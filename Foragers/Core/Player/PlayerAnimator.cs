using Foragers.Core.Animator;
using Foragers.Core.Helpers;
using Foragers.Core.Shaders;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using static Foragers.Core.Helpers.Tweens;

namespace Foragers.Core.Player;

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

    public void Update(GameTime gameTime, float animSpeed, bool facingLeft, bool isSwimming)
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

        string targetAnim = isSwimming ? "Swim" : (animSpeed > 0f ? "Run" : "Idle");

        if (_animPlayer.Current != targetAnim)
            _animPlayer.Play(targetAnim);

        float playbackSpeed = isSwimming
            ? Math.Max(animSpeed, 0.3f)
            : (targetAnim == "Run" ? animSpeed : 1f);

        _animPlayer.Update(gameTime, playbackSpeed);
        _renderer.Update(gameTime);
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position, bool debugMode = false)
    {
        bool shadersEnabled = Runtime.GetBool("Core/Options.json", "Shaders", false);
        bool waterReflectionEnabled = Runtime.GetBool(
            "Core/Options.json",
            "WaterReflectionShader",
            false
        );
        bool canReflect =
            shadersEnabled
            && waterReflectionEnabled
            && ShaderManager.WaterReflectionEffect != null
            && _wasSwimming;

        if (canReflect)
        {
            DrawReflection(spriteBatch, position);
        }

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

    private void DrawReflection(SpriteBatch spriteBatch, Vector2 position)
    {
        Effect effect = ShaderManager.WaterReflectionEffect!;

        spriteBatch.End();

        SpriteEffects flipEffect = _facingLeft
            ? SpriteEffects.FlipHorizontally | SpriteEffects.FlipVertically
            : SpriteEffects.FlipVertically;

        spriteBatch.Begin(
            SpriteSortMode.Immediate,
            BlendState.AlphaBlend,
            SamplerState.PointClamp,
            null,
            null,
            effect
        );

        var reflectionPos = new Vector2(position.X, position.Y + _sheet.FrameHeight);

        _renderer.Draw(
            spriteBatch,
            _sheet.Texture,
            _animPlayer.SourceRect(),
            reflectionPos,
            flipEffect,
            _sheet.PivotX,
            _sheet.PivotY
        );

        spriteBatch.End();
        spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);
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
                from: 1.25f,
                to: 1.0f,
                duration: 0.7f,
                curve: Tweens.BackOut
            )
        );
        _renderer.TriggerTween(
            new SpriteTween(
                SpriteTarget.ScaleY,
                from: 0.5f,
                to: 1.0f,
                duration: 0.9f,
                curve: Tweens.BackOut
            )
        );
    }
}
