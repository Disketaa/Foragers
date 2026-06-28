using System.IO;
using System.Text.Json;
using System.Threading;

namespace Foragers_Project.Core.Helpers;

public static class JsonManager
{
    private static readonly Dictionary<string, JsonFileData> _files = new();
    private static readonly Dictionary<string, string> _outputToSource = new();
    private static readonly Dictionary<string, string> _sourceToOutput = new();
    private static readonly List<FileSystemWatcher> _watchers = new();
    private static readonly HashSet<string> _watchedDirectories = new();
    private static readonly HashSet<string> _savingPaths = new();

    private static readonly JsonSerializerOptions _readOptions = new()
    {
        PropertyNameCaseInsensitive = true,
    };

    private static readonly JsonSerializerOptions _writeOptions = new()
    {
        PropertyNameCaseInsensitive = true,
        WriteIndented = true,
    };

    public static event Action<string>? FileReloaded;

    private static string ResolvePath(string path)
    {
        if (Path.IsPathRooted(path))
        {
            return Path.GetFullPath(path);
        }

        return Path.GetFullPath(
            Path.Combine(AppDomain.CurrentDomain.BaseDirectory, "Content", "Data", path)
        );
    }

    public static void RegisterByPath(string fullPath)
    {
        fullPath = Path.GetFullPath(fullPath);

        if (_files.ContainsKey(fullPath))
        {
            return;
        }

        EnsureWatcherFor(fullPath);

        var fileData = new JsonFileData(fullPath);
        _files[fullPath] = fileData;
        fileData.Reload();
    }

    public static void Register(string relativePath)
    {
        string fullPath = ResolvePath(relativePath);
        RegisterByPath(fullPath);

        string? sourcePath = FindSourcePath(relativePath);
        if (!string.IsNullOrEmpty(sourcePath) && sourcePath != fullPath)
        {
            EnsureWatcherFor(sourcePath);
            _outputToSource[fullPath] = sourcePath;
            _sourceToOutput[sourcePath] = fullPath;
        }
    }

    private static string? FindSourcePath(string relativePath)
    {
        string baseDir = AppDomain.CurrentDomain.BaseDirectory;

        string[] possibleRoots = new[]
        {
            Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..", "..")),
            Path.GetFullPath(Path.Combine(baseDir, "..", "..", "..")),
            Path.GetFullPath(Path.Combine(baseDir, "..", "..")),
        };

        foreach (string root in possibleRoots)
        {
            string sourcePath = Path.Combine(root, "Content", "Data", relativePath);
            if (File.Exists(sourcePath))
            {
                return Path.GetFullPath(sourcePath);
            }
        }

        return null;
    }

    private static void EnsureWatcherFor(string filePath)
    {
        string? directory = Path.GetDirectoryName(filePath);
        if (string.IsNullOrEmpty(directory) || !Directory.Exists(directory))
        {
            return;
        }

        if (!_watchedDirectories.Add(directory))
        {
            return;
        }

        var watcher = new FileSystemWatcher(directory)
        {
            NotifyFilter = NotifyFilters.LastWrite | NotifyFilters.FileName,
            Filter = "*.json",
            IncludeSubdirectories = false,
            EnableRaisingEvents = true,
        };

        watcher.Changed += OnFileChanged;
        watcher.Renamed += OnFileRenamed;
        watcher.Deleted += OnFileDeleted;

        _watchers.Add(watcher);
    }

    private static void OnFileChanged(object sender, FileSystemEventArgs e)
    {
        string fullPath = Path.GetFullPath(e.FullPath);

        if (_savingPaths.Contains(fullPath))
        {
            return;
        }

        if (_files.TryGetValue(fullPath, out JsonFileData? data))
        {
            data.NeedsReload = true;
        }

        if (_sourceToOutput.TryGetValue(fullPath, out string? outputPath))
        {
            try
            {
                File.Copy(fullPath, outputPath, overwrite: true);
            }
            catch { }

            if (_files.TryGetValue(outputPath, out JsonFileData? outputData))
            {
                outputData.NeedsReload = true;
            }
        }
    }

    private static void OnFileRenamed(object sender, RenamedEventArgs e)
    {
        string oldFullPath = Path.GetFullPath(e.OldFullPath);
        string newFullPath = Path.GetFullPath(e.FullPath);
        if (_files.TryGetValue(oldFullPath, out JsonFileData? data))
        {
            _files.Remove(oldFullPath);
            _files[newFullPath] = data;
            data.FilePath = newFullPath;
            data.NeedsReload = true;
        }
    }

    private static void OnFileDeleted(object sender, FileSystemEventArgs e)
    {
        string fullPath = Path.GetFullPath(e.FullPath);
        if (_files.TryGetValue(fullPath, out JsonFileData? data))
        {
            data.IsDeleted = true;
        }
    }

    public static void Update()
    {
        foreach (KeyValuePair<string, JsonFileData> pair in _files)
        {
            JsonFileData data = pair.Value;

            if (data.NeedsReload)
            {
                data.Reload();
            }
            else if (data.IsDeleted && File.Exists(data.FilePath))
            {
                data.Reload();
            }
        }
    }

    public static T Get<T>(string path, string key, T defaultValue = default!)
    {
        string fullPath = ResolvePath(path);

        if (_files.TryGetValue(fullPath, out JsonFileData? data) && data.Data != null)
        {
            if (data.Data.TryGetValue(key, out object? value) && value is JsonElement element)
            {
                try
                {
                    return element.Deserialize<T>(_readOptions) ?? defaultValue;
                }
                catch
                {
                    return defaultValue;
                }
            }
        }

        return defaultValue;
    }

    public static bool GetBool(string path, string key, bool defaultValue = false)
    {
        return Get<bool>(path, key, defaultValue);
    }

    public static float GetFloat(string path, string key, float defaultValue = 0f)
    {
        return Get<float>(path, key, defaultValue);
    }

    public static int GetInt(string path, string key, int defaultValue = 0)
    {
        return Get<int>(path, key, defaultValue);
    }

    public static string GetString(string path, string key, string defaultValue = "")
    {
        return Get<string>(path, key, defaultValue);
    }

    public static Dictionary<string, object>? GetData(string path)
    {
        string fullPath = ResolvePath(path);

        if (_files.TryGetValue(fullPath, out JsonFileData? data))
        {
            return data.Data;
        }

        return null;
    }

    public static void Set(string path, string key, object value)
    {
        string fullPath = ResolvePath(path);

        if (_files.TryGetValue(fullPath, out JsonFileData? data) && data.Data != null)
        {
            data.Data[key] = JsonSerializer.SerializeToElement(value, _readOptions);
            data.Save();
        }
    }

    private sealed class JsonFileData
    {
        public string FilePath;
        public Dictionary<string, object>? Data;
        public bool NeedsReload;
        public bool IsDeleted;

        public JsonFileData(string filePath)
        {
            FilePath = filePath;
        }

        public void Reload()
        {
            if (!File.Exists(FilePath))
            {
                IsDeleted = true;
                return;
            }

            for (int attempt = 0; attempt < 3; attempt++)
            {
                try
                {
                    string json = File.ReadAllText(FilePath);
                    Data = JsonSerializer.Deserialize<Dictionary<string, object>>(
                        json,
                        _readOptions
                    );
                    NeedsReload = false;
                    IsDeleted = false;
                    FileReloaded?.Invoke(FilePath);
                    return;
                }
                catch (IOException)
                {
                    Thread.Sleep(50);
                }
                catch (Exception ex)
                {
                    System.Diagnostics.Debug.WriteLine(
                        $"[JsonManager] Failed to load {FilePath}: {ex.Message}"
                    );
                    return;
                }
            }
        }

        public void Save()
        {
            if (Data == null)
            {
                return;
            }

            _savingPaths.Add(FilePath);

            try
            {
                string? directory = Path.GetDirectoryName(FilePath);
                if (!string.IsNullOrEmpty(directory) && !Directory.Exists(directory))
                {
                    Directory.CreateDirectory(directory);
                }

                string json = JsonSerializer.Serialize(Data, _writeOptions);
                json = ConvertSpacesToTabs(json);
                File.WriteAllText(FilePath, json);

                if (_outputToSource.TryGetValue(FilePath, out string? sourcePath))
                {
                    string? sourceDir = Path.GetDirectoryName(sourcePath);
                    if (!string.IsNullOrEmpty(sourceDir) && !Directory.Exists(sourceDir))
                    {
                        Directory.CreateDirectory(sourceDir);
                    }
                    File.WriteAllText(sourcePath, json);
                }
            }
            catch (Exception ex)
            {
                System.Diagnostics.Debug.WriteLine(
                    $"[JsonManager] Failed to save {FilePath}: {ex.Message}"
                );
            }
            finally
            {
                _savingPaths.Remove(FilePath);
            }
        }

        private static string ConvertSpacesToTabs(string json)
        {
            string[] lines = json.Split('\n');
            for (int i = 0; i < lines.Length; i++)
            {
                int spaces = 0;
                while (spaces < lines[i].Length && lines[i][spaces] == ' ')
                {
                    spaces++;
                }

                if (spaces > 0)
                {
                    int tabs = spaces / 2;
                    lines[i] = new string('\t', tabs) + lines[i][spaces..];
                }
            }

            return string.Join('\n', lines);
        }
    }
}
