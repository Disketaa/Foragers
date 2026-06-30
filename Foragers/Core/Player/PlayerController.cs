using Foragers.Core.Helpers;
using Foragers.Core.World;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Foragers.Core.Player;

public sealed class PlayerController(
    GraphicsDevice graphicsDevice,
    string animPath,
    Vector2 startPosition
) : ICollidable
{
    private readonly PlayerAnimator _animator = new PlayerAnimator(graphicsDevice, animPath);
    private Vector2 _position = startPosition;
    private bool _facingLeft;

    private static float GamepadDeadzone =>
        Runtime.GetFloat("Core/Options.json", "GamepadDeadzone", 0.2f);
    private static float MouseStopRadius =>
        Runtime.GetFloat("Core/Options.json", "MouseStopRadius", 4f);
    private static float MouseFullSpeedRadius =>
        Runtime.GetFloat("Core/Options.json", "MouseFullSpeedRadius", 64f);
    private const float MinSpeedFactor = 0.05f;

    public bool NeedsTileCollision => true;
    public Vector2 Position => _position;
    public CollisionBox? CollisionBox => _animator.Collision;

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

        var direction = new Vector2(stick.X, -stick.Y);
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

            if (speedFactor <= MinSpeedFactor)
                Move(gameTime, Vector2.Zero, 0f);
            else
                Move(gameTime, toTarget / distance, speedFactor);
        }
        else
        {
            Move(gameTime, Vector2.Zero, 0f);
        }
    }

    private void Move(GameTime gameTime, Vector2 direction, float speedFactor)
    {
        float runningSpeed = Runtime.GetFloat("Entity/Player.json", "running_speed", 1f);
        float swimmingSpeedMult = Runtime.GetFloat("Entity/Player.json", "swimming_speed", 0.5f);
        bool isSwimming = !IsOnTile();
        float speed = isSwimming ? swimmingSpeedMult : runningSpeed;

        if (direction != Vector2.Zero && speedFactor > 0f)
        {
            _position = WorldBorder.Clamp(
                _position + direction * speed * speedFactor,
                _animator.Collision,
                _animator.PivotX,
                _animator.PivotY
            );
            _facingLeft = direction.X < 0f || direction.X <= 0f && _facingLeft;
        }

        float animSpeed = isSwimming
            ? speedFactor * swimmingSpeedMult
            : (speedFactor > 0f ? speedFactor : 0f);

        _animator.Update(gameTime, animSpeed, _facingLeft, isSwimming);
    }

    private bool IsOnTile()
    {
        if (_animator.Collision == null)
            return false;

        Rectangle bounds = _animator.Collision.GetBounds(
            _position,
            _animator.PivotX,
            _animator.PivotY
        );
        return TileMap.IntersectsTile(bounds);
    }

    public void Draw(SpriteBatch spriteBatch, bool debugMode = false)
    {
        _animator.Draw(spriteBatch, _position, debugMode);
    }
}
