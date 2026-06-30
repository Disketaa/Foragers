using System;
using System.Collections.Generic;
using System.Diagnostics;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Shaders;

public sealed class ShaderMaterial(GraphicsDevice graphicsDevice, string shaderName) : IDisposable
{
    private readonly ShaderAsset _asset = new ShaderAsset(graphicsDevice, shaderName);
    private readonly Dictionary<string, object> _parameters = [];

    public bool IsValid => _asset.Effect != null;
    public Effect? Effect => _asset.Effect;

    [Conditional("DEBUG")]
    public void Update()
    {
        if (_asset.TryRefresh())
        {
            ApplyParameters();
        }
    }

    private void ApplyParameters()
    {
        if (_asset.Effect == null)
            return;

        foreach (KeyValuePair<string, object> kvp in _parameters)
        {
            EffectParameter? param = _asset.Effect.Parameters[kvp.Key];
            if (param == null)
                continue;

            switch (kvp.Value)
            {
                case float f:
                    param.SetValue(f);
                    break;
                case Vector2 v2:
                    param.SetValue(v2);
                    break;
                case Vector3 v3:
                    param.SetValue(v3);
                    break;
                case Vector4 v4:
                    param.SetValue(v4);
                    break;
                case Matrix m:
                    param.SetValue(m);
                    break;
                case Texture2D tex:
                    param.SetValue(tex);
                    break;
            }
        }
    }

    private static bool ParameterExists(Effect? effect, string name)
    {
        if (effect?.Parameters == null)
            return false;

        foreach (EffectParameter param in effect.Parameters)
        {
            if (param.Name == name)
                return true;
        }
        return false;
    }

    public bool SetParameter(string name, float value)
    {
        if (!ParameterExists(_asset.Effect, name))
            return false;

        _parameters[name] = value;
        _asset.Effect?.Parameters[name]?.SetValue(value);
        return true;
    }

    public bool SetParameter(string name, Vector2 value)
    {
        if (!ParameterExists(_asset.Effect, name))
            return false;

        _parameters[name] = value;
        _asset.Effect?.Parameters[name]?.SetValue(value);
        return true;
    }

    public bool SetParameter(string name, Vector3 value)
    {
        if (!ParameterExists(_asset.Effect, name))
            return false;

        _parameters[name] = value;
        _asset.Effect?.Parameters[name]?.SetValue(value);
        return true;
    }

    public bool SetParameter(string name, Vector4 value)
    {
        if (!ParameterExists(_asset.Effect, name))
            return false;

        _parameters[name] = value;
        _asset.Effect?.Parameters[name]?.SetValue(value);
        return true;
    }

    public bool SetParameter(string name, Matrix value)
    {
        if (!ParameterExists(_asset.Effect, name))
            return false;

        _parameters[name] = value;
        _asset.Effect?.Parameters[name]?.SetValue(value);
        return true;
    }

    public void Dispose()
    {
        _asset?.Effect?.Dispose();
    }
}
