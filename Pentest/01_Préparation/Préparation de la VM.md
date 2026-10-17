# Préparation de la VM
## Sécurité
### Linux

* Chiffrement du disque dur : Avec l'option "Swap (no Hibernate)"
* Mise à jour de l'OS et des paquets : `sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y`

### Windows (Prendre une version developper de l'OS)

* Chiffrement du disque dur
* Mise à jour de l'OS : `Install-WindowsUpdate -AcceptAll`
* Installation de Chocolatey : `Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))`
* Mise à jour de Chocolatey : `choco upgrade chocolatey -y `
* Installation de Windows Subsystem for Linux  (WSL) pour permettre l'exécution d'une distribution linux sous forme de conteneur : `choco install WSL2`
* Ajouter des exlusions dans Windows Defender pour ne pas être bloquer par l'antivirus : `Add-MpPreference -ExclusionPath "C:\Users\your user here\AppData\Local\Temp\chocolatey\"`

## Logs

### Linux : 

* Date : Permet d'afficher la date et l'heure dans le prompt.
* Script : Permet de log toute les commandes utilisées dans un fichier de log.

### Windows : 

* `Start-transcript fichier.log`
  
## Documentation

* CherryTree : Pour la prise de note
* Flameshot : Pour les screenshots
* Peek : Pour créer des GIFs
