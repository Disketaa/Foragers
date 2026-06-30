using System;
using Foragers.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.World;

public sealed class TilePalette
{
    private static readonly int[] DefaultTileMap =
    {
        0,
        12,
        1,
        13,
        4,
        8,
        5,
        9,
        3,
        15,
        2,
        14,
        7,
        11,
        6,
        10,
    };

    private readonly Texture2D _texture;
    private readonly int _tileWidth;
    private readonly int _tileHeight;
    private readonly int _columns;
    private readonly int[] _tileMap;
    private readonly Dictionary<int, int[]> _variants;

    public TilePalette(GraphicsDevice graphicsDevice, string jsonPath)
    {
        string fullJsonPath = Path.Combine(AppDomain.CurrentDomain.BaseDirectory, jsonPath);

        Runtime.RegisterJsonByPath(fullJsonPath);

        string sheetPath = Runtime.GetString(fullJsonPath, "sheet", string.Empty);
        _tileWidth = Runtime.GetInt(fullJsonPath, "tileWidth", 8);
        _tileHeight = Runtime.GetInt(fullJsonPath, "tileHeight", 8);
        _columns = Runtime.GetInt(fullJsonPath, "columns", 4);
        _tileMap = Runtime.Get<int[]>(fullJsonPath, "tileMap", DefaultTileMap);
        _variants = Runtime.Get<Dictionary<int, int[]>>(fullJsonPath, "variants", []);

        string fullPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            "Content",
            "Assets",
            "World",
            sheetPath
        );
        _texture = Texture2D.FromFile(graphicsDevice, fullPath);
    }

    public int ResolveTileIndex(bool top, bool right, bool bottom, bool left)
    {
        int mask = (top ? 1 : 0) | (right ? 2 : 0) | (bottom ? 4 : 0) | (left ? 8 : 0);
        return _tileMap[mask];
    }

    public int ResolveVariant(int tileIndex, int variantSeed)
    {
        if (!_variants.TryGetValue(tileIndex, out int[]? options) || options.Length == 0)
            return tileIndex;

        int pick = (int)((uint)variantSeed % (uint)options.Length);
        return options[pick];
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
