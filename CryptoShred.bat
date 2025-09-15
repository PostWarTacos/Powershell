@echo off
setlocal ENABLEDELAYEDEXPANSION

REM === CONFIGURATION ===
set VERACRYPT_PATH=%~dp0VeraCrypt.exe
set KEYFILE=%TEMP%\vc_keyfile.bin
set PASSWORD_FILE=%TEMP%\vc_password.txt

REM === LIST DRIVES ===
echo Available drives:
wmic logicaldisk get name,description | findstr ":"
echo.
set /p DRIVE="Enter the drive letter to encrypt (e.g., D:): "

REM === CONFIRMATION ===
echo WARNING: This will DESTROY ALL DATA on %DRIVE%!
set /p CONFIRM="Type YES to continue: "
if /I not "%CONFIRM%"=="YES" goto :EOF

REM === GENERATE RANDOM PASSWORD ===
setlocal
set "RANDOM_PASS="
for /L %%A in (1,1,32) do set /a "R=!random! %% 62" & call set "RANDOM_PASS=!RANDOM_PASS!!R!"
echo !RANDOM_PASS! > "%PASSWORD_FILE%"
endlocal & set /p VC_PASSWORD=<"%PASSWORD_FILE%"

REM === CREATE RANDOM KEYFILE ===
%VERACRYPT_PATH% /CreateKeyfile "%KEYFILE%" /RandomSource Random

REM === ENCRYPT ENTIRE DRIVE ===
echo Encrypting entire drive %DRIVE% ...
REM /volume %DRIVE%: targets the whole partition
REM /format formats and encrypts the entire partition
REM /password and /keyfiles set the credentials
REM /encryption AES /hash SHA-512 /filesystem NTFS /silent as before
%VERACRYPT_PATH% /volume %DRIVE% /format /password "%VC_PASSWORD%" /keyfiles "%KEYFILE%" /encryption AES /hash SHA-512 /filesystem NTFS /silent
if errorlevel 1 (
    echo VeraCrypt failed to encrypt the drive. Aborting.
    goto :CLEANUP
)

REM === DELETE KEYFILE AND PASSWORD ===
del /f /q "%KEYFILE%"
del /f /q "%PASSWORD_FILE%"

REM === SHRED COMPLETE ===
echo Crypto-shredding complete. Data is now unrecoverable.
pause

:CLEANUP
endlocal
