using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using static Foragers_Project.Core.Helpers.Tweens;

namespace Foragers_Project.Core;

public sealed class SpriteRenderer
{
    private readonly List<SpriteTween> _tweens;

    public SpriteRenderer()
    {
        _tweens = new List<SpriteTween>();
    }

    public void TriggerTween(SpriteTween tween)
    {
        tween.Start();
        _tweens.Add(tween);
    }

    public void Update(GameTime gameTime)
    {
        for (int i = _tweens.Count - 1; i >= 0; i--)
        {
            var tween = _tweens[i];
            tween.Update(gameTime);
            _tweens[i] = tween;

            if (!tween.IsActive)
                _tweens.RemoveAt(i);
        }
    }

    public void Draw(
        SpriteBatch spriteBatch,
        Texture2D texture,
        Rectangle sourceRect,
        Vector2 position,
        SpriteEffects effects,
        float pivotX = 0.5f,
        float pivotY = 0.5f
    )
    {
        float scaleX = 1f;
        float scaleY = 1f;
        float offsetX = 0f;
        float offsetY = 0f;

        foreach (var tween in _tweens)
        {
            float value = tween.GetValue();
            switch (tween.Target)
            {
                case SpriteTarget.ScaleX:
                    scaleX *= value;
                    break;
                case SpriteTarget.ScaleY:
                    scaleY *= value;
                    break;
                case SpriteTarget.X:
                    offsetX += value;
                    break;
                case SpriteTarget.Y:
                    offsetY += value;
                    break;
            }
        }

        Vector2 origin = new Vector2(sourceRect.Width * pivotX, sourceRect.Height * pivotY);
        Vector2 drawPosition = position + new Vector2(offsetX, offsetY);

        spriteBatch.Draw(
            texture,
            drawPosition,
            sourceRect,
            Color.White,
            0f,
            origin,
            new Vector2(scaleX, scaleY),
            effects,
            0f
        );
    }
}
