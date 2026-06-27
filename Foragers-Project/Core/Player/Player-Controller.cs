using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Foragers_Project.Core;

public sealed class PlayerController
{
    private readonly SpriteSheet _sheet;
    private readonly AnimationPlayer _animPlayer;
    private Vector2 _position;
    private string _currentAnim = "Idle";
    private bool _facingLeft;

    public PlayerController(GraphicsDevice graphicsDevice, string animPath, Vector2 startPosition)
    {
        _sheet = new SpriteSheet(graphicsDevice, animPath);
        _animPlayer = new AnimationPlayer(_sheet);
        _animPlayer.Play("Idle");
        _position = startPosition;
    }

    public void Update(GameTime gameTime)
    {
        KeyboardState keyboard = Keyboard.GetState();

        Vector2 movement = Vector2.Zero;

        if (keyboard.IsKeyDown(Keys.W) || keyboard.IsKeyDown(Keys.Up))
        {
            movement.Y -= 1;
        }

        if (keyboard.IsKeyDown(Keys.S) || keyboard.IsKeyDown(Keys.Down))
        {
            movement.Y += 1;
        }

        if (keyboard.IsKeyDown(Keys.A) || keyboard.IsKeyDown(Keys.Left))
        {
            movement.X -= 1;
            _facingLeft = true;
        }

        if (keyboard.IsKeyDown(Keys.D) || keyboard.IsKeyDown(Keys.Right))
        {
            movement.X += 1;
            _facingLeft = false;
        }

        if (movement != Vector2.Zero)
        {
            movement.Normalize();
            _position += movement * Runtime.Get<float>("speed");
            PlayRun();
        }
        else if (keyboard.IsKeyDown(Keys.Space))
        {
            _animPlayer.Play("Death");
            _currentAnim = "Death";
        }
        else
        {
            if (_animPlayer.Done || _currentAnim == "Run")
            {
                _currentAnim = "Idle";
                _animPlayer.Play(_currentAnim);
            }
        }

        _animPlayer.Update(gameTime);
    }

    private void PlayRun()
    {
        _animPlayer.Play("Run");
        _currentAnim = "Run";
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        SpriteEffects effects = _facingLeft ? SpriteEffects.FlipHorizontally : SpriteEffects.None;

        spriteBatch.Draw(
            _sheet.Texture,
            PixelRounding.RoundToPixel(_position),
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
