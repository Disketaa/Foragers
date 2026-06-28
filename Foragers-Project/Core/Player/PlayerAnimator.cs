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
    private bool _wasSwimming;

    public CollisionBox? Collision => _sheet.Collision;
    public float PivotX => _sheet.PivotX;
    public float PivotY => _sheet.PivotY;

    public PlayerAnimator(GraphicsDevice graphicsDevice, string animPath)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
        _renderer = new SpriteRenderer();
    }

    public void Update(GameTime gameTime, float speed, bool facingLeft, bool isSwimming)
    {
        if (facingLeft != _facingLeft)
        {
            _facingLeft = facingLeft;
            OnFlip();
        }

        if (isSwimming != _wasSwimming)
        {
            _wasSwimming = isSwimming;
            OnSwimStateChange();
        }

        string targetAnim = isSwimming ? "Swim" : (speed > 0 ? "Run" : "Idle");

        if (_animPlayer.Current != targetAnim)
            _animPlayer.Play(targetAnim);

        float animSpeed = targetAnim == "Run" || targetAnim == "Swim" ? speed : 1f;
        _animPlayer.Update(gameTime, animSpeed);
        _renderer.Update(gameTime);
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position, bool debugMode = false)
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

        if (debugMode && _sheet.Collision != null)
        {
            Rectangle bounds = _sheet.Collision.GetBounds(position, _sheet.PivotX, _sheet.PivotY);
            Collisions.DrawDebug(spriteBatch, bounds);
        }
    }

    private void OnFlip()
    {
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleX,
                from: 0.5f,
                to: 1.0f,
                duration: 0.3f,
                curve: Tweens.BackOut
            )
        );
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleY,
                from: 1.5f,
                to: 1.0f,
                duration: 0.3f,
                curve: Tweens.BackOut
            )
        );
    }

    private void OnSwimStateChange()
    {
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleX,
                from: 0.75f,
                to: 1.0f,
                duration: 0.2f,
                curve: Tweens.BackOut
            )
        );
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleY,
                from: 1.5f,
                to: 1.0f,
                duration: 0.4f,
                curve: Tweens.BackOut
            )
        );
    }
}
