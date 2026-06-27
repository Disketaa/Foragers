using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using static Foragers_Project.Core.Helpers.Tweens;

namespace Foragers_Project.Core;

public sealed class PlayerAnimator
{
    private readonly SpriteSheet _sheet;
    private readonly AnimationPlayer _animPlayer;
    private readonly SpriteRenderer _renderer;
    private bool _facingLeft;

    public PlayerAnimator(GraphicsDevice graphicsDevice, string animPath)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
        _renderer = new SpriteRenderer();
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
        _renderer.Update(gameTime);
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position)
    {
        SpriteEffects effects = _facingLeft ? SpriteEffects.FlipHorizontally : SpriteEffects.None;
        _renderer.Draw(
            spriteBatch,
            _sheet.Texture,
            _animPlayer.SourceRect(),
            position,
            effects,
            _sheet.PivotX,
            _sheet.PivotY
        );
    }

    private void OnFlip()
    {
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleY,
                from: 1.5f,
                to: 1.0f,
                duration: 0.1f,
                curve: Tweens.BackOut
            )
        );
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleX,
                from: 0.5f,
                to: 1.0f,
                duration: 0.1f,
                curve: Tweens.BackOut
            )
        );
    }
}
