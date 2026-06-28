using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core.Helpers;

public static class CollisionHelper
{
    private static Texture2D? _pixel;

    public static void Initialize(GraphicsDevice graphicsDevice)
    {
        if (_pixel == null)
        {
            _pixel = new Texture2D(graphicsDevice, 1, 1);
            _pixel.SetData(new[] { Color.White });
        }
    }

    public static void DrawDebug(SpriteBatch spriteBatch, Rectangle bounds)
    {
        if (_pixel == null)
            return;

        var debugColor = new Color(255, 0, 0, 128);

        spriteBatch.Draw(_pixel, new Rectangle(bounds.X, bounds.Y, bounds.Width, 1), debugColor);
        spriteBatch.Draw(
            _pixel,
            new Rectangle(bounds.X, bounds.Y + bounds.Height - 1, bounds.Width, 1),
            debugColor
        );
        spriteBatch.Draw(_pixel, new Rectangle(bounds.X, bounds.Y, 1, bounds.Height), debugColor);
        spriteBatch.Draw(
            _pixel,
            new Rectangle(bounds.X + bounds.Width - 1, bounds.Y, 1, bounds.Height),
            debugColor
        );

        int centerX = bounds.X + bounds.Width / 2;
        int centerY = bounds.Y + bounds.Height / 2;

        spriteBatch.Draw(_pixel, new Rectangle(centerX - 2, centerY, 5, 1), debugColor);
        spriteBatch.Draw(_pixel, new Rectangle(centerX, centerY - 2, 1, 5), debugColor);
    }
}
