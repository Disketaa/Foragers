using System;
using System.Diagnostics;
using System.IO;
using Foragers.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

internal static class ShaderDebugLog
{
    private static readonly string LogPath = Path.Combine(
        AppDomain.CurrentDomain.BaseDirectory,
        "shader_debug.log"
    );

    public static void Write(string message)
    {
        try
        {
            File.AppendAllText(LogPath, $"[{DateTime.Now:HH:mm:ss}] {message}\n");
        }
        catch { }
    }
}

public sealed class ShaderRenderer : IDisposable
{
    private readonly GraphicsDevice _graphicsDevice;
    private ShaderMaterial? _tileMaterial;
    private bool _isEnabled;

    public bool IsEnabled => _isEnabled;

    public ShaderRenderer(GraphicsDevice graphicsDevice)
    {
        _graphicsDevice = graphicsDevice;
        ShaderDebugLog.Write("ShaderRenderer created");
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
        ShaderDebugLog.Write($"LoadConfig: Shaders={_isEnabled}");

        if (_isEnabled)
        {
            _tileMaterial?.Dispose();
            _tileMaterial = new ShaderMaterial(_graphicsDevice, "TileDebug");
            ShaderDebugLog.Write("TileDebug shader loaded");
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
            ShaderDebugLog.Write("TileDebug shader loaded");
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

    public static Vector4 GetRandomColor()
    {
        Random random = new();
        return new Vector4(
            (float)random.NextDouble(),
            (float)random.NextDouble(),
            (float)random.NextDouble(),
            1f
        );
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
