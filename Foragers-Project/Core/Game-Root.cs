using Foragers_Project.Core.Helpers;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Foragers_Project.Core;

public class GameRoot : Game
{
    private const int BaseWidth = 640;
    private const int BaseHeight = 360;

    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch = null!;
    private Texture2D _tiledBackground = null!;
    private Texture2D _cursor = null!;
    private RenderTarget2D _renderTarget = null!;
    private int _scale = 1;
    private int _offsetX;
    private int _offsetY;

    private PlayerController _player = null!;
    private string _playerDataPath = string.Empty;
    private bool _needsReload;
    private FileSystemWatcher? _fileWatcher;

    public GameRoot()
    {
        _graphics = new GraphicsDeviceManager(this)
        {
            PreferredBackBufferWidth = BaseWidth,
            PreferredBackBufferHeight = BaseHeight,
            IsFullScreen = false,
        };

        Content.RootDirectory = "Content";
        Window.AllowUserResizing = true;
        Window.ClientSizeChanged += OnResize;
        IsMouseVisible = false;
    }

    protected override void Initialize()
    {
        base.Initialize();
        UpdateScale();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _tiledBackground = Texture2D.FromFile(
            GraphicsDevice,
            Path.Combine(Content.RootDirectory, "Assets", "World", "Tiled-Background.png")
        );

        _renderTarget = new RenderTarget2D(
            GraphicsDevice,
            BaseWidth,
            BaseHeight,
            false,
            SurfaceFormat.Color,
            DepthFormat.None
        );

        _cursor = Texture2D.FromFile(
            GraphicsDevice,
            Path.Combine(Content.RootDirectory, "Assets", "UI", "Cursor.png")
        );

        _playerDataPath = Path.Combine(Content.RootDirectory, "Data", "Entity", "Player.json");
        Runtime.Load(_playerDataPath);

        _player = new PlayerController(
            GraphicsDevice,
            Path.Combine(Content.RootDirectory, "Assets", "Entity", "Character.anim.json"),
            new Vector2(320, 180)
        );

        SetupFileWatcher();
    }

    private void SetupFileWatcher()
    {
        string directory = Path.GetDirectoryName(_playerDataPath) ?? string.Empty;
        if (!string.IsNullOrEmpty(directory) && Directory.Exists(directory))
        {
            _fileWatcher = new FileSystemWatcher(directory, "Player.json");
            _fileWatcher.NotifyFilter = NotifyFilters.LastWrite;
            _fileWatcher.Changed += (s, e) => _needsReload = true;
            _fileWatcher.EnableRaisingEvents = true;
        }
    }

    private void OnResize(object? sender, EventArgs e)
    {
        UpdateScale();
    }

    private void UpdateScale()
    {
        int screenWidth = GraphicsDevice.PresentationParameters.BackBufferWidth;
        int screenHeight = GraphicsDevice.PresentationParameters.BackBufferHeight;

        int scaleX = (screenWidth + BaseWidth - 1) / BaseWidth;
        int scaleY = (screenHeight + BaseHeight - 1) / BaseHeight;
        _scale = Math.Max(1, Math.Max(scaleX, scaleY));

        _offsetX = (screenWidth - BaseWidth * _scale) / 2;
        _offsetY = (screenHeight - BaseHeight * _scale) / 2;
    }

    protected override void Update(GameTime gameTime)
    {
        if (_needsReload)
        {
            _needsReload = false;
            Runtime.Load(_playerDataPath);
        }

        MouseState mouse = Mouse.GetState();
        float cursorX = (mouse.X - _offsetX) / (float)_scale;
        float cursorY = (mouse.Y - _offsetY) / (float)_scale;
        _player.UpdateMouse(gameTime, new Vector2(cursorX, cursorY));

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        MouseState drawMouse = Mouse.GetState();
        int gameMouseX = (drawMouse.X - _offsetX) / _scale;
        int gameMouseY = (drawMouse.Y - _offsetY) / _scale;

        GraphicsDevice.SetRenderTarget(_renderTarget);
        GraphicsDevice.Clear(Color.Black);

        _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);

        for (int x = 0; x < BaseWidth; x += _tiledBackground.Width)
        for (int y = 0; y < BaseHeight; y += _tiledBackground.Height)
            _spriteBatch.Draw(_tiledBackground, new Vector2(x, y), Color.White);

        _player.Draw(_spriteBatch);

        _spriteBatch.End();

        _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);
        _spriteBatch.Draw(_cursor, new Vector2(gameMouseX, gameMouseY), Color.White);
        _spriteBatch.End();

        GraphicsDevice.SetRenderTarget(null);
        GraphicsDevice.Clear(Color.Black);

        _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);

        _spriteBatch.Draw(
            _renderTarget,
            new Rectangle(_offsetX, _offsetY, BaseWidth * _scale, BaseHeight * _scale),
            Color.White
        );

        _spriteBatch.End();

        base.Draw(gameTime);
    }

    protected override void UnloadContent()
    {
        _fileWatcher?.Dispose();
        base.UnloadContent();
    }
}
