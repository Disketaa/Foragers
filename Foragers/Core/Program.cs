using Foragers.Core;
using Foragers.Core.Helpers;

try
{
    using var game = new GameRoot();
    game.Run();
}
catch (Exception ex)
{
    ErrorHandler.ShowError("Foragers - Критическая ошибка", ex);
}
