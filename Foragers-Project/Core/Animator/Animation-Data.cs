namespace Foragers_Project.Core;

public sealed class AnimationDef
{
    public string Name { get; set; } = string.Empty;
    public int Frames { get; set; }
    public int Fps { get; set; }
    public bool Loop { get; set; }
}

public sealed class AnimationData
{
    public string Sheet { get; set; } = string.Empty;
    public int FrameWidth { get; set; }
    public int FrameHeight { get; set; }
    public float PivotX { get; set; } = 0.5f;
    public float PivotY { get; set; } = 0.5f;
    public List<AnimationDef> Animations { get; set; } = [];
}
