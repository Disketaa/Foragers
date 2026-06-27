using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public sealed class PlayerAnimator
{
    private readonly SpriteSheet _sheet;
    private readonly AnimationPlayer _animPlayer;
    private readonly List<Tweens.SpriteTween> _tweens;
    private bool _facingLeft;

    public PlayerAnimator(GraphicsDevice graphicsDevice, string animPath)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
        _tweens = new List<Tweens.SpriteTween>();
    }

    public void AddTween(Tweens.SpriteTween tween)
    {
        _tweens.Add(tween);
    }

    public void TriggerTween(Tweens.SpriteTween tween)
    {
        tween.Start();
        _tweens.Add(tween);
    }

    public void Update(GameTime gameTime, float speed, bool facingLeft)
    {
        if (facingLeft != _facingLeft)
        {
            _facingLeft = facingLeft;
            OnFlip();
        }

        string targetAnim = speed > 0 ? "Run" : "Idle";

        if (_animPlayer.Current != targetAnim)
            _animPlayer.Play(targetAnim);

        _animPlayer.Update(gameTime);

        for (int i = _tweens.Count - 1; i >= 0; i--)
        {
            var tween = _tweens[i];
            tween.Update(gameTime);
            _tweens[i] = tween;

            if (!tween.IsActive)
                _tweens.RemoveAt(i);
        }
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position)
    {
        SpriteEffects effects = _facingLeft ? SpriteEffects.FlipHorizontally : SpriteEffects.None;

        float scaleX = 1f;
        float scaleY = 1f;
        float offsetX = 0f;
        float offsetY = 0f;

        foreach (var tween in _tweens)
        {
            float value = tween.GetValue();
            switch (tween.Target)
            {
                case Tweens.SpriteTarget.ScaleX:
                    scaleX *= value;
                    break;
                case Tweens.SpriteTarget.ScaleY:
                    scaleY *= value;
                    break;
                case Tweens.SpriteTarget.X:
                    offsetX += value;
                    break;
                case Tweens.SpriteTarget.Y:
                    offsetY += value;
                    break;
            }
        }

        Rectangle sourceRect = _animPlayer.SourceRect();
        Vector2 origin = new Vector2(sourceRect.Width / 2f, sourceRect.Height);
        Vector2 drawPosition = position + new Vector2(offsetX, offsetY);
        Vector2 scale = new Vector2(scaleX, scaleY);

        spriteBatch.Draw(
            _sheet.Texture,
            drawPosition,
            sourceRect,
            Color.White,
            0f,
            origin,
            scale,
            effects,
            0f
        );
    }

    private void OnFlip()
    {
        var height = new Tweens.SpriteTween(
            Tweens.SpriteTarget.ScaleY,
            from: 1.3f,
            to: 1.0f,
            duration: 0.3f,
            curve: Tweens.BackOut
        );
        height.Start();
        _tweens.Add(height);

        var width = new Tweens.SpriteTween(
            Tweens.SpriteTarget.ScaleX,
            from: 0.0f,
            to: 1.0f,
            duration: 0.2f,
            curve: Tweens.BackOut
        );
        width.Start();
        _tweens.Add(width);
    }
}
