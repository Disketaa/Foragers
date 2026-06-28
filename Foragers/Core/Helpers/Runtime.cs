namespace Foragers.Core.Helpers;

public static class Runtime
{
    public static event Action<string>? FileReloaded
    {
        add => JsonManager.FileReloaded += value;
        remove => JsonManager.FileReloaded -= value;
    }

    public static void RegisterJson(string relativePath)
    {
        JsonManager.Register(relativePath);
    }

    public static void RegisterJsonByPath(string fullPath)
    {
        JsonManager.RegisterByPath(fullPath);
    }

    public static void Update()
    {
        JsonManager.Update();
    }

    public static T Get<T>(string relativePath, string key, T defaultValue = default!)
    {
        return JsonManager.Get<T>(relativePath, key, defaultValue);
    }

    public static bool GetBool(string relativePath, string key, bool defaultValue = false)
    {
        return JsonManager.GetBool(relativePath, key, defaultValue);
    }

    public static float GetFloat(string relativePath, string key, float defaultValue = 0f)
    {
        return JsonManager.GetFloat(relativePath, key, defaultValue);
    }

    public static int GetInt(string relativePath, string key, int defaultValue = 0)
    {
        return JsonManager.GetInt(relativePath, key, defaultValue);
    }

    public static string GetString(string relativePath, string key, string defaultValue = "")
    {
        return JsonManager.GetString(relativePath, key, defaultValue);
    }

    public static void Set(string relativePath, string key, object value)
    {
        JsonManager.Set(relativePath, key, value);
    }

    public static Dictionary<string, object>? GetData(string relativePath)
    {
        return JsonManager.GetData(relativePath);
    }
}
