using Foragers.Core.World;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers.Core.Helpers;

public sealed class ReflectionRenderer
{
    private readonly List<ReflectionEntry> _entries = [];

    public void Register(
        Texture2D texture,
        Func<Rectangle> sourceRectProvider,
        Func<Vector2> positionProvider,
        Func<SpriteEffects> effectsProvider,
        Func<Vector2> originProvider,
        Func<Vector2>? anchorProvider = null,
        Func<Vector2>? scaleProvider = null,
        Func<Vector2>? offsetProvider = null
    )
    {
        _entries.Add(
            new ReflectionEntry(
                texture,
                sourceRectProvider,
                positionProvider,
                effectsProvider,
                originProvider,
                anchorProvider,
                scaleProvider,
                offsetProvider
            )
        );
    }

    public void Clear() => _entries.Clear();

    public void Draw(SpriteBatch spriteBatch)
    {
        if (!TileMap.IsInitialized)
            return;

        DrawTileReflections(spriteBatch);
        DrawEntries(spriteBatch);
    }

    private static void DrawTileReflections(SpriteBatch spriteBatch)
    {
        int tileSize = Generator.TilePixelSize;
        int tileCount = Generator.TileCount;
        Vector2 worldOffset = TileMap.WorldOffset;
        Texture2D tileTexture = Generator.TileTexture;

        for (int y = 0; y < tileCount; y++)
        {
            for (int x = 0; x < tileCount; x++)
            {
                if (!Generator.IsFilled(x, y))
                    continue;

                if (Generator.IsFilled(x, y + 1))
                    continue;

                int tileIndex = Generator.GetTileIndex(x, y);
                if (tileIndex < 0)
                    continue;

                Rectangle sourceRect = Generator.GetTileSourceRect(tileIndex);
                Vector2 tilePos = new(
                    worldOffset.X + (x * tileSize),
                    worldOffset.Y + (y * tileSize)
                );

                Vector2 reflectedPos = new(tilePos.X, tilePos.Y + tileSize);

                spriteBatch.Draw(
                    tileTexture,
                    reflectedPos,
                    sourceRect,
                    Color.White * 0.35f,
                    0f,
                    Vector2.Zero,
                    Vector2.One,
                    SpriteEffects.FlipVertically,
                    0f
                );
            }
        }
    }

    private void DrawEntries(SpriteBatch spriteBatch)
    {
        int tileSize = Generator.TilePixelSize;
        Vector2 worldOffset = TileMap.WorldOffset;

        for (int i = 0; i < _entries.Count; i++)
        {
            ReflectionEntry entry = _entries[i];
            Vector2 position = entry.PositionProvider();
            Rectangle sourceRect = entry.SourceRectProvider();
            SpriteEffects effects = entry.EffectsProvider() | SpriteEffects.FlipVertically;
            Vector2 anchor = entry.AnchorProvider?.Invoke() ?? position;
            Vector2 origin = entry.OriginProvider();
            Vector2 scale = entry.ScaleProvider?.Invoke() ?? Vector2.One;
            Vector2 offset = entry.OffsetProvider?.Invoke() ?? Vector2.Zero;

            // The reflection should follow the same visual origin as the main sprite, not the frame edge.
            Vector2 reflectedPosition = new(
                anchor.X + offset.X,
                anchor.Y + offset.Y + (sourceRect.Height - origin.Y)
            );

            float drawX = reflectedPosition.X - origin.X * scale.X;
            float drawY = reflectedPosition.Y - origin.Y * scale.Y;
            int drawWidth = (int)(sourceRect.Width * scale.X);
            int drawHeight = (int)(sourceRect.Height * scale.Y);

            if ((effects & SpriteEffects.FlipHorizontally) != 0)
            {
                drawX = reflectedPosition.X - (sourceRect.Width - origin.X) * scale.X;
            }

            Rectangle reflectionBounds = new((int)drawX, (int)drawY, drawWidth, drawHeight);

            int leftTile = (int)Math.Floor((reflectionBounds.Left - worldOffset.X) / tileSize);
            int rightTile = (int)
                Math.Floor((reflectionBounds.Right - 1 - worldOffset.X) / tileSize);
            int topTile = (int)Math.Floor((reflectionBounds.Top - worldOffset.Y) / tileSize);
            int bottomTile = (int)
                Math.Floor((reflectionBounds.Bottom - 1 - worldOffset.Y) / tileSize);

            bool fullyCovered = true;
            bool hasAnyTile = false;

            for (int y = topTile; y <= bottomTile; y++)
            {
                for (int x = leftTile; x <= rightTile; x++)
                {
                    if (Generator.IsFilled(x, y))
                    {
                        hasAnyTile = true;
                    }
                    else
                    {
                        fullyCovered = false;
                        break;
                    }
                }
                if (!fullyCovered)
                    break;
            }

            if (fullyCovered && hasAnyTile)
            {
                continue;
            }

            spriteBatch.Draw(
                entry.Texture,
                reflectedPosition,
                sourceRect,
                Color.White * 0.35f,
                0f,
                origin,
                scale,
                effects,
                0f
            );
        }
    }

    private sealed class ReflectionEntry(
        Texture2D texture,
        Func<Rectangle> sourceRectProvider,
        Func<Vector2> positionProvider,
        Func<SpriteEffects> effectsProvider,
        Func<Vector2> originProvider,
        Func<Vector2>? anchorProvider,
        Func<Vector2>? scaleProvider,
        Func<Vector2>? offsetProvider
    )
    {
        public Texture2D Texture { get; } = texture;
        public Func<Rectangle> SourceRectProvider { get; } = sourceRectProvider;
        public Func<Vector2> PositionProvider { get; } = positionProvider;
        public Func<SpriteEffects> EffectsProvider { get; } = effectsProvider;
        public Func<Vector2> OriginProvider { get; } = originProvider;
        public Func<Vector2>? AnchorProvider { get; } = anchorProvider;
        public Func<Vector2>? ScaleProvider { get; } = scaleProvider;
        public Func<Vector2>? OffsetProvider { get; } = offsetProvider;
    }
}
