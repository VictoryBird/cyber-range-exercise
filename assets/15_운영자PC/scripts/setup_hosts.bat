@echo off
REM ============================================================
REM setup_hosts.bat — OT 운영자 PC hosts 파일 설정
REM 관리자 권한(CMD)으로 실행하세요.
REM ============================================================

echo.
echo  OT 운영자 PC hosts 파일 설정
echo  ============================================
echo.

REM 관리자 권한 확인
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [오류] 관리자 권한으로 실행하세요.
    echo         마우스 오른쪽 클릭 ^> "관리자 권한으로 실행"
    pause
    exit /b 1
)

set HOSTS_FILE=C:\Windows\System32\drivers\etc\hosts

REM 백업 생성
copy "%HOSTS_FILE%" "%HOSTS_FILE%.bak" >nul 2>&1
echo [1/2] hosts 파일 백업 완료

REM hosts 엔트리 추가 (중복 방지)
findstr /C:"scada-server" "%HOSTS_FILE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo 192.168.201.10    scada-server >> "%HOSTS_FILE%"
    echo   [추가] 192.168.201.10    scada-server
) else (
    echo   [존재] scada-server (이미 등록됨)
)

findstr /C:"plc-simulator" "%HOSTS_FILE%" >nul 2>&1
if %errorlevel% neq 0 (
    echo 192.168.201.11    plc-simulator >> "%HOSTS_FILE%"
    echo   [추가] 192.168.201.11    plc-simulator
) else (
    echo   [존재] plc-simulator (이미 등록됨)
)

echo.
echo [2/2] hosts 파일 설정 완료
echo.
echo  현재 hosts 파일 내용:
echo  ============================================
type "%HOSTS_FILE%"
echo  ============================================
echo.

pause
