# Windows 11 notes

## Why did my computer restart?

```powershell
Get-WinEvent -FilterHashtable @{ LogName = 'System'; Id = 41, 1074, 6006, 6605, 6008; } | Format-List Id, LevelDisplayName, TimeCreated, Message
```

```cmd
wevtutil qe System /q:"*[System[(EventID=41) or (EventID=1074) or (EventID=6006) or (EventID=6005) or (EventID=6008)]]" /c:100 /f:text /rd:true
```

Credit: https://superuser.com/a/1821713
