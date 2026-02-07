DEL /F /Q /A "C:\BOOTNXT"
DEL /F /Q /A "C:\BOOTSECT.BAK"
DEL /F /Q /A "C:\DumpStack.*"
DEL /F /Q /A "C:\hiberfil.sys"
DEL /F /Q /A "C:\pagefile.sys"
DEL /F /Q /A "C:\swapfile.sys"

FOR /D %%d IN ("%WINDIR%\Temp\*") DO RD /S /Q "%%d"
DEL /F /Q /A "%WINDIR%\Temp\*"

FOR /D %%d IN ("%TEMP%\*") DO RD /S /Q "%%d"
DEL /F /Q /A "%TEMP%\*"

shutdown /s /f /t 0
