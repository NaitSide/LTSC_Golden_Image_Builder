# =========================================================
#    LTSC Golden Image Builder
#    Clean and Sysprep - Windows Image Preparation
#    NaitSide Custom Build
# =========================================================
#
#    [!] ВНИМАНИЕ: Запускать ТОЛЬКО в AUDIT MODE!
#
#    Этот скрипт подготавливает Windows 10 LTSC к Sysprep:
#
#    • Очистка временных файлов и кэша
#    • Удаление логов и истории
#    • Оптимизация образа перед запечатыванием
#    • Запуск Sysprep с OOBE для создания Golden Image
#
# =========================================================
#    GitHub: github.com/NaitSide/LTSC_Golden_Image_Builder
# =========================================================

# Установка кодировки UTF-8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "LTSC Golden Image Builder - Clean and Sysprep"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host "   [!]  ВНИМАНИЕ: Запускать ТОЛЬКО в AUDIT MODE!" -ForegroundColor Red
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Этот скрипт:" -ForegroundColor Cyan
Write-Host "   • Очистит временные файлы и кэш" -ForegroundColor Gray
Write-Host "   • Удалит логи и историю" -ForegroundColor Gray
Write-Host "   • Оптимизирует образ" -ForegroundColor Gray
Write-Host "   • Запустит Sysprep с OOBE" -ForegroundColor Gray
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Yellow
Write-Host ""
Read-Host "Нажмите Enter для продолжения"

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   LTSC Golden Image Builder" -ForegroundColor White
Write-Host "   Clean and Sysprep" -ForegroundColor Gray
Write-Host "   NaitSide Custom Build" -ForegroundColor Gray
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "   Начинаю очистку и подготовку системы..." -ForegroundColor Yellow
Write-Host ""
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# Путь к скрипту
$global:scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptDir

# Создание папки для XML файлов
$global:xmlFolder = Join-Path $scriptDir "xml_for_build"
if (-not (Test-Path $xmlFolder)) {
    New-Item -Path $xmlFolder -ItemType Directory -Force | Out-Null
}

# ============================================================================
# ФУНКЦИИ
# ============================================================================

function Show-Menu {
    Clear-Host
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "   ПОДГОТОВКА ПРОФИЛЯ ДЛЯ SYSPREP" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Выберите режим работы:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  [1] - Полная подготовка + Sysprep" -ForegroundColor Green
    Write-Host "        (очистка, настройка, генерация файлов, запуск Sysprep)"
    Write-Host ""
    Write-Host "  [2] - ТЕСТ: Только генерация FirstLogon.ps1 и unattend.xml" -ForegroundColor Yellow
    Write-Host "        (без очистки, без изменений системы)"
    Write-Host ""
    Write-Host "  [0] - Выход" -ForegroundColor Red
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

function Clear-BrowserCaches {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[1/9] Очистка кэша браузеров..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Chrome
    $chromeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
    $chromeCodeCachePath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache"
    if (Test-Path $chromeCachePath) {
        Remove-Item -Path $chromeCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $chromeCodeCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  [+] Chrome кеш удалён" -ForegroundColor Green
    }
    
    # Edge
    $edgeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"
    $edgeCodeCachePath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Code Cache"
    if (Test-Path $edgeCachePath) {
        Remove-Item -Path $edgeCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $edgeCodeCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  + Edge кеш удалён" -ForegroundColor Green
    }
    
    # Yandex
    $yandexCachePath = "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Cache"
    $yandexCodeCachePath = "$env:LOCALAPPDATA\Yandex\YandexBrowser\User Data\Default\Code Cache"
    if (Test-Path $yandexCachePath) {
        Remove-Item -Path $yandexCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path $yandexCodeCachePath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  + Yandex кеш удалён" -ForegroundColor Green
    }
}

function Clear-TempFiles {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[2/9] Очистка временных файлов..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Temp
    Remove-Item -Path "$env:LOCALAPPDATA\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] AppData\Local\Temp очищен" -ForegroundColor Green
    
    # INetCache
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\INetCache\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] INetCache очищен" -ForegroundColor Green
    
    # Recent
    Remove-Item -Path "$env:APPDATA\Microsoft\Windows\Recent\*" -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Recent очищен" -ForegroundColor Green
}

function Remove-LogsAndDumps {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[3/10] Удаление логов и дампов..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Логи
    Get-ChildItem -Path "$env:LOCALAPPDATA" -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Get-ChildItem -Path "$env:APPDATA" -Filter "*.log" -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Логи удалены" -ForegroundColor Green
    
    # Дампы
    $crashDumpsPath = "$env:LOCALAPPDATA\CrashDumps"
    if (Test-Path $crashDumpsPath) {
        Remove-Item -Path $crashDumpsPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  + Дампы удалены" -ForegroundColor Green
    }
    
    # Миниатюры
    Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
    Write-Host "  [+] Миниатюры удалены" -ForegroundColor Green
}

function Clear-SystemHistory {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[4/9] Очистка истории системы..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # История адресной строки Explorer
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\TypedPaths" /f 2>$null
    Write-Host "  [+] История Explorer удалена" -ForegroundColor Green
    
    # История Win+R
    reg delete "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU" /f 2>$null
    Write-Host "  [+] История Win+R удалена" -ForegroundColor Green
}

function Export-StartLayoutTiles {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[5/9] Настройка плиток (Меню Пуск и Панель задач)..." -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Путь к файлу макета в рабочей папке
    $sourceLayoutPath = Join-Path $global:xmlFolder "LayoutModification.xml"
    
    # Экспортируем макет в рабочую папку
    try {
        Export-StartLayout -Path $sourceLayoutPath
        Write-Host "[+] Макет плиток экспортирован в xml_for_build" -ForegroundColor Green
    } catch {
        Write-Host "[!] ОШИБКА при экспорте макета плиток!" -ForegroundColor Red
        return
    }
    
    # Проверяем что файл создался
    if (-not (Test-Path $sourceLayoutPath)) {
        Write-Host "[!] ОШИБКА: файл макета не найден после экспорта!" -ForegroundColor Red
        return
    }
    
    # Путь для Default профиля
    $defaultPath = "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell"
    New-Item -Path $defaultPath -ItemType Directory -Force | Out-Null
    
    # Путь для текущего пользователя
    $currentUserPath = "$env:LOCALAPPDATA\Microsoft\Windows\Shell"
    New-Item -Path $currentUserPath -ItemType Directory -Force | Out-Null
    
    # Копируем из xml_for_build в оба профиля
    try {
        Copy-Item -Path $sourceLayoutPath -Destination "$defaultPath\LayoutModification.xml" -Force
        Copy-Item -Path $sourceLayoutPath -Destination "$currentUserPath\LayoutModification.xml" -Force
        Write-Host "[+] Макет плиток успешно применён к профилям" -ForegroundColor Green
    } catch {
        Write-Host "[!] ОШИБКА при копировании макета в профили!" -ForegroundColor Red
    }
}

function Hide-TaskbarSearch {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[6/9] Скрытие лупы на панели задач..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    # Загружаем куст профиля по умолчанию
    reg load HKLM\DefUser "C:\Users\Default\NTUSER.DAT" 2>$null
    
    # Настройка Поиска (0 - скрыт, 1 - значок лупы, 2 - поле поиска)
    reg add "HKLM\DefUser\Software\Microsoft\Windows\CurrentVersion\Search" /v "SearchboxTaskbarMode" /t REG_DWORD /d 0 /f 2>$null
    
    # Выгружаем куст
    reg unload HKLM\DefUser 2>$null
    
    Write-Host "  [+] Поиск на панели задач скрыт" -ForegroundColor Green
}

function Setup-Avatar {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[7/9] Настройка аватара..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $avatarSource = Join-Path $scriptDir "Pictures_profile\user.png"
    $avatarDest = "C:\ProgramData\Microsoft\User Account Pictures"
    
    if (Test-Path $avatarSource) {
        # Копируем под все размеры
        foreach ($size in @(32, 40, 48, 192, 448)) {
            Copy-Item -Path $avatarSource -Destination "$avatarDest\user-$size.png" -Force
        }
        Copy-Item -Path $avatarSource -Destination "$avatarDest\user.png" -Force
        
        # Применяем политику
        reg add "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "UseDefaultTile" /t REG_DWORD /d 1 /f 2>$null
        
        Write-Host "  [+] Аватар заменен" -ForegroundColor Green
    } else {
        Write-Host "  ! ОШИБКА: Файл user.png не найден!" -ForegroundColor Red
    }
}

function Generate-FirstLogonScript {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[8/9] Создание FirstLogon.ps1..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $firstLogonPath = Join-Path $xmlFolder "FirstLogon.ps1"
    
    # Удаляем старый файл если есть
    if (Test-Path $firstLogonPath) {
        Remove-Item -Path $firstLogonPath -Force
    }
    
    # Создаём скрипт используя here-string
    $scriptContent = @'
# Скрипт первого входа
# Выполняется автоматически при первом логине нового пользователя

# Запуск логирования
#Start-Transcript не работает вместе с -WindowStyle Hidden 
#Start-Transcript -Path "C:\Windows\Temp\FirstLogon.log" -Append

Write-Host "=== FirstLogon Script Started ===" -ForegroundColor Green
Write-Host "User: $env:USERNAME" -ForegroundColor Cyan
Write-Host "Computer: $env:COMPUTERNAME" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)" -ForegroundColor Cyan

# Ждём полной загрузки профиля
Start-Sleep -Seconds 5

# ===== ПЕРЕИМЕНОВАНИЕ КОМПЬЮТЕРА =====
Write-Host "`n=== Переименование компьютера ===" -ForegroundColor Cyan

try {
    $newName = "$env:USERNAME-PC"
    $currentName = $env:COMPUTERNAME

    Write-Host "Текущее имя: $currentName" -ForegroundColor Cyan
    Write-Host "Новое имя: $newName" -ForegroundColor Cyan

    if ($currentName -ne $newName) {
        Rename-Computer -NewName $newName -Force -ErrorAction Stop
        Write-Host "Переименовано успешно!" -ForegroundColor Green
        Write-Host "ТРЕБУЕТСЯ ПЕРЕЗАГРУЗКА" -ForegroundColor Yellow
    } else {
        Write-Host "Имя уже правильное" -ForegroundColor Green
    }
} catch {
    Write-Host "Ошибка переименования: $_" -ForegroundColor Red
}

# ===== ОЧИСТКА =====
Write-Host "`n=== Завершение ===" -ForegroundColor Yellow

Start-Sleep -Seconds 2

try {
    Remove-Item -Path $PSCommandPath -Force -ErrorAction Stop
    Write-Host "Скрипт удален" -ForegroundColor Green
} catch {
    Write-Host "Не удалось удалить: $_" -ForegroundColor Red
}

Write-Host "=== FirstLogon Script Completed ===" -ForegroundColor Green
#Stop-Transcript
'@

    # Сохраняем скрипт в UTF-8 with BOM
    $utf8BOM = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($firstLogonPath, $scriptContent, $utf8BOM)
    
    Write-Host "  [+] FirstLogon.ps1 создан" -ForegroundColor Green
}

function Generate-UnattendXml {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "[9/9] Создание unattend.xml..." -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $unattendPath = Join-Path $xmlFolder "unattend.xml"
    
    $xmlContent = @'
<?xml version="1.0" encoding="utf-8"?>
<unattend xmlns="urn:schemas-microsoft-com:unattend">
    <settings pass="specialize">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <CopyProfile>true</CopyProfile>
        </component>
    </settings>
    <settings pass="oobeSystem">
        <component name="Microsoft-Windows-Shell-Setup" processorArchitecture="amd64" publicKeyToken="31bf3856ad364e35" language="neutral" versionScope="nonSxS">
            <FirstLogonCommands>
                <SynchronousCommand>
                    <Order>1</Order>
                    <CommandLine>powershell.exe -ExecutionPolicy Bypass -NoProfile -WindowStyle Hidden -File C:\Windows\Setup\Scripts\FirstLogon.ps1</CommandLine>
                    <Description>First Logon Setup Script with Logging</Description>
                </SynchronousCommand>
            </FirstLogonCommands>
        </component>
    </settings>
</unattend>
'@

    $xmlContent | Out-File -FilePath $unattendPath -Encoding utf8 -Force
    
    Write-Host "  [+] unattend.xml создан" -ForegroundColor Green
}

function Test-Prerequisites {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host "ПРОВЕРКА ПЕРЕД SYSPREP" -ForegroundColor Cyan
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
    
    $allOk = $true
    
    # Проверка LayoutModification.xml
    if (Test-Path "C:\Users\Default\AppData\Local\Microsoft\Windows\Shell\LayoutModification.xml") {
        Write-Host "  [+]  LayoutModification.xml в Default User" -ForegroundColor Green
    } else {
        Write-Host "  [!]  LayoutModification.xml НЕ НАЙДЕН" -ForegroundColor Red
        $allOk = $false
    }
    
    # Проверка аватара
    if (Test-Path "C:\ProgramData\Microsoft\User Account Pictures\user-448.png") {
        Write-Host "  [+]  user-448.png в ProgramData" -ForegroundColor Green
    } else {
        Write-Host "  [!]  user-448.png НЕ НАЙДЕН" -ForegroundColor Red
        $allOk = $false
    }
    
    # Проверка FirstLogon.ps1
    if (Test-Path (Join-Path $xmlFolder "FirstLogon.ps1")) {
        Write-Host "  [+]  FirstLogon.ps1 создан" -ForegroundColor Green
    } else {
        Write-Host "  [!]  FirstLogon.ps1 НЕ СОЗДАН" -ForegroundColor Red
        $allOk = $false
    }
    
    # Проверка unattend.xml
    if (Test-Path (Join-Path $xmlFolder "unattend.xml")) {
        Write-Host "  [+]  unattend.xml создан" -ForegroundColor Green
    } else {
        Write-Host "  [!]  unattend.xml НЕ СОЗДАН" -ForegroundColor Red
        $allOk = $false
    }
     
    Write-Host ""
    return $allOk
}

function Start-SysprepProcess {
    Write-Host ""
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host "ВНИМАНИЕ!" -ForegroundColor Yellow
    Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Следующий шаг запустит Sysprep!" -ForegroundColor Yellow
    Write-Host "После выполнения компьютер ВЫКЛЮЧИТСЯ!" -ForegroundColor Red
    Write-Host ""
    
    $confirm = Read-Host "Продолжить? (Yes/No)"
    
    if ($confirm -in @("y", "yes", "Y", "Yes", "YES")) {
        Write-Host ""
        Write-Host "Копирование FirstLogon.ps1 в C:\Windows\Setup\Scripts\..." -ForegroundColor Cyan
        
        # Создание папки Scripts
        $scriptsPath = "C:\Windows\Setup\Scripts"
        if (-not (Test-Path $scriptsPath)) {
            New-Item -Path $scriptsPath -ItemType Directory -Force | Out-Null
        }
        
        # Копирование скрипта
        $sourcePath = Join-Path $xmlFolder "FirstLogon.ps1"
        $destPath = Join-Path $scriptsPath "FirstLogon.ps1"
        
        if (Test-Path $sourcePath) {
            Copy-Item -Path $sourcePath -Destination $destPath -Force
            Write-Host "  + FirstLogon.ps1 скопирован" -ForegroundColor Green
        } else {
            Write-Host "  ! FirstLogon.ps1 не найден!" -ForegroundColor Red
            pause
            return
        }
        
        Write-Host ""
        Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host "ЗАПУСК SYSPREP" -ForegroundColor Cyan
        Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Система будет подготовлена к созданию образа..." -ForegroundColor Yellow
        Write-Host "После нажатия Enter, это окно закроется и через несеолько секунд откроется окно SysPrep" -ForegroundColor Yellow
        Write-Host "Компьютер автоматически выключится через несколько минут." -ForegroundColor Yellow
        Write-Host ""
        pause
        
        # Запуск Sysprep
        $unattendPath = Join-Path $xmlFolder "unattend.xml"
        & "C:\Windows\System32\Sysprep\sysprep.exe" /generalize /oobe /shutdown /unattend:"$unattendPath"
    } else {
        Write-Host ""
        Write-Host "Отменено." -ForegroundColor Yellow
        Write-Host "Вы можете запустить Sysprep позже вручную." -ForegroundColor Yellow
    }
}

# ============================================================================
# ОСНОВНАЯ ЛОГИКА
# ============================================================================

# Главный цикл меню
do {
    Show-Menu
    $choice = Read-Host "Выберите опцию"
    
    switch ($choice) {
        "1" {
            # Полная подготовка
            Clear-Host
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host "РЕЖИМ: Полная подготовка + Sysprep" -ForegroundColor Green
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            
            Clear-BrowserCaches
            Clear-TempFiles
            Remove-LogsAndDumps
            Clear-SystemHistory
            Export-StartLayoutTiles
            Hide-TaskbarSearch
            Setup-Avatar
            Generate-FirstLogonScript
            Generate-UnattendXml
            
            Write-Host ""
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host "[OK] ПОДГОТОВКА ЗАВЕРШЕНА!" -ForegroundColor Green
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host ""
            
            $allOk = Test-Prerequisites
            
            if (-not $allOk) {
                Write-Host ""
                Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Red
                Write-Host "⚠️  ВНИМАНИЕ! ОБНАРУЖЕНЫ ПРОБЛЕМЫ!" -ForegroundColor Red
                Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Red
                Write-Host ""
                Write-Host "Sysprep может не сработать корректно." -ForegroundColor Yellow
                Write-Host "Исправьте ошибки и запустите скрипт заново." -ForegroundColor Yellow
                Write-Host ""
                pause
                continue
            }
            
            Start-SysprepProcess
            break
        }
        "2" {
            # Тест: только генерация
            Clear-Host
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
            Write-Host "РЕЖИМ: ТЕСТ - Только генерация файлов" -ForegroundColor Yellow
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Yellow
            
            Generate-FirstLogonScript
            Generate-UnattendXml
            
            Write-Host ""
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host "ГОТОВО!" -ForegroundColor Green
            Write-Host "════════════════════════════════════════════════════════" -ForegroundColor Green
            Write-Host ""
            Write-Host "Файлы созданы в: $xmlFolder" -ForegroundColor Cyan
            Write-Host ""
            Write-Host "  1. FirstLogon.ps1" -ForegroundColor White
            Write-Host "  2. unattend.xml" -ForegroundColor White
            Write-Host ""
            Write-Host "Проверить синтаксис FirstLogon.ps1:" -ForegroundColor Yellow
            Write-Host "  powershell -File `"$xmlFolder\FirstLogon.ps1`" -WhatIf" -ForegroundColor Gray
            Write-Host ""
            pause
        }
        "0" {
            Write-Host ""
            Write-Host "Выход..." -ForegroundColor Yellow
            break
        }
        default {
            Write-Host ""
            Write-Host "Неверный выбор! Нажмите Enter..." -ForegroundColor Red
            pause
        }
    }
} while ($choice -ne "0" -and $choice -ne "1")