using Foragers_Project.Core.Helpers;
using Foragers_Project.Core.World;
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
    private Texture2D _cursor = null!;
    private RenderTarget2D _renderTarget = null!;
    private int _scale = 1;
    private int _offsetX;
    private int _offsetY;

    private PlayerController _player = null!;
    private Generator _world = null!;
    private string _playerDataPath = string.Empty;
    private string _worldDataPath = string.Empty;
    private string _tilePalettePath = string.Empty;
    private bool _needsReload;
    private bool _needsWorldReload;
    private FileSystemWatcher? _playerFileWatcher;
    private FileSystemWatcher? _worldFileWatcher;

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
            Path.Combine(Content.RootDirectory, "Assets", "Entity", "Character.json"),
            new Vector2(320, 180)
        );

        _tilePalettePath = Path.Combine(
            Content.RootDirectory,
            "Assets",
            "World",
            "Tiles-Grass.json"
        );

        _worldDataPath = Path.Combine(Content.RootDirectory, "Data", "World", "World.json");
        _world = new Generator(GraphicsDevice, _tilePalettePath, _worldDataPath);

        SetupFileWatcher();
    }

    private void SetupFileWatcher()
    {
        string playerDirectory = Path.GetDirectoryName(_playerDataPath) ?? string.Empty;
        if (!string.IsNullOrEmpty(playerDirectory) && Directory.Exists(playerDirectory))
        {
            _playerFileWatcher = new FileSystemWatcher(playerDirectory, "Player.json");
            _playerFileWatcher.NotifyFilter = NotifyFilters.LastWrite;
            _playerFileWatcher.Changed += (s, e) => _needsReload = true;
            _playerFileWatcher.EnableRaisingEvents = true;
        }

        string worldDirectory = Path.GetDirectoryName(_worldDataPath) ?? string.Empty;
        if (!string.IsNullOrEmpty(worldDirectory) && Directory.Exists(worldDirectory))
        {
            _worldFileWatcher = new FileSystemWatcher(worldDirectory, "World.json");
            _worldFileWatcher.NotifyFilter = NotifyFilters.LastWrite;
            _worldFileWatcher.Changed += (s, e) => _needsWorldReload = true;
            _worldFileWatcher.EnableRaisingEvents = true;
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
        if (!IsActive)
        {
            base.Update(gameTime);
            return;
        }

        if (_needsReload)
        {
            _needsReload = false;
            Runtime.Load(_playerDataPath);
        }

        if (_needsWorldReload)
        {
            _needsWorldReload = false;
            _world = Generator.Reload(GraphicsDevice, _tilePalettePath, _worldDataPath);
        }

        MouseState mouse = Mouse.GetState();
        float cursorX = (mouse.X - _offsetX) / (float)_scale;
        float cursorY = (mouse.Y - _offsetY) / (float)_scale;
        Vector2 cursorPos = new Vector2(cursorX, cursorY);

        GamePadState gamePad = GamePad.GetState(0);

        Vector2 stick = gamePad.ThumbSticks.Left;
        float magnitude = stick.Length();

        if (gamePad.IsConnected && magnitude >= 0.2f)
        {
            _player.UpdateGamepad(gameTime);
        }
        else if (mouse.LeftButton == ButtonState.Pressed)
        {
            _player.UpdateMouse(gameTime, cursorPos);
        }
        else
        {
            _player.UpdateKeyboard(gameTime);
        }

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        MouseState drawMouse = Mouse.GetState();
        int gameMouseX = (drawMouse.X - _offsetX) / _scale;
        int gameMouseY = (drawMouse.Y - _offsetY) / _scale;

        GraphicsDevice.SetRenderTarget(_renderTarget);
        GraphicsDevice.Clear(new Color(46, 171, 212));

        _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);

        _world.Draw(
            _spriteBatch,
            new Vector2(
                (BaseWidth - Generator.WorldWidth) / 2f,
                (BaseHeight - Generator.WorldHeight) / 2f
            )
        );

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
        _playerFileWatcher?.Dispose();
        _worldFileWatcher?.Dispose();
        base.UnloadContent();
    }
}
