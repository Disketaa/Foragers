using System;
using System.Diagnostics;
using System.IO;
using Foragers.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

public sealed class ShaderRenderer : IDisposable
{
    private readonly GraphicsDevice _graphicsDevice;
    private ShaderMaterial? _tileMaterial;
    private bool _isEnabled;

    public bool IsEnabled => _isEnabled;

    public ShaderRenderer(GraphicsDevice graphicsDevice)
    {
        _graphicsDevice = graphicsDevice;
        LoadConfig();

        Runtime.FileReloaded += OnFileReloaded;
    }

    private void OnFileReloaded(string filePath)
    {
        if (filePath.EndsWith("Options.json", StringComparison.OrdinalIgnoreCase))
        {
            bool newEnabled = Runtime.GetBool("Core/Options.json", "Shaders", false);
            SetEnabled(newEnabled);
        }
    }

    private void LoadConfig()
    {
        _isEnabled = Runtime.GetBool("Core/Options.json", "Shaders", false);

        if (_isEnabled)
        {
            _tileMaterial?.Dispose();
            _tileMaterial = new ShaderMaterial(_graphicsDevice, "TileDebug");
        }
    }

    public void SetEnabled(bool enabled)
    {
        if (_isEnabled == enabled)
            return;

        _isEnabled = enabled;

        if (_isEnabled)
        {
            _tileMaterial?.Dispose();
            _tileMaterial = new ShaderMaterial(_graphicsDevice, "TileDebug");
        }
        else
        {
            _tileMaterial?.Dispose();
            _tileMaterial = null;
        }
    }

    public ShaderMaterial? GetTileMaterial()
    {
        if (!_isEnabled)
            return null;
        return _tileMaterial;
    }

    public void ApplyViewProjection(Matrix view, Matrix projection)
    {
        Matrix vp = view * projection;
        _tileMaterial?.SetParameter("view_projection", vp);
    }

    [Conditional("DEBUG")]
    public void Update()
    {
        _tileMaterial?.Update();
    }

    public void Dispose()
    {
        Runtime.FileReloaded -= OnFileReloaded;
        _tileMaterial?.Dispose();
        _tileMaterial = null;
    }
}
