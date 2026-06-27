using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core.World;

public sealed class Generator
{
    private readonly int _seed;
    private readonly float[] _map;
    private readonly int[] _tileIndices;
    private readonly TilePalette _palette;
    private readonly float _threshold;
    private readonly int _tileSize;
    private readonly int _worldTiles;

    public static int WorldWidth => Instance._worldTiles * Instance._tileSize;
    public static int WorldHeight => Instance._worldTiles * Instance._tileSize;
    public static int TileCount => Instance._worldTiles;
    public static int TilePixelSize => Instance._tileSize;
    public static int Seed => Instance._seed;

    private static Generator? _instance;
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
        Runtime.Load(dataPath);

        _tileSize = Runtime.Get("tileSize", 8);
        _worldTiles = Runtime.Get("worldTiles", 20);
        _seed = Runtime.Get("seed", 0);
        _threshold = Runtime.Get("threshold", 0.5f);

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
        int octaves = Runtime.Get("octaves", 4);
        float persistence = Runtime.Get("persistence", 0.5f);
        float lacunarity = Runtime.Get("lacunarity", 2.0f);
        float scale = Runtime.Get("scale", 0.1f);

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

                _map[y * _worldTiles + x] = noiseValue / maxAmplitude;
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

    private static float Fade(float t) => t * t * t * (t * (t * 6f - 15f) + 10f);

    private static float Lerp(float a, float b, float t) => a + t * (b - a);

    private static int FloorInt(float x) => x >= 0 ? (int)x : (int)x - 1;

    public float GetTile(int x, int y)
    {
        if (x < 0 || x >= _worldTiles || y < 0 || y >= _worldTiles)
            return 0f;
        return _map[y * _worldTiles + x];
    }

    public bool IsFilled(int x, int y) => GetTile(x, y) >= _threshold;

    public void Draw(SpriteBatch spriteBatch, Vector2 position)
    {
        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                int tileIndex = _tileIndices[y * _worldTiles + x];
                if (tileIndex < 0)
                    continue;

                Vector2 tilePos = new(position.X + x * _tileSize, position.Y + y * _tileSize);
                _palette.Draw(spriteBatch, tileIndex, tilePos);
            }
        }
    }

    private void ResolveTiles()
    {
        for (int y = 0; y < _worldTiles; y++)
        {
            for (int x = 0; x < _worldTiles; x++)
            {
                if (!IsFilled(x, y))
                {
                    _tileIndices[y * _worldTiles + x] = -1;
                    continue;
                }

                int baseIndex = ResolveAutotileIndex(x, y);
                int variantSeed = Hash(x, y, _seed);

                _tileIndices[y * _worldTiles + x] = _palette.ResolveVariant(baseIndex, variantSeed);
            }
        }
    }

    private int ResolveAutotileIndex(int x, int y)
    {
        bool top = y > 0 && IsFilled(x, y - 1);
        bool right = x < _worldTiles - 1 && IsFilled(x + 1, y);
        bool bottom = y < _worldTiles - 1 && IsFilled(x, y + 1);
        bool left = x > 0 && IsFilled(x - 1, y);

        return _palette.ResolveTileIndex(top, right, bottom, left);
    }
}
