using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core.World;

public sealed class TilePalette
{
    private readonly Texture2D _texture;
    private readonly int _tileWidth;
    private readonly int _tileHeight;
    private readonly int _columns;

    public TilePalette(GraphicsDevice graphicsDevice, string jsonPath)
    {
        Runtime.Load(jsonPath);

        string sheetPath = Runtime.Get<string>("sheet", string.Empty);
        _tileWidth = Runtime.Get<int>("tileWidth", 8);
        _tileHeight = Runtime.Get<int>("tileHeight", 8);
        _columns = Runtime.Get<int>("columns", 4);

        _texture = Texture2D.FromFile(
            graphicsDevice,
            Path.Combine("Content", "Assets", "World", sheetPath)
        );
    }

    public static int ResolveTileIndex(bool top, bool right, bool bottom, bool left)
    {
        if (!top && !right && !bottom && !left)
            return 0;

        bool h = left || right;
        bool v = top || bottom;

        if (h && !v)
        {
            if (left && right)
                return 2;
            if (right)
                return 1;
            if (left)
                return 3;
        }

        if (v && !h)
        {
            if (top && bottom)
                return 8;
            if (bottom)
                return 4;
            if (top)
                return 12;
        }

        if (top && right && bottom && left)
            return 10;

        if (bottom && right && left)
            return 6;
        if (top && right && left)
            return 14;
        if (top && bottom && left)
            return 11;
        if (top && bottom && right)
            return 9;

        if (top && right)
            return 13;
        if (right && bottom)
            return 5;
        if (bottom && left)
            return 7;
        if (left && top)
            return 15;

        if (top)
            return 14;
        if (right)
            return 9;
        if (bottom)
            return 6;
        if (left)
            return 11;

        return 10;
    }

    public Rectangle GetSourceRect(int tileIndex)
    {
        int col = tileIndex % _columns;
        int row = tileIndex / _columns;
        return new Rectangle(col * _tileWidth, row * _tileHeight, _tileWidth, _tileHeight);
    }

    public void Draw(SpriteBatch spriteBatch, int tileIndex, Vector2 position)
    {
        spriteBatch.Draw(_texture, position, GetSourceRect(tileIndex), Color.White);
    }

    public Texture2D Texture => _texture;
    public int TileWidth => _tileWidth;
    public int TileHeight => _tileHeight;
}
