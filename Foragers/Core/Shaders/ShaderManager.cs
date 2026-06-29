using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

public static class ShaderManager
{
    private static Effect? _waterReflectionEffect;

    public static Effect? WaterReflectionEffect => _waterReflectionEffect;

    public static void LoadContent(GraphicsDevice graphicsDevice)
    {
        string shaderPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            "WaterReflection.mgfxo"
        );

        if (File.Exists(shaderPath))
        {
            byte[] effectBytes = File.ReadAllBytes(shaderPath);
            _waterReflectionEffect = new Effect(graphicsDevice, effectBytes);
        }
    }

    public static void Unload()
    {
        _waterReflectionEffect?.Dispose();
        _waterReflectionEffect = null;
    }
}
