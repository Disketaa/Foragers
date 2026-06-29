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
        foreach (ReflectionEntry entry in _entries)
        {
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
