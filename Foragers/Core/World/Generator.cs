using Foragers.Core.Helpers;
using Foragers.Core.Shaders;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.World;

public sealed class Generator
{
    private readonly int _seed;
    private readonly float[] _map;
    private readonly int[] _tileIndices;
    private readonly TilePalette _palette;
    private readonly float _threshold;
    private readonly int _tileSize;
    private readonly int _worldTiles;
    private readonly string _dataPath;

    public static int WorldWidth => Instance._worldTiles * Instance._tileSize;
    public static int WorldHeight => Instance._worldTiles * Instance._tileSize;
    public static int TileCount => Instance._worldTiles;
    public static int TilePixelSize => Instance._tileSize;
    public static int Seed => Instance._seed;

    private static Generator? _instance;
    public static bool IsInitialized => _instance != null;
    private static Generator Instance =>
        _instance ?? throw new InvalidOperationException("Generator not initialized");

    public static Generator Reload(
        GraphicsDevice graphicsDevice,
        string palettePath,
        string dataPath
    )
    {
        _instance = new Generator(graphicsDevice, palettePath, dataPath);
        return _instance;
    }

    public Generator(GraphicsDevice graphicsDevice, string palettePath, string dataPath)
    {
        _dataPath = dataPath;
        _tileSize = Runtime.GetInt(dataPath, "tileSize", 8);
        _worldTiles = Runtime.GetInt(dataPath, "worldTiles", 20);
        _seed = Runtime.GetInt(dataPath, "seed", 0);
        _threshold = Runtime.GetFloat(dataPath, "threshold", 0.5f);

        if (_seed == -1)
        {
            _seed = new Random().Next();
        }

        _palette = new TilePalette(graphicsDevice, palettePath);
        _map = new float[_worldTiles * _worldTiles];
        _tileIndices = new int[_worldTiles * _worldTiles];
        Generate();
        ResolveTiles();
        _instance = this;
    }

    private void Generate()
    {
        int octaves = Runtime.GetInt(_dataPath, "octaves", 4);
        float persistence = Runtime.GetFloat(_dataPath, "persistence", 0.5f);
        float lacunarity = Runtime.GetFloat(_dataPath, "lacunarity", 2.0f);
        float scale = Runtime.GetFloat(_dataPath, "scale", 0.1f);

        float maxAmplitude = 0f;
        float amplitude = 1f;
        for (int i = 0; i < octaves; i++)
        {
            maxAmplitude += amplitude;
            amplitude *= persistence;
        }

        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                amplitude = 1f;
                float frequency = scale;
                float noiseValue = 0f;

                for (int o = 0; o < octaves; o++)
                {
                    float sampleX = x * frequency;
                    float sampleY = y * frequency;
                    noiseValue += SampleNoise(sampleX, sampleY) * amplitude;
                    amplitude *= persistence;
                    frequency *= lacunarity;
                }

                _map[(y * _worldTiles) + x] = noiseValue / maxAmplitude;
            }
        }
    }

    private float SampleNoise(float x, float y)
    {
        int x0 = FloorInt(x);
        int x1 = x0 + 1;
        int y0 = FloorInt(y);
        int y1 = y0 + 1;

        float sx = Fade(x - x0);
        float sy = Fade(y - y0);

        float n00 = ValueAt(x0, y0);
        float n10 = ValueAt(x1, y0);
        float n01 = ValueAt(x0, y1);
        float n11 = ValueAt(x1, y1);

        float ix0 = Lerp(n00, n10, sx);
        float ix1 = Lerp(n01, n11, sx);

        return Lerp(ix0, ix1, sy);
    }

    private float ValueAt(int x, int y)
    {
        int hash = Hash(x, y, _seed);
        return (hash & 0xFFFF) / 65535f;
    }

    private static int Hash(int x, int y, int seed)
    {
        int h = seed;
        h ^= x * 374761393;
        h ^= y * 668265263;
        h = (h ^ (h >> 13)) * 1274126177;
        return h ^ (h >> 16);
    }

    private static float Fade(float t) => t * t * t * ((t * ((t * 6f) - 15f)) + 10f);

    private static float Lerp(float a, float b, float t) => a + (t * (b - a));

    private static int FloorInt(float x) => x >= 0 ? (int)x : (int)x - 1;

    private bool IsFilledLocal(int x, int y)
    {
        if (x < 0 || x >= _worldTiles || y < 0 || y >= _worldTiles)
            return false;
        return _map[(y * _worldTiles) + x] >= _threshold;
    }

    public static bool IsFilled(int x, int y)
    {
        if (x < 0 || x >= Instance._worldTiles || y < 0 || y >= Instance._worldTiles)
            return false;
        return Instance._map[(y * Instance._worldTiles) + x] >= Instance._threshold;
    }

    public void Draw(SpriteBatch spriteBatch, Vector2 position)
    {
        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                int tileIndex = _tileIndices[(y * _worldTiles) + x];
                if (tileIndex < 0)
                    continue;

                Vector2 tilePos = new(position.X + (x * _tileSize), position.Y + (y * _tileSize));
                _palette.Draw(spriteBatch, tileIndex, tilePos);
            }
        }
    }

    private static int _tileDrawCounter;

    public void DrawWithShadedColor(
        SpriteBatch spriteBatch,
        ShaderRenderer shaderRenderer,
        Vector2 position
    )
    {
        _tileDrawCounter = 0;
        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                int tileIndex = _tileIndices[(y * _worldTiles) + x];
                if (tileIndex < 0)
                    continue;

                Vector2 tilePos = new(position.X + (x * _tileSize), position.Y + (y * _tileSize));
                Vector4 color = ShaderRenderer.GetRandomColor();
                _palette.DrawWithColor(
                    spriteBatch,
                    shaderRenderer.GetTileMaterial()?.Effect,
                    tileIndex,
                    tilePos,
                    color
                );
                _tileDrawCounter++;
            }
        }
        Core.Shaders.ShaderDebugLog.Write(
            $"DrawWithShadedColor: drew {_tileDrawCounter} tiles at {position}"
        );
    }

    private void ResolveTiles()
    {
        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                if (!IsFilledLocal(x, y))
                {
                    _tileIndices[(y * _worldTiles) + x] = -1;
                    continue;
                }

                int baseIndex = ResolveAutotileIndex(x, y);
                int variantSeed = Hash(x, y, _seed);

                _tileIndices[(y * _worldTiles) + x] = _palette.ResolveVariant(
                    baseIndex,
                    variantSeed
                );
            }
        }
    }

    private int ResolveAutotileIndex(int x, int y)
    {
        bool top = y > 0 && IsFilledLocal(x, y - 1);
        bool right = x < _worldTiles - 1 && IsFilledLocal(x + 1, y);
        bool bottom = y < _worldTiles - 1 && IsFilledLocal(x, y + 1);
        bool left = x > 0 && IsFilledLocal(x - 1, y);

        return _palette.ResolveTileIndex(top, right, bottom, left);
    }
}
