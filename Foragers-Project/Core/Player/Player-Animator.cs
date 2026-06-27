using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public sealed class PlayerAnimator
{
    private readonly SpriteSheet _sheet;
    private readonly AnimationPlayer _animPlayer;

    public PlayerAnimator(GraphicsDevice graphicsDevice, string animPath)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
    }

    public void Update(GameTime gameTime, float speed)
    {
        string targetAnim = speed > 0 ? "Run" : "Idle";

        if (_animPlayer.Current != targetAnim)
        {
            _animPlayer.Play(targetAnim);
        }

        _animPlayer.Update(gameTime);
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position, bool facingLeft)
    {
        SpriteEffects effects = facingLeft ? SpriteEffects.FlipHorizontally : SpriteEffects.None;

        spriteBatch.Draw(
            _sheet.Texture,
            PixelRounding.RoundToPixel(position),
            _animPlayer.SourceRect(),
            Color.White,
            0f,
            Vector2.Zero,
            1f,
            effects,
            0f
        );
    }
}
