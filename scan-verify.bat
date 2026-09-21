@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

REM ============================================================
REM  Nessus 11714 / 85582 verification script
REM  用法：直接雙擊執行，或在 cmd 打 scan-verify.bat
REM  要換環境只改下面兩行
REM ============================================================
set "HOST=https://chinaairlines.iqs-t.com"
set "APP=/drive"

where curl >nul 2>nul
if errorlevel 1 (
  echo [ERROR] 找不到 curl，請改用 Windows 10 1803 以上或自行安裝 curl。
  pause & exit /b 1
)

echo.
echo ============================================================
echo   弱點修補驗證   Target: %HOST%%APP%
echo   %DATE% %TIME%
echo ============================================================
echo.

echo [11714] 實體路徑洩漏  ^(沒有輸出 D:\ = PASS^)
echo ------------------------------------------------------------
call :CHKPATH "%HOST%%APP%/notexist123.asp"
call :CHKPATH "%HOST%%APP%/notexist123.aspx"
call :CHKPATH "%HOST%%APP%/notexist123"
call :CHKPATH "%HOST%/notexist123.asp"
echo.

echo [85582] Clickjacking 標頭  ^(2 個標頭都在 = PASS^)
echo ------------------------------------------------------------
call :CHKHDR "%HOST%%APP%/"
call :CHKHDR "%HOST%%APP%/home"
call :CHKHDR "%HOST%/"
echo.

echo ============================================================
echo  全部 PASS 才算通過，任一 FAIL 請截圖回報。
echo ============================================================
echo.
pause
exit /b


:CHKPATH
curl -sk %~1 2>nul | findstr /i /c:"D:\" >nul
if errorlevel 1 (
  echo   [PASS]  %~1
) else (
  echo   [FAIL]  %~1   ^<-- 仍洩漏實體路徑
)
exit /b


:CHKHDR
set "N=0"
for /f %%A in ('curl -sk -o NUL -D - %~1 2^>nul ^| findstr /i /c:"X-Frame-Options" /c:"Content-Security-Policy" ^| find /c /v ""') do set "N=%%A"
if "!N!"=="2" (
  echo   [PASS]  %~1   ^(2 headers^)
) else (
  echo   [FAIL]  %~1   ^(只找到 !N! 個標頭^)
)
exit /b
