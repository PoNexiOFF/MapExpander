@echo off
setlocal enabledelayedexpansion

set "configFile=config.txt"

for /f "tokens=1,* delims==" %%a in (%configFile%) do (
    set "key=%%a"
    set "value=%%b"
    
    if "!key!"=="directory" set "directory=!value!"
)

if exist "%directory%" (
    echo The directory exists.
) else (
    color 04
    echo The directory does not exist. Please modify the directory you entered in config.txt by following the README instructions.
    color
    pause >nul
    exit
)

echo Saves Directory : "%directory%"

set /a index=0

set "tempFile=%temp%\dossier_list.txt"
del "%tempFile%" 2>nul

for /d %%D in ("%directory%\*") do (
    set /a index+=1
    echo !index! %%~nD >> "%tempFile%"
)

echo List of saves :
for /f "tokens=1* delims= " %%A in (%tempFile%) do (
    set "line=(%%A) %%B"
    echo !line!
)

set /p "choice=Enter the index number of the folder you wish to select (without brackets) : "

set "selectedFolder="
for /f "tokens=1* delims= " %%A in ('findstr /b "%choice% " "%tempFile%"') do set "selectedFolder=%%B"

:RemoveTrailingSpaces
if "%selectedFolder:~-1%"==" " set "selectedFolder=%selectedFolder:~0,-1%" & goto :RemoveTrailingSpaces

set "chosenDir=%directory%\%selectedFolder%"
set "jsonFile=%chosenDir%\GameData.json"

if defined selectedFolder (
    if exist "%chosenDir%" (
        echo Directory : "%jsonFile%"
        if exist "%jsonFile%" (
            echo GameData.json file found.
        ) else (
            color 04
            echo GameData.json file not found in specified path.
            color
            del "%tempFile%"
            endlocal
            pause >nul
            exit
        )
    ) else (
        color 04
        echo Folder not found in specified path.
        color
        del "%tempFile%"
        endlocal
        pause >nul
        exit
    )
) else (
    color 04
    echo Invalid index number or folder not found.
    color
    del "%tempFile%"
    endlocal
    pause >nul
    exit
)

powershell -Command "Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.MessageBox]::Show('You are about to change the size of your backup map. This can lead to significant performance losses or crashes/bugs. We have determined that 1998 is the maximum size in x and y for constant bugs.', 'Warning', 'OK', [System.Windows.Forms.MessageBoxIcon]::Warning, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::ServiceNotification)"

set /p "new_x=Enter the new value for x (must be over 1050) : "
if %new_x% gtr 1998 (
    color 04
    echo Please enter a value less than 1998.
    color
    del "%tempFile%"
    endlocal
    pause >nul
    exit
) else if %new_x% lss 1050 (
    color 04
    echo Please enter a value greater than 1050.
    color
    del "%tempFile%"
    endlocal
    pause >nul
    exit
) else (
    goto yValueCheck
)

:yValueCheck
set /p "new_y=Enter the new value for y (must be over 700) : "
if %new_y% gtr 1998 (
    color 04
    echo Please enter a value less than 1998.
    color
    del "%tempFile%"
    endlocal
    pause >nul
    exit
) else if %new_y% lss 700 (
    color 04
    echo Please enter a value greater than 700.
    color
    del "%tempFile%"
    endlocal
    pause >nul
    exit
) else (
    goto modifyFile
)

:modifyFile
powershell -Command ^
    "$jsonFile = '%jsonFile%';" ^
    "$jsonFile = $jsonFile -replace '\\', '\\\\';" ^
    "$json = Get-Content -Path $jsonFile -Raw | ConvertFrom-Json;" ^
    "$json.airportData.worldSize.x = %new_x%;" ^
    "$json.airportData.worldSize.y = %new_y%;" ^
    "$json | ConvertTo-Json -Compress | Set-Content -Path $jsonFile;"

color 2
echo Modifications carried out successfully.
color

del "%tempFile%"
endlocal
pause
