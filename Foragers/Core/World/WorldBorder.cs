using Foragers.Core.Helpers;
using Microsoft.Xna.Framework;

namespace Foragers.Core.World;

public static class WorldBorder
{
    private static int _padding = 8;

    public static void SetPadding(int tiles) => _padding = tiles;

    public static Vector2 Clamp(Vector2 position, CollisionBox? box, float pivotX, float pivotY)
    {
        if (!TileMap.IsInitialized || box == null)
            return position;

        int tileSize = Generator.TilePixelSize;
        int tiles = Generator.TileCount;

        Vector2 offset = TileMap.WorldOffset;
        float minX = offset.X - _padding * tileSize;
        float minY = offset.Y - _padding * tileSize;
        float maxX = offset.X + tiles * tileSize + _padding * tileSize - box.Width;
        float maxY = offset.Y + tiles * tileSize + _padding * tileSize - box.Height;

        float localX = position.X + box.OffsetX - box.Width * pivotX;
        float localY = position.Y + box.OffsetY - box.Height * pivotY;

        float clampedX = MathHelper.Clamp(localX, minX, maxX);
        float clampedY = MathHelper.Clamp(localY, minY, maxY);

        return new Vector2(
            clampedX - box.OffsetX + box.Width * pivotX,
            clampedY - box.OffsetY + box.Height * pivotY
        );
    }
}
