DISM /Online /Set-ReservedStorageState /State:Disabled

POWERCFG /HIBERNATE OFF

WMIC COMPUTERSYSTEM WHERE NAME="%COMPUTERNAME%" SET AutomaticManagedPagefile=False
WMIC PAGEFILESET WHERE NAME="C:\\pagefile.sys" DELETE

WMIC RECOVEROS SET DebugInfoType=0

D:\scripts\virtio-win-guest-tools.exe /S

CertUtil -f -addstore "TrustedPublisher" D:\scripts\qxl-0.141.cer
D:\scripts\spice-guest-tools-0.141.exe /S

REG ADD HKLM\Software\Microsoft\Windows\CurrentVersion\RunOnce /v SecondLogon /t REG_SZ /d "D:\scripts\SecondLogon.cmd" /f

shutdown /r /f /t 0
