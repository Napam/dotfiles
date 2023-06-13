# Install chocolatey:
```
Set-ExecutionPolicy Bypass -Scope Process -Force;
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072;
iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

- Use chocolatey to install stuff:
- ```choco install chocoinstall.txt```

# Remember autohotkey! 
```Win+R -> type shell:startup -> add shortcut to .ahk file to startup things```

# Other stuff to remember:

- Windows Terminal
- Wolfram Alpha
- Python
- Linux (WSL)

Make PowerShell tab completion like bash:
Copy profile.ps1 to User/Documents/WindowsPowerShell/

## Other notes:
    Firewall is mean to WSL, may block some internet stuff

