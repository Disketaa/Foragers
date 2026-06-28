using Foragers_Project.Core.World;
using Microsoft.Xna.Framework;

namespace Foragers_Project.Core.Helpers;

public static class TileMap
{
    private static Vector2 _worldOffset;

    public static bool IsInitialized => Generator.IsInitialized;

    public static void SetWorldOffset(Vector2 offset)
    {
        _worldOffset = offset;
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
}

public interface ICollidable
{
    bool NeedsTileCollision { get; }
    Vector2 Position { get; }
    CollisionBox? CollisionBox { get; }
}
