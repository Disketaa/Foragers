using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Foragers_Project.Core;

public sealed class PlayerController
{
    private readonly PlayerAnimator _animator;
    private Vector2 _position;
    private bool _facingLeft;

    public PlayerController(GraphicsDevice graphicsDevice, string animPath, Vector2 startPosition)
    {
        _animator = new PlayerAnimator(graphicsDevice, animPath);
        _position = startPosition;
    }

    public void Update(GameTime gameTime)
    {
        KeyboardState keyboard = Keyboard.GetState();

        Vector2 movement = Vector2.Zero;

        if (keyboard.IsKeyDown(Keys.W) || keyboard.IsKeyDown(Keys.Up))
            movement.Y -= 1;

        if (keyboard.IsKeyDown(Keys.S) || keyboard.IsKeyDown(Keys.Down))
            movement.Y += 1;

        if (keyboard.IsKeyDown(Keys.A) || keyboard.IsKeyDown(Keys.Left))
        {
            _facingLeft = true;
            movement.X -= 1;
        }

        if (keyboard.IsKeyDown(Keys.D) || keyboard.IsKeyDown(Keys.Right))
        {
            _facingLeft = false;
            movement.X += 1;
        }

        float speed = Runtime.Get<float>("speed");
        float movementSpeed = 0f;

        if (movement != Vector2.Zero)
        {
            movement.Normalize();
            movementSpeed = speed;
            _position += movement * speed;
        }

        _animator.Update(gameTime, movementSpeed, _facingLeft);
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _animator.Draw(spriteBatch, _position);
    }
}
