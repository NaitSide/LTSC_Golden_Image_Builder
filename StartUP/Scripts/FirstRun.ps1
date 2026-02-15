# FirstRun.ps1

# === PotPlayer ===
$pot = "$env:APPDATA\PotPlayerMini64\PotPlayerMini64.ini"
if (Test-Path $pot) {
    $content = [IO.File]::ReadAllText($pot, [Text.Encoding]::UTF8)
    $content = $content -replace 'Администратор', $env:USERNAME
    [IO.File]::WriteAllText($pot, $content, [Text.Encoding]::UTF8)
}

# === qBittorrent INI ===
$qb = "$env:APPDATA\qBittorrent\qBittorrent.ini"
if (Test-Path $qb) {
    $content = [IO.File]::ReadAllText($qb, [Text.Encoding]::UTF8)
    $content = $content -replace 'Администратор', $env:USERNAME
    [IO.File]::WriteAllText($qb, $content, [Text.Encoding]::UTF8)
}

# === qBittorrent watched_folders.json ===
$watchedJson = "$env:APPDATA\qBittorrent\watched_folders.json"
if (Test-Path $watchedJson) {
    $content = [IO.File]::ReadAllText($watchedJson, [Text.Encoding]::UTF8)
    $content = $content -replace 'Администратор', $env:USERNAME
    [IO.File]::WriteAllText($watchedJson, $content, [Text.Encoding]::UTF8)
}

# === Запуск SetupQuickAccess.ps1 ===
& "C:\Windows\Setup\Scripts\SetupQuickAccess.ps1"

# === Удаление только VBS ===
Remove-Item "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup\FirstRun.vbs" -Force -ErrorAction SilentlyContinue