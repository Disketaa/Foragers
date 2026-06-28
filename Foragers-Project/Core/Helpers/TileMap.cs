using Foragers_Project.Core.World;
using Microsoft.Xna.Framework;

namespace Foragers_Project.Core.Helpers;

public static class TileMap
{
    private static Vector2 _worldOffset;

    public static bool IsInitialized => Generator.IsInitialized;
    public static Vector2 WorldOffset => _worldOffset;

    public static void SetWorldOffset(Vector2 offset)
    {
        _worldOffset = offset;
    }

    public static bool IsFilled(int tileX, int tileY) => Generator.IsFilled(tileX, tileY);

    public static bool IsFilledWorldPosition(Vector2 worldPos)
    {
        int tileSize = Generator.TilePixelSize;
        int tileX = (int)((worldPos.X - _worldOffset.X) / tileSize);
        int tileY = (int)((worldPos.Y - _worldOffset.Y) / tileSize);
        return Generator.IsFilled(tileX, tileY);
    }

    public static bool IntersectsTile(Rectangle bounds)
    {
        if (!IsInitialized)
            return false;

        int tileSize = Generator.TilePixelSize;

        int leftTile = (int)((bounds.Left - _worldOffset.X) / tileSize);
        int rightTile = (int)((bounds.Right - 1 - _worldOffset.X) / tileSize);
        int topTile = (int)((bounds.Top - _worldOffset.Y) / tileSize);
        int bottomTile = (int)((bounds.Bottom - 1 - _worldOffset.Y) / tileSize);

        for (int y = topTile; y <= bottomTile; y++)
        {
            for (int x = leftTile; x <= rightTile; x++)
            {
                if (Generator.IsFilled(x, y))
                    return true;
            }
        }

        return false;
    }

    public static bool IntersectsNeighborTiles(Vector2 worldPos, int radiusInTiles = 1)
    {
        if (!IsInitialized)
            return false;

        int tileSize = Generator.TilePixelSize;
        int centerX = (int)((worldPos.X - _worldOffset.X) / tileSize);
        int centerY = (int)((worldPos.Y - _worldOffset.Y) / tileSize);

        for (int dy = -radiusInTiles; dy <= radiusInTiles; dy++)
        {
            for (int dx = -radiusInTiles; dx <= radiusInTiles; dx++)
            {
                if (Generator.IsFilled(centerX + dx, centerY + dy))
                    return true;
            }
        }

        return false;
    }
}

public interface ICollidable
{
    bool NeedsTileCollision { get; }
    Vector2 Position { get; }
    CollisionBox? CollisionBox { get; }
}
