using System;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

internal sealed class ShaderAsset
{
    private Effect? _effect;
    private DateTime _updatedAt;
    private readonly string _assetName;
    private readonly GraphicsDevice _graphicsDevice;

    public Effect? Effect => _effect;
    public DateTime UpdatedAt => _updatedAt;
    public bool IsValid => _effect != null;

    public ShaderAsset(GraphicsDevice graphicsDevice, string assetName)
    {
        _graphicsDevice = graphicsDevice;
        _assetName = assetName;
        _updatedAt = DateTime.MinValue;
        Load();
    }

    private void Load()
    {
        string mgfxoPath = System.IO.Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            $"{_assetName}.mgfxo"
        );

        if (!System.IO.File.Exists(mgfxoPath))
            return;

        try
        {
            byte[] effectCode = System.IO.File.ReadAllBytes(mgfxoPath);
            _effect = new Effect(_graphicsDevice, effectCode);
            _updatedAt = System.IO.File.GetLastWriteTime(mgfxoPath);
        }
        catch
        {
            _effect = null;
        }
    }

    public bool TryRefresh()
    {
        string mgfxoPath = System.IO.Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            $"{_assetName}.mgfxo"
        );

        if (!System.IO.File.Exists(mgfxoPath))
            return false;

        DateTime fileTime = System.IO.File.GetLastWriteTime(mgfxoPath);
        if (fileTime <= _updatedAt)
            return false;

        try
        {
            byte[] effectCode = System.IO.File.ReadAllBytes(mgfxoPath);
            Effect? oldEffect = _effect;
            _effect = new Effect(_graphicsDevice, effectCode);
            _updatedAt = fileTime;
            oldEffect?.Dispose();
            return true;
        }
        catch
        {
            return false;
        }
    }
}
