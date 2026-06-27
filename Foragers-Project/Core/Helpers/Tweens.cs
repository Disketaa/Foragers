using Microsoft.Xna.Framework;

namespace Foragers_Project.Core.Helpers;

public static class Tweens
{
    public static float BackOut(float t)
    {
        const float c1 = 1.70158f;
        const float c3 = c1 + 1;
        return 1f + c3 * MathF.Pow(t - 1f, 3) + c1 * MathF.Pow(t - 1f, 2);
    }

    public static float Ease(float t, float from, float to, Func<float, float> curve)
    {
        return from + (to - from) * curve(t);
    }

    public static float Bump(float t, float factor)
    {
        return 1.0f + factor * Math.Min(BackOut(t), BackOut(1.0f - t));
    }

    public struct SmearEffect
    {
        public float Duration { get; private set; }
        public float Factor { get; private set; }
        public float Timer { get; private set; }
        public bool IsActive { get; private set; }

        public SmearEffect(float duration, float factor)
        {
            Duration = duration;
            Factor = factor;
            Timer = 0;
            IsActive = false;
        }

        public void Start()
        {
            Timer = 0;
            IsActive = true;
        }

        public void Update(GameTime gameTime)
        {
            if (!IsActive)
                return;

            Timer += (float)gameTime.ElapsedGameTime.TotalSeconds;
            if (Timer >= Duration)
            {
                IsActive = false;
                Timer = 0;
            }
        }

        public Vector2 GetCurrentScale()
        {
            if (!IsActive)
                return Vector2.One;

            float t = Timer / Duration;
            float scaleValue = Bump(t, Factor);
            return new Vector2(scaleValue, scaleValue);
        }
    }
}
