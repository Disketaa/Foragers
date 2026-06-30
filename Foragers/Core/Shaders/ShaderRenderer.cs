using System;
using System.Diagnostics;
using System.IO;
using Foragers.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

public static class ShaderDebugLog
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
    private const string ShadersFolder = "Shaders/";
    private const string ShaderConfig = "Core/Options.json";

    private readonly GraphicsDevice _graphicsDevice;
    private readonly Dictionary<string, Effect> _effects = [];

    private bool _isEnabled;
    private string _currentShader = string.Empty;

    private readonly Random _random = new();

    public bool IsEnabled => _isEnabled;
    public string CurrentShader => _currentShader;

    public ShaderRenderer(GraphicsDevice graphicsDevice)
    {
        _graphicsDevice = graphicsDevice;
        ShaderDebugLog.Write("ShaderRenderer created");
        LoadConfig();
        Runtime.FileReloaded += OnFileReloaded;
    }

    private void LoadConfig()
    {
        _isEnabled = Runtime.GetBool(ShaderConfig, "ShaderEnabled", false);
        string shaderName = Runtime.GetString(ShaderConfig, "ActiveShader", string.Empty);

        ShaderDebugLog.Write($"LoadConfig: Enabled={_isEnabled}, Shader='{shaderName}'");

        if (_isEnabled && !string.IsNullOrEmpty(shaderName))
        {
            LoadShader(shaderName);
            _currentShader = shaderName;
        }
        else
        {
            _currentShader = string.Empty;
        }
    }

    private void OnFileReloaded(string filePath)
    {
        if (filePath.EndsWith("Options.json", StringComparison.OrdinalIgnoreCase))
        {
            ShaderDebugLog.Write($"Options.json reloaded, reloading config");
            LoadConfig();
        }
    }

    private void LoadShader(string shaderName)
    {
        if (_effects.TryGetValue(shaderName, out Effect? existing) && existing != null)
        {
            ShaderDebugLog.Write($"Shader '{shaderName}' already loaded");
            return;
        }

        string mgfxoPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            ShadersFolder,
            $"{shaderName}.mgfxo"
        );

        ShaderDebugLog.Write($"Loading shader from: {mgfxoPath}");

        if (!File.Exists(mgfxoPath))
        {
            ShaderDebugLog.Write($"ERROR: Shader file not found: {mgfxoPath}");
            return;
        }

        try
        {
            byte[] effectCode = File.ReadAllBytes(mgfxoPath);
            ShaderDebugLog.Write($"Shader file size: {effectCode.Length} bytes");
            var effect = new Effect(_graphicsDevice, effectCode);
            _effects[shaderName] = effect;
            ShaderDebugLog.Write($"Shader '{shaderName}' loaded successfully. Parameters:");
            foreach (EffectParameter param in effect.Parameters)
            {
                ShaderDebugLog.Write($"  - {param.Name}");
            }
        }
        catch (Exception ex)
        {
            ShaderDebugLog.Write($"ERROR: Failed to load shader '{shaderName}': {ex.Message}");
        }
    }

    public void SetShader(string shaderName)
    {
        if (string.IsNullOrEmpty(shaderName))
        {
            _currentShader = string.Empty;
            return;
        }

        if (!_effects.ContainsKey(shaderName))
        {
            LoadShader(shaderName);
        }

        _currentShader = _effects.ContainsKey(shaderName) ? shaderName : string.Empty;
    }

    public void SetEnabled(bool enabled)
    {
        _isEnabled = enabled;
        if (!enabled)
        {
            _currentShader = string.Empty;
        }
    }

    public Effect? GetCurrentEffect()
    {
        if (!_isEnabled || string.IsNullOrEmpty(_currentShader))
        {
            ShaderDebugLog.Write(
                $"GetCurrentEffect returning null: Enabled={_isEnabled}, CurrentShader='{_currentShader}'"
            );
            return null;
        }

        _effects.TryGetValue(_currentShader, out Effect? effect);
        if (effect == null)
        {
            ShaderDebugLog.Write($"ERROR: Effect '{_currentShader}' not found in dictionary!");
        }
        return effect;
    }

    public void SetParameter(string name, Vector4 value)
    {
        if (_effects.TryGetValue(_currentShader, out Effect? effect))
        {
            effect.Parameters[name]?.SetValue(value);
        }
    }

    public void SetRandomColor()
    {
        if (_effects.TryGetValue(_currentShader, out Effect? effect))
        {
            var color = new Vector4(
                (float)_random.NextDouble(),
                (float)_random.NextDouble(),
                (float)_random.NextDouble(),
                1f
            );
            effect.Parameters["RandomColor"]?.SetValue(color);
        }
    }

    public void Dispose()
    {
        foreach (Effect effect in _effects.Values)
        {
            effect.Dispose();
        }
        _effects.Clear();
    }
}
