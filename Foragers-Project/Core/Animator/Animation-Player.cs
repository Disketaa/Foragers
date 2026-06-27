using Microsoft.Xna.Framework;

namespace Foragers_Project.Core;

public sealed class AnimationPlayer
{
    private readonly SpriteSheet _sheet;
    private string _current = string.Empty;
    private int _frame;
    private float _timer;
    private bool _done;

    public string Current => _current;
    public int Frame => _frame;
    public bool Done => _done;

    public AnimationPlayer(SpriteSheet sheet)
    {
        _sheet = sheet;
        _done = true;
    }

    public void Play(string name)
    {
        if (_current == name && !_done)
            return;

        if (!_sheet.Has(name))
            return;

        _current = name;
        _frame = 0;
        _timer = 0f;
        _done = false;
    }

    public void Stop()
    {
        _frame = 0;
        _timer = 0f;
        _done = true;
    }

    public void Update(GameTime gameTime)
    {
        if (_done || string.IsNullOrEmpty(_current))
            return;

        AnimationDef def = _sheet.GetDef(_current);
        float delay = 1f / def.Fps;

        _timer += (float)gameTime.ElapsedGameTime.TotalSeconds;

        while (_timer >= delay)
        {
            _timer -= delay;
            _frame++;

            if (_frame >= def.Frames)
            {
                if (def.Loop)
                {
                    _frame = 0;
                }
                else
                {
                    _frame = def.Frames - 1;
                    _done = true;
                }
            }
        }
    }

    public Rectangle SourceRect()
    {
        return _sheet.GetFrames(_current)[_frame];
    }
}
