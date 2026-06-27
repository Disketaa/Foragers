using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core.World;

public sealed class Generator
{
    private const int TileSize = 8;
    private const int WorldTiles = 20;
    private const int WorldPixels = WorldTiles * TileSize;

    private readonly int _seed;
    private readonly float[] _map;
    private readonly Texture2D _tileTexture;
    private readonly float _threshold;

    public static int WorldWidth => WorldPixels;
    public static int WorldHeight => WorldPixels;
    public static int TileCount => WorldTiles;
    public static int TilePixelSize => TileSize;

    public Generator(Texture2D tileTexture, int seed, float threshold = 0.5f)
    {
        _seed = seed;
        _tileTexture = tileTexture;
        _threshold = threshold;
        _map = new float[WorldTiles * WorldTiles];
        Generate();
    }

    private void Generate()
    {
        int octaves = 4;
        float persistence = 0.5f;
        float lacunarity = 2.0f;
        float scale = 0.1f;

        float maxAmplitude = 0f;
        float amplitude = 1f;
        for (int i = 0; i < octaves; i++)
        {
            maxAmplitude += amplitude;
            amplitude *= persistence;
        }

        for (int y = 0; y < WorldTiles; y++)
        {
            for (int x = 0; x < WorldTiles; x++)
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

                _map[y * WorldTiles + x] = noiseValue / maxAmplitude;
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
        if (x < 0 || x >= WorldTiles || y < 0 || y >= WorldTiles)
            return 0f;
        return _map[y * WorldTiles + x];
    }

    public bool IsFilled(int x, int y) => GetTile(x, y) >= _threshold;

    public void Draw(SpriteBatch spriteBatch, Vector2 position)
    {
        for (int y = 0; y < WorldTiles; y++)
        {
            for (int x = 0; x < WorldTiles; x++)
            {
                float value = _map[y * WorldTiles + x];
                if (value < _threshold)
                    continue;

                int shade = (int)(value * 4);
                shade = shade > 3 ? 3 : shade;

                var destRect = new Rectangle(
                    (int)(position.X + x * TileSize),
                    (int)(position.Y + y * TileSize),
                    TileSize,
                    TileSize
                );

                spriteBatch.Draw(_tileTexture, destRect, Color.White);
            }
        }
    }
}
