# ============================================================================
# ПОЛНАЯ НАСТРОЙКА БЫСТРОГО ДОСТУПА
# ============================================================================

Write-Host "`n=== ШАГ 1: Установка иконки для папки пользователя ===" -ForegroundColor Cyan

# 1.1 Путь к папке пользователя
$userFolderPath = "$env:USERPROFILE"
$userIniPath = Join-Path $userFolderPath "desktop.ini"

# 1.2 Содержимое desktop.ini
$userIniContent = @"
[.ShellClassInfo]
IconFile=%SystemRoot%\System32\shell32.dll
IconIndex=158
ConfirmFileOp=0
"@

# 1.3 Снимаем защиту с файла, если он уже есть
if (Test-Path $userIniPath) {
    Set-ItemProperty -Path $userIniPath -Name Attributes -Value "Normal"
}

# 1.4 Записываем настройки в кодировке Unicode
Out-File -FilePath $userIniPath -InputObject $userIniContent -Encoding Unicode -Force

# 1.5 Прячем файл
Set-ItemProperty -Path $userIniPath -Name Attributes -Value "Hidden,System"

# 1.6 Активируем чтение иконки через атрибут папки
Set-ItemProperty -Path $userFolderPath -Name Attributes -Value "ReadOnly"

Write-Host "Иконка пользователя установлена." -ForegroundColor Green


Write-Host "`n=== ШАГ 2: Создание папки TORRENTS и установка иконки ===" -ForegroundColor Cyan

# 2.1 Определяем пути
$torrentsPath = Join-Path $env:USERPROFILE "TORRENTS"
$tempPath = Join-Path $torrentsPath "temp"
$qbExe = "C:\Program Files\qBittorrent\qbittorrent.exe"
$torrentsIniPath = Join-Path $torrentsPath "desktop.ini"

# 2.2 Создаем папку TORRENTS, если её нет
if (!(Test-Path $torrentsPath)) { 
    New-Item -ItemType Directory -Path $torrentsPath -Force | Out-Null 
    Write-Host "Папка TORRENTS создана." -ForegroundColor Green
}

# 2.3 Создаем скрытую папку temp внутри TORRENTS
if (!(Test-Path $tempPath)) {
    New-Item -ItemType Directory -Path $tempPath -Force | Out-Null
    Set-ItemProperty -Path $tempPath -Name Attributes -Value "Hidden"
    Write-Host "Скрытая папка temp создана." -ForegroundColor Green
}

# 2.4 Подготовка desktop.ini для TORRENTS
$torrentsIniContent = @"
[.ShellClassInfo]
IconResource=$qbExe,0
"@

# 2.5 Запись
if (Test-Path $torrentsIniPath) {
    Set-ItemProperty -Path $torrentsIniPath -Name Attributes -Value "Normal"
}

# 2.6 Записываем строго в Unicode
Out-File -FilePath $torrentsIniPath -InputObject $torrentsIniContent -Encoding Unicode -Force

# 2.7 Установка атрибутов
Set-ItemProperty -Path $torrentsIniPath -Name Attributes -Value "Hidden,System"
Set-ItemProperty -Path $torrentsPath -Name Attributes -Value "ReadOnly"

Write-Host "Иконка qBittorrent установлена для папки TORRENTS." -ForegroundColor Green


Write-Host "`n=== ШАГ 3: Обновление иконок ===" -ForegroundColor Cyan

# 3.1 Регистрируем класс для работы с Shell API
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class IconRefresh {
    [DllImport("shell32.dll", CharSet = CharSet.Auto)]
    public static extern void SHChangeNotify(uint wEventId, uint uFlags, IntPtr dwItem1, IntPtr dwItem2);
}
"@

# 3.2 Множественные вызовы для обновления
$userFolderPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($userFolderPath)
$torrentsPtr = [System.Runtime.InteropServices.Marshal]::StringToHGlobalUni($torrentsPath)

# SHCNE_ASSOCCHANGED
[IconRefresh]::SHChangeNotify(0x08000000, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)
Start-Sleep -Milliseconds 100

# SHCNE_UPDATEDIR - user folder
[IconRefresh]::SHChangeNotify(0x00001000, 0x0005, $userFolderPtr, [IntPtr]::Zero)
Start-Sleep -Milliseconds 100

# SHCNE_UPDATEDIR - TORRENTS
[IconRefresh]::SHChangeNotify(0x00001000, 0x0005, $torrentsPtr, [IntPtr]::Zero)
Start-Sleep -Milliseconds 100

# SHCNE_UPDATEITEM - user folder
[IconRefresh]::SHChangeNotify(0x00002000, 0x0005, $userFolderPtr, [IntPtr]::Zero)
Start-Sleep -Milliseconds 100

# SHCNE_UPDATEITEM - TORRENTS
[IconRefresh]::SHChangeNotify(0x00002000, 0x0005, $torrentsPtr, [IntPtr]::Zero)
Start-Sleep -Milliseconds 100

# SHCNE_ALLEVENTS
[IconRefresh]::SHChangeNotify(0x7FFFFFFF, 0x1000, [IntPtr]::Zero, [IntPtr]::Zero)

# Освобождаем память
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($userFolderPtr)
[System.Runtime.InteropServices.Marshal]::FreeHGlobal($torrentsPtr)

Write-Host "Отправлены сигналы обновления иконок." -ForegroundColor Green

# 3.3 Перезапуск explorer
Write-Host "Перезапуск Explorer..." -ForegroundColor Yellow
Start-Sleep -Milliseconds 300
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
Start-Sleep -Milliseconds 500

# 3.4 Дополнительное обновление через COM
Start-Sleep -Seconds 2
try {
    $shell = New-Object -ComObject Shell.Application
    $shell.Windows() | ForEach-Object { $_.Refresh() }
    Write-Host "Explorer обновлен." -ForegroundColor Green
} catch {
    # Explorer еще не запустился
}


Write-Host "`n=== ШАГ 4: Открепление стандартных папок ===" -ForegroundColor Cyan

$foldersToUnpin = @("Рабочий стол", "Документы", "Загрузки", "Изображения", "Музыка", "Видео")

$quickAccess = New-Object -ComObject Shell.Application
$recentFiles = $quickAccess.Namespace("shell:::{679f85cb-0220-4080-b29b-5540cc05aab6}").Items()

foreach ($folder in $foldersToUnpin) {
    $item = $recentFiles | Where-Object { $_.Name -eq $folder }

    if ($item) {
        $item.InvokeVerb("unpinfromhome")
        Write-Host "Папка '$folder' откреплена." -ForegroundColor Green
    } else {
        Write-Host "Папка '$folder' не найдена." -ForegroundColor Yellow
    }
}


Write-Host "`n=== ШАГ 5: Закрепление папок в нужном порядке ===" -ForegroundColor Cyan

$Shell = New-Object -ComObject Shell.Application

$P_User = $env:USERPROFILE
$P_Desk = Join-Path $env:USERPROFILE "Desktop"
$P_Down = Join-Path $env:USERPROFILE "Downloads"
$P_Torr = Join-Path $env:USERPROFILE "TORRENTS"
$P_Docu = Join-Path $env:USERPROFILE "Documents"
$P_Pict = Join-Path $env:USERPROFILE "Pictures"

Start-Sleep -Milliseconds 500

$PathsToPin = @($P_User, $P_Desk, $P_Down, $P_Torr, $P_Docu, $P_Pict)

foreach ($Path in $PathsToPin) {
    $Folder = $Shell.Namespace($Path)
    if ($Folder) {
        $Folder.Self.InvokeVerb("pintohome")
        Write-Host "Закреплена: $Path" -ForegroundColor Green
        Start-Sleep -Milliseconds 300 
    }
}

Write-Host "`n=== ЗАВЕРШЕНО! Quick Access настроен! ===" -ForegroundColor Green