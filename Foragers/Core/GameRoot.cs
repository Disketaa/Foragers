using System;
using Foragers.Core.Helpers;
using Foragers.Core.Player;
using Foragers.Core.Shaders;
using Foragers.Core.World;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Content;
using Microsoft.Xna.Framework.Graphics;
using Microsoft.Xna.Framework.Input;

namespace Foragers.Core;

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
    private ShaderRenderer _shaderRenderer = null!;
    private bool _debugMode;
    private bool _needsWorldReload;
    private KeyboardState _prevKeyboardState;
    private string _tilePalettePath = string.Empty;
    private string _characterPath = string.Empty;

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
        UpdateWindowTitle();
    }

    protected override void Initialize()
    {
        base.Initialize();
        UpdateWindowTitle();
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

        string cursorPath = Path.Combine(
            AppDomain.CurrentDomain.BaseDirectory,
            Content.RootDirectory,
            "Assets",
            "UI",
            "Cursor.png"
        );
        _cursor = Texture2D.FromFile(GraphicsDevice, cursorPath);

        Collisions.Initialize(GraphicsDevice);

        Runtime.RegisterJson("Core/Options.json");
        Runtime.RegisterJson("Entity/Player.json");
        Runtime.RegisterJson("World/World.json");

        Runtime.FileReloaded += OnFileReloaded;

        _debugMode = Runtime.GetBool("Core/Options.json", "DebugMode", false);
        UpdateWindowTitle();

        _characterPath = Path.Combine(Content.RootDirectory, "Assets", "Entity", "Character.json");
        Runtime.RegisterJsonByPath(_characterPath);

        _player = new PlayerController(GraphicsDevice, _characterPath, new Vector2(320, 180));

        _tilePalettePath = Path.Combine(
            Content.RootDirectory,
            "Assets",
            "World",
            "TilesGrass.json"
        );

        _world = new Generator(GraphicsDevice, _tilePalettePath, "World/World.json");

        _shaderRenderer = new ShaderRenderer(GraphicsDevice);

        Vector2 worldOffset = new(
            (BaseWidth - Generator.WorldWidth) / 2f,
            (BaseHeight - Generator.WorldHeight) / 2f
        );
        TileMap.SetWorldOffset(worldOffset);
    }

    private void OnFileReloaded(string filePath)
    {
        if (filePath.EndsWith("World.json", StringComparison.OrdinalIgnoreCase))
        {
            _needsWorldReload = true;
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

    private void UpdateWindowTitle()
    {
        Window.Title = _debugMode ? "Foragers (Debugging)" : "Foragers";
    }

    protected override void Update(GameTime gameTime)
    {
        if (!IsActive)
        {
            base.Update(gameTime);
            return;
        }

        Runtime.Update();

        if (_needsWorldReload)
        {
            _needsWorldReload = false;
            _world = Generator.Reload(GraphicsDevice, _tilePalettePath, "World/World.json");
        }

        _debugMode = Runtime.GetBool("Core/Options.json", "DebugMode", false);
        UpdateWindowTitle();

        MouseState mouse = Mouse.GetState();
        float cursorX = (mouse.X - _offsetX) / (float)_scale;
        float cursorY = (mouse.Y - _offsetY) / (float)_scale;
        Vector2 cursorPos = new(cursorX, cursorY);

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

        KeyboardState keyboard = Keyboard.GetState();
        if (keyboard.IsKeyDown(Keys.F1) && _prevKeyboardState.IsKeyUp(Keys.F1))
        {
            _debugMode = !_debugMode;
            Runtime.Set("Core/Options.json", "DebugMode", _debugMode);
            UpdateWindowTitle();
        }
        _prevKeyboardState = keyboard;

        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        MouseState drawMouse = Mouse.GetState();
        int gameMouseX = (drawMouse.X - _offsetX) / _scale;
        int gameMouseY = (drawMouse.Y - _offsetY) / _scale;

        ShaderMaterial? tileMaterial = _shaderRenderer.GetTileMaterial();
        bool useTileShader = tileMaterial?.IsValid == true;

        Vector2 worldPos = new(
            (BaseWidth - Generator.WorldWidth) / 2f,
            (BaseHeight - Generator.WorldHeight) / 2f
        );

        GraphicsDevice.SetRenderTarget(_renderTarget);
        GraphicsDevice.Clear(new Color(46, 171, 212));

        if (useTileShader && tileMaterial != null)
        {
            var view = Matrix.CreateTranslation(0, 0, 0);
            var projection = Matrix.CreateOrthographicOffCenter(0, BaseWidth, BaseHeight, 0, 0, 1);
            _shaderRenderer.ApplyViewProjection(view, projection);

            Effect? tileEffect = tileMaterial.Effect;
            if (tileEffect != null)
            {
                _spriteBatch.Begin(
                    SpriteSortMode.Immediate,
                    null,
                    SamplerState.PointClamp,
                    null,
                    null,
                    tileEffect
                );
                _world.DrawShaded(_spriteBatch, worldPos);
                _spriteBatch.End();
            }
        }
        else
        {
            _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);
            _world.Draw(_spriteBatch, worldPos);
            _spriteBatch.End();
        }

        _spriteBatch.Begin(SpriteSortMode.Deferred, null, SamplerState.PointClamp);
        _player.Draw(_spriteBatch, _debugMode);
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
}
