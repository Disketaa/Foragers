using System.Text.Json;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public sealed class SpriteSheet
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly Dictionary<string, Rectangle[]> _animations;
    private readonly Dictionary<string, AnimationDef> _definitions;
    private readonly AnimationData _data;
    private readonly Texture2D _texture;

    public Texture2D Texture => _texture;
    public int FrameWidth => _data.FrameWidth;
    public int FrameHeight => _data.FrameHeight;

    public SpriteSheet(GraphicsDevice graphicsDevice, string jsonPath)
    {
        string json = File.ReadAllText(jsonPath);
        _data =
            JsonSerializer.Deserialize<AnimationData>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to parse animation file.");

        string directory = Path.GetDirectoryName(jsonPath) ?? "Content";
        string sheetPath = Path.Combine(directory, _data.Sheet);
        _texture = Texture2D.FromFile(graphicsDevice, sheetPath);

        _animations = [];
        _definitions = [];

        for (int row = 0; row < _data.Animations.Count; row++)
        {
            AnimationDef def = _data.Animations[row];
            Rectangle[] frames = new Rectangle[def.Frames];

            for (int i = 0; i < def.Frames; i++)
            {
                frames[i] = new Rectangle(
                    i * _data.FrameWidth,
                    row * _data.FrameHeight,
                    _data.FrameWidth,
                    _data.FrameHeight
                );
            }

            _animations[def.Name] = frames;
            _definitions[def.Name] = def;
        }
    }

    public Rectangle[] GetFrames(string name) => _animations[name];

    public AnimationDef GetDef(string name) => _definitions[name];

    public bool Has(string name) => _animations.ContainsKey(name);
}
