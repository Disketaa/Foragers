using Foragers_Project.Core.World;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core.Helpers;

public static class Collisions
{
    private static Texture2D? _pixel;

    public static void Initialize(GraphicsDevice graphicsDevice)
    {
        if (_pixel == null)
        {
            _pixel = new Texture2D(graphicsDevice, 1, 1);
            _pixel.SetData([Color.White]);
        }
    }

    public static bool IntersectsTile(Rectangle bounds) => TileMap.IntersectsTile(bounds);

    public static bool IntersectsNeighborTiles(Vector2 worldPos, int radiusInTiles = 1) =>
        TileMap.IntersectsNeighborTiles(worldPos, radiusInTiles);

    public static void DrawDebug(SpriteBatch spriteBatch, Rectangle bounds)
    {
        if (_pixel == null)
            return;

        Color debugColor = new(255, 0, 0, 128);

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

public sealed class CollisionBox
{
    public int Width { get; }
    public int Height { get; }
    public int OffsetX { get; }
    public int OffsetY { get; }

    public CollisionBox(int width, int height, int offsetX = 0, int offsetY = 0)
    {
        Width = width;
        Height = height;
        OffsetX = offsetX;
        OffsetY = offsetY;
    }

    public Rectangle GetBounds(Vector2 position, float pivotX, float pivotY)
    {
        float originX = Width * pivotX;
        float originY = Height * pivotY;

        int x = (int)(position.X + OffsetX - originX);
        int y = (int)(position.Y + OffsetY - originY);

        return new Rectangle(x, y, Width, Height);
    }
}
