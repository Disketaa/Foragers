using System;
using System.Text.Json;
using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public sealed class SpriteSheet
{
    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private readonly GraphicsDevice _graphicsDevice;
    private readonly string _jsonPath;
    private readonly string _fullPath;

    private Dictionary<string, Rectangle[]> _animations = null!;
    private Dictionary<string, AnimationDef> _definitions = null!;
    private AnimationData _data = null!;
    private Texture2D _texture = null!;

    public Texture2D Texture => _texture;
    public int FrameWidth => _data.FrameWidth;
    public int FrameHeight => _data.FrameHeight;
    public float PivotX => _data.PivotX;
    public float PivotY => _data.PivotY;
    public CollisionBox? Collision { get; private set; }

    public SpriteSheet(GraphicsDevice graphicsDevice, string jsonPath)
    {
        _graphicsDevice = graphicsDevice;
        _jsonPath = jsonPath;
        _fullPath = Path.GetFullPath(jsonPath);

        Load();

        Runtime.FileReloaded += OnFileReloaded;
    }

    private void OnFileReloaded(string filePath)
    {
        if (
            string.Equals(Path.GetFullPath(filePath), _fullPath, StringComparison.OrdinalIgnoreCase)
        )
        {
            Load();
        }
    }

    private void Load()
    {
        string json = File.ReadAllText(_jsonPath);
        _data =
            JsonSerializer.Deserialize<AnimationData>(json, JsonOptions)
            ?? throw new InvalidOperationException("Failed to parse animation file.");

        string baseDirectory = AppDomain.CurrentDomain.BaseDirectory;
        string directory = Path.GetDirectoryName(_jsonPath) ?? baseDirectory;
        string sheetPath = Path.IsPathRooted(directory)
            ? Path.Combine(directory, _data.Sheet)
            : Path.Combine(baseDirectory, directory, _data.Sheet);

        _texture?.Dispose();
        _texture = Texture2D.FromFile(_graphicsDevice, sheetPath);

        Collision = null;
        if (_data.Collision != null)
        {
            Collision = new CollisionBox(
                _data.Collision.Width,
                _data.Collision.Height,
                _data.Collision.OffsetX,
                _data.Collision.OffsetY
            );
        }

        _animations = [];
        _definitions = [];

        for (int row = 0; row < _data.Animations.Count; row++)
        {
            AnimationDef def = _data.Animations[row];
            var frames = new Rectangle[def.Frames];

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
