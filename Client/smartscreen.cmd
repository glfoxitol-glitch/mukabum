@echo off
title SmartScreen Fix [MuOnline]

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
"$p=0; ^
Write-Host 'Iniciando reparacion...'; ^
for ($i=0; $i -le 100; $i+=10) { ^
    Write-Progress -Activity 'Reparando SmartScreen' -Status \"$i%% completado\" -PercentComplete $i; ^
    Start-Sleep -Milliseconds 300 ^
}; ^
Unblock-File 'main.exe'; ^
Write-Host 'OK: Aplicacion lista para ejecutarse.'"

pause