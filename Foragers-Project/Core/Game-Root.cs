using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace Foragers_Project.Core;

public class GameRoot : Game
{
    private readonly GraphicsDeviceManager _graphics;
    private SpriteBatch _spriteBatch = null!;
    private Texture2D _tiledBackground = null!;

    public GameRoot()
    {
        _graphics = new GraphicsDeviceManager(this)
        {
            PreferredBackBufferWidth = 640,
            PreferredBackBufferHeight = 360,
            IsFullScreen = false,
        };

        Content.RootDirectory = "Content";
    }

    protected override void Initialize()
    {
        base.Initialize();
    }

    protected override void LoadContent()
    {
        _spriteBatch = new SpriteBatch(GraphicsDevice);
        _tiledBackground = Texture2D.FromFile(
            GraphicsDevice,
            Path.Combine(Content.RootDirectory, "Assets", "World", "Tiled-Background.png")
        );
    }

    protected override void Update(GameTime gameTime)
    {
        base.Update(gameTime);
    }

    protected override void Draw(GameTime gameTime)
    {
        GraphicsDevice.Clear(Color.Black);

        _spriteBatch.Begin();

        int screenWidth = _graphics.PreferredBackBufferWidth;
        int screenHeight = _graphics.PreferredBackBufferHeight;
        int tileWidth = _tiledBackground.Width;
        int tileHeight = _tiledBackground.Height;

        for (int x = 0; x < screenWidth; x += tileWidth)
        for (int y = 0; y < screenHeight; y += tileHeight)
            _spriteBatch.Draw(_tiledBackground, new Vector2(x, y), Color.White);

        _spriteBatch.End();

        base.Draw(gameTime);
    }
}
