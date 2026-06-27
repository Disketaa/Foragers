using Microsoft.Xna.Framework;

namespace Foragers_Project.Core.Helpers;

static class PixelRounding
{
    public static Vector2 RoundToPixel(Vector2 value)
    {
        return new Vector2((float)Math.Round(value.X), (float)Math.Round(value.Y));
    }

    public static void ApplyPixelRounding(ref Vector2 value)
    {
        value = RoundToPixel(value);
    }
}
