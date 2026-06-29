using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Helpers;

public static class ShaderManager
{
    private static Effect? _waterReflectionEffect;
    private static Effect? _redScreenEffect;

    public static Effect? WaterReflectionEffect => _waterReflectionEffect;
    public static Effect? RedScreenEffect => _redScreenEffect;

    private static void Log(string message)
    {
        try
        {
            File.AppendAllText("debug.log", $"[{DateTime.Now:HH:mm:ss.fff}] {message}\n");
        }
        catch { }
    }

    public static void LoadContent(GraphicsDevice graphicsDevice)
    {
        Log("=== ShaderManager.LoadContent START ===");
        Log($"BaseDirectory: {AppDomain.CurrentDomain.BaseDirectory}");
        Log($"debug.log full path: {Path.GetFullPath("debug.log")}");

        string shaderPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            "WaterReflection.mgfxo"
        );

        Log($"WaterReflection path: {shaderPath}");
        Log($"WaterReflection exists: {File.Exists(shaderPath)}");

        if (File.Exists(shaderPath))
        {
            try
            {
                byte[] effectBytes = File.ReadAllBytes(shaderPath);
                Log($"WaterReflection bytes read: {effectBytes.Length}");
                _waterReflectionEffect = new Effect(graphicsDevice, effectBytes);
                Log($"WaterReflection loaded: {_waterReflectionEffect != null}");
                Log($"WaterReflection technique: {_waterReflectionEffect?.CurrentTechnique?.Name}");
            }
            catch (Exception ex)
            {
                Log($"WaterReflection FAILED: {ex.Message}");
                Log($"WaterReflection StackTrace: {ex.StackTrace}");
            }
        }
        else
        {
            Log("WaterReflection file NOT FOUND");
        }

        string redScreenPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            "RedScreen.mgfxo"
        );

        Log($"RedScreen path: {redScreenPath}");
        Log($"RedScreen exists: {File.Exists(redScreenPath)}");

        if (File.Exists(redScreenPath))
        {
            try
            {
                byte[] effectBytes = File.ReadAllBytes(redScreenPath);
                Log($"RedScreen bytes read: {effectBytes.Length}");
                _redScreenEffect = new Effect(graphicsDevice, effectBytes);
                Log($"RedScreen loaded: {_redScreenEffect != null}");
                Log($"RedScreen technique: {_redScreenEffect?.CurrentTechnique?.Name}");
            }
            catch (Exception ex)
            {
                Log($"RedScreen FAILED: {ex.Message}");
                Log($"RedScreen StackTrace: {ex.StackTrace}");
            }
        }
        else
        {
            Log("RedScreen file NOT FOUND");
        }

        Log("=== ShaderManager.LoadContent END ===");
    }

    public static void Unload()
    {
        _waterReflectionEffect?.Dispose();
        _waterReflectionEffect = null;
        _redScreenEffect?.Dispose();
        _redScreenEffect = null;
    }
}
