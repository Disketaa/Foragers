using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

public static class ShaderManager
{
    private static Effect? _waterReflectionEffect;
    private static EffectParameter? _gradientColorParam;
    private static EffectParameter? _gradientHeightParam;
    private static EffectTechnique? _waterReflectionTechnique;

    public static Effect? WaterReflectionEffect => _waterReflectionEffect;
    public static bool IsLoaded => _waterReflectionEffect != null;

    public static void LoadContent(GraphicsDevice graphicsDevice)
    {
        string shaderPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Shaders",
            "WaterReflection.mgfxo"
        );

        if (!File.Exists(shaderPath))
            return;

        byte[] effectBytes = File.ReadAllBytes(shaderPath);
        _waterReflectionEffect = new Effect(graphicsDevice, effectBytes);

        _gradientColorParam = _waterReflectionEffect.Parameters["GradientColor"];
        _gradientHeightParam = _waterReflectionEffect.Parameters["GradientHeight"];
        _waterReflectionTechnique = _waterReflectionEffect.Techniques["WaterReflection"];

        SetGradientColor(new Color(46, 171, 212));
        SetGradientHeight(1.0f);
    }

    public static void SetGradientColor(Color color)
    {
        if (_gradientColorParam != null)
            _gradientColorParam.SetValue(color.ToVector4());
    }

    public static void SetGradientHeight(float height)
    {
        if (_gradientHeightParam != null)
            _gradientHeightParam.SetValue(height);
    }

    public static void Apply()
    {
        if (_waterReflectionEffect == null || _waterReflectionTechnique == null)
            return;

        _waterReflectionEffect.CurrentTechnique = _waterReflectionTechnique;
        _waterReflectionEffect.CurrentTechnique.Passes[0].Apply();
    }

    public static void Unload()
    {
        _waterReflectionEffect?.Dispose();
        _waterReflectionEffect = null;
        _gradientColorParam = null;
        _gradientHeightParam = null;
        _waterReflectionTechnique = null;
    }
}
