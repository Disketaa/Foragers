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

    private static float GamepadDeadzone => Runtime.Get("GamepadDeadzone", 0.2f);
    private static float MouseStopRadius => Runtime.Get("MouseStopRadius", 4f);
    private static float MouseFullSpeedRadius => Runtime.Get("MouseFullSpeedRadius", 64f);

    public PlayerController(GraphicsDevice graphicsDevice, string animPath, Vector2 startPosition)
    {
        _animator = new PlayerAnimator(graphicsDevice, animPath);
        _position = startPosition;
    }

    public void UpdateKeyboard(GameTime gameTime)
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

        Move(gameTime, direction, direction != Vector2.Zero ? 1f : 0f);
    }

    public void UpdateGamepad(GameTime gameTime)
    {
        GamePadState gamePad = GamePad.GetState(0);
        Vector2 stick = gamePad.ThumbSticks.Left;

        float magnitude = stick.Length();

        if (magnitude < GamepadDeadzone)
        {
            Move(gameTime, Vector2.Zero, 0f);
            return;
        }

        float absX = MathF.Abs(stick.X);
        float absY = MathF.Abs(stick.Y);
        float maxComponent = Math.Max(absX, absY);

        float adjustedMagnitude = Math.Min(magnitude / maxComponent, 1f);
        float speedFactor = MathHelper.Clamp(
            (adjustedMagnitude - GamepadDeadzone) / (1f - GamepadDeadzone),
            0f,
            1f
        );

        Vector2 direction = new Vector2(stick.X, -stick.Y);
        direction.Normalize();

        Move(gameTime, direction, speedFactor);
    }

    public void UpdateMouse(GameTime gameTime, Vector2 cursorPosition)
    {
        Vector2 toTarget = cursorPosition - _position;
        float distance = toTarget.Length();

        if (Mouse.GetState().LeftButton == ButtonState.Pressed && distance > MouseStopRadius)
        {
            float t = MathHelper.Clamp(
                (distance - MouseStopRadius) / (MouseFullSpeedRadius - MouseStopRadius),
                0f,
                1f
            );
            float speedFactor = 1f - MathF.Pow(1f - t, 3f);
            Move(gameTime, toTarget / distance, speedFactor);
        }
        else
        {
            Move(gameTime, Vector2.Zero, 0f);
        }
    }

    private void Move(GameTime gameTime, Vector2 direction, float speedFactor)
    {
        float speed = Runtime.Get("speed", 1f);

        if (direction != Vector2.Zero && speedFactor > 0f)
        {
            _position += direction * speed * speedFactor;
            _facingLeft =
                direction.X < 0f ? true
                : direction.X > 0f ? false
                : _facingLeft;
            _animator.Update(gameTime, speedFactor, _facingLeft);
        }
        else
        {
            _animator.Update(gameTime, 0f, _facingLeft);
        }
    }

    public void Draw(SpriteBatch spriteBatch)
    {
        _animator.Draw(spriteBatch, _position);
    }
}
