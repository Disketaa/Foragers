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

    private const float StopRadius = 4f;
    private const float FullSpeedRadius = 64f;

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

    public void UpdateMouse(GameTime gameTime, Vector2 cursorPosition)
    {
        Vector2 toTarget = cursorPosition - _position;
        float distance = toTarget.Length();

        float speed = Runtime.Get<float>("speed");
        float movementSpeed = 0f;

        if (distance > StopRadius)
        {
            float factor = MathHelper.Clamp(
                (distance - StopRadius) / (FullSpeedRadius - StopRadius),
                0f,
                1f
            );
            movementSpeed = speed * factor;

            Vector2 direction = toTarget / distance;

            if (direction.X < 0f)
                _facingLeft = true;
            else if (direction.X > 0f)
                _facingLeft = false;

            float step = Math.Min(movementSpeed, distance);
            _position += direction * step;
        }

        _animator.Update(gameTime, movementSpeed, _facingLeft);
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _animator.Draw(spriteBatch, _position);
    }
}
