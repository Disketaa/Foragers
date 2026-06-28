using Microsoft.Xna.Framework;

namespace Foragers_Project.Core.Helpers;

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
