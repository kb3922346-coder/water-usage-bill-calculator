@echo off
cd /d "%~dp0"
title Water Usage & Bill Calculator Server

echo [1/2] Checking C compiler...
if not exist "cgi-bin\calculate.exe" (
    if exist "C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe" (
        echo Compiling calculate.c using CodeBlocks MinGW...
        "C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe" calculate.c -o cgi-bin\calculate.exe
        "C:\Program Files\CodeBlocks\MinGW\bin\gcc.exe" calculate.c -o cgi-bin\calculate.cgi
    ) else (
        echo Warning: gcc not found in CodeBlocks. Checking PATH...
        gcc calculate.c -o cgi-bin\calculate.exe
    )
)

echo [2/2] Starting local web server on http://localhost:8080...
start http://localhost:8080/

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1" -Port 8080
pause

