using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public sealed class PlayerAnimator
{
    private readonly SpriteSheet _sheet;
    private readonly AnimationPlayer _animPlayer;
    private Tweens.SmearEffect _smearEffect;

    public PlayerAnimator(GraphicsDevice graphicsDevice, string animPath)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
        _smearEffect = new Tweens.SmearEffect(0.1f, 0.2f);
    }

    public void Smear()
    {
        _smearEffect.Start();
    }

    public void Update(GameTime gameTime, float speed)
    {
        string targetAnim = speed > 0 ? "Run" : "Idle";

        if (_animPlayer.Current != targetAnim)
        {
            _animPlayer.Play(targetAnim);
        }

        _animPlayer.Update(gameTime);
        _smearEffect.Update(gameTime);
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position, bool facingLeft)
    {
        SpriteEffects effects = facingLeft ? SpriteEffects.FlipHorizontally : SpriteEffects.None;
        Vector2 scale = _smearEffect.GetCurrentScale();
        Rectangle sourceRect = _animPlayer.SourceRect();
        Vector2 origin = new Vector2(sourceRect.Width / 2f, sourceRect.Height);

        spriteBatch.Draw(
            _sheet.Texture,
            position,
            sourceRect,
            Color.White,
            0f,
            origin,
            scale,
            effects,
            0f
        );
    }
}
