using System.Text.Json;

namespace Foragers_Project.Core.Helpers;

public static class Runtime
{
    private static Dictionary<string, object>? _data;

    private static readonly JsonSerializerOptions JsonOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = true,
    };

    public static void Load(string jsonPath)
    {
        if (!File.Exists(jsonPath))
        {
            return;
        }

        try
        {
            string json = File.ReadAllText(jsonPath);
            _data = JsonSerializer.Deserialize<Dictionary<string, object>>(json, JsonOptions);
        }
        catch (Exception ex)
        {
            System.Diagnostics.Debug.WriteLine(
                $"[Runtime] Failed to load {jsonPath}: {ex.Message}"
            );
        }
    }

    public static T Get<T>(string key, T defaultValue = default!)
    {
        if (_data != null && _data.TryGetValue(key, out object? value))
        {
            try
            {
                if (value is JsonElement element)
                {
                    return element.Deserialize<T>(JsonOptions) ?? defaultValue;
                }

                if (value is T typed)
                {
                    return typed;
                }
            }
            catch
            {
                return defaultValue;
            }
        }
        return defaultValue;
    }
}
