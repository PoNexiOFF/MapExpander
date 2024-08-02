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
        echo GameData.json Directory : "%jsonFile%"
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

powershell -Command ^
    "$jsonFile = '%jsonFile%';" ^
    "$jsonFile = $jsonFile -replace '\\', '\\\\';" ^
    "$json = Get-Content -Path $jsonFile -Raw | ConvertFrom-Json;" ^
    "$original_x = $json.airportData.worldSize.x;" ^
    "$original_y = $json.airportData.worldSize.y;" ^
    "$outputFile = '%temp%\original_values.txt';" ^
    "Add-Content -Path $outputFile -Value ('Original x: ' + $original_x);" ^
    "Add-Content -Path $outputFile -Value ('Original y: ' + $original_y);" ^
    "exit 0"

rem Lire les valeurs originales depuis le fichier temporaire
set "outputFile=%temp%\original_values.txt"

for /f "tokens=1,* delims=:" %%i in ('type "%outputFile%"') do (
    if "%%i"=="Original x" set "original_x=%%j"
    if "%%i"=="Original y" set "original_y=%%j"
)

del "%outputFile%"

powershell -Command ^
    "Add-Type -AssemblyName System.Windows.Forms;" ^
    "[System.Windows.Forms.MessageBox]::Show('You are about to change the size of your backup map from X:%original_x% and Y:%original_y%. This can lead to significant performance losses or crashes/bugs. We have determined that 1998 is the maximum size in x and y to avoid constant bugs.', 'Warning', 'OK', [System.Windows.Forms.MessageBoxIcon]::Warning, [System.Windows.Forms.MessageBoxDefaultButton]::Button1, [System.Windows.Forms.MessageBoxOptions]::ServiceNotification)"

set /p "new_x=Enter the new value for x (current value:%original_x%) (must be over 1050) : "
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
set /p "new_y=Enter the new value for y (current value:%original_y%) (must be over 700) : "
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
echo Modifications carried out successfully. If you have already started the game, please switch it off so that the change can be taken into account.
color

rem Création du fichier pour le dll dans le dossier de la save

set meFile=%chosenDir%\MapExpanderData.txt
(
    echo value_x=%new_x%
    echo value_y=%new_y%
) > "%meFile%"

rem Création du fichier log (pas sûr de garder ça)

set scriptDir=%~dp0
set projectDir=%scriptDir%\..
set logsDir=%projectDir%\logs

if not exist "%logsDir%" mkdir "%logsDir%"

for /f "tokens=2 delims==" %%I in ('"wmic os get localdatetime /value"') do set ldt=%%I
set timestamp=%ldt:~0,4%-%ldt:~4,2%-%ldt:~6,2%_%ldt:~8,2%-%ldt:~10,2%-%ldt:~12,2%

set logFile=%logsDir%\log_%timestamp%.txt
(
    echo Modified Save Name : %selectedFolder%
    echo Old x value : %original_x% - new x value : %new_x%
    echo Old y value : %original_y% - new y value : %new_y%
) > "%logFile%"

del "%tempFile%"
endlocal
pause
