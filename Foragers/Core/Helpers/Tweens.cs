using Microsoft.Xna.Framework;

namespace Foragers.Core.Helpers;

public static class Tweens
{
    public enum SpriteTarget
    {
        ScaleX,
        ScaleY,
        X,
        Y,
    }

    public static float BackOut(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1;
        return 1f + (c3 * MathF.Pow(t - 1f, 3)) + (c1 * MathF.Pow(t - 1f, 2));
    }

    public static float Ease(float t, float from, float to, Func<float, float> curve)
    {
        return from + ((to - from) * curve(t));
    }

    public static float Bump(float t, float factor)
    {
        return 1.0f + (factor * Math.Min(BackOut(t), BackOut(1.0f - t)));
    }

    public struct SpriteTween(
        SpriteTarget target,
        float from,
        float to,
        float duration,
        Func<float, float> curve
    )
    {
        public SpriteTarget Target { get; private set; } = target;
        public float From { get; private set; } = from;
        public float To { get; private set; } = to;
        public float Duration { get; private set; } = duration;
        public Func<float, float> Curve { get; private set; } = curve;
        public float Timer { get; private set; }
        public bool IsActive { get; private set; }

        public void Start()
        {
            Timer = 0f;
            IsActive = true;
        }

        public void Update(GameTime gameTime)
        {
            if (!IsActive)
                return;

            Timer += (float)gameTime.ElapsedGameTime.TotalSeconds;
            if (Timer >= Duration)
            {
                Timer = Duration;
                IsActive = false;
            }
        }

        public float GetValue()
        {
            if (!IsActive)
                return To;

            float t = Timer / Duration;
            return Ease(t, From, To, Curve);
        }
    }
}
