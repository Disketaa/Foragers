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

    private const float StopRadius = 4f;
    private const float FullSpeedRadius = 64f;

    public PlayerController(GraphicsDevice graphicsDevice, string animPath, Vector2 startPosition)
    {
        _animator = new PlayerAnimator(graphicsDevice, animPath);
        _position = startPosition;
    }

    public void Update(GameTime gameTime)
    {
        KeyboardState keyboard = Keyboard.GetState();

        Vector2 direction = Vector2.Zero;

        if (keyboard.IsKeyDown(Keys.W) || keyboard.IsKeyDown(Keys.Up))
            direction.Y -= 1;

        if (keyboard.IsKeyDown(Keys.S) || keyboard.IsKeyDown(Keys.Down))
            direction.Y += 1;

        if (keyboard.IsKeyDown(Keys.A) || keyboard.IsKeyDown(Keys.Left))
            direction.X -= 1;

        if (keyboard.IsKeyDown(Keys.D) || keyboard.IsKeyDown(Keys.Right))
            direction.X += 1;

        if (direction != Vector2.Zero)
            direction.Normalize();

        float speedFactor = direction != Vector2.Zero ? 1f : 0f;

        Move(gameTime, direction, speedFactor);
    }

    public void UpdateMouse(GameTime gameTime, Vector2 cursorPosition)
    {
        MouseState mouse = Mouse.GetState();

        Vector2 toTarget = cursorPosition - _position;
        float distance = toTarget.Length();

        Vector2 direction = Vector2.Zero;
        float speedFactor = 0f;

        if (mouse.LeftButton == ButtonState.Pressed && distance > StopRadius)
        {
            float t = MathHelper.Clamp(
                (distance - StopRadius) / (FullSpeedRadius - StopRadius),
                0f,
                1f
            );
            speedFactor = 1f - MathF.Pow(1f - t, 3f);
            direction = toTarget / distance;
        }

        Move(gameTime, direction, speedFactor);
    }

    private const float MinSpeedThreshold = 0.01f;

    private void Move(GameTime gameTime, Vector2 direction, float speedFactor)
    {
        float speed = Runtime.Get<float>("speed");
        float animSpeed = 0f;

        if (direction != Vector2.Zero && speedFactor > MinSpeedThreshold)
        {
            Vector2 step = direction * speed * speedFactor;
            _facingLeft =
                direction.X < 0f ? true
                : direction.X > 0f ? false
                : _facingLeft;
            _position += step;
            animSpeed = step.Length();
        }
        _animator.Update(gameTime, animSpeed, _facingLeft);
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _animator.Draw(spriteBatch, _position);
    }
}
