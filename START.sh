#!/bin/bash
#
#Ejecutar en root
# Got root?
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    toilet -f future 'Password:'
    sudo ./$0
    exit
fi
#
#CHECHEO DE PLATAFORMA
if [ -f "/etc/systemd/system/tpot.service" ]; then
    toilet -f pagga 'Plataforma T-POT'
    if [ -f "/home/tsec/PCAP/tcpdump.pcap" ]; then
        echo "Este script solo se ejectuta una vez despues de la instalacion"; sleep 3; exit 1
    else
        echo "Plataforma T-Pot: OK"
    fi
else
    echo "Este script solo funciona en la plataforma T-Pot."; cd ..; rm -r SCRIPT/; echo "Saliendo..."; sleep 3
    exit 1
fi
#Checar Contenedor Cowrie
if docker ps -a | grep cowrie > /dev/null; then
    echo "Cowrie is running."
else
    echo "El contenedor "cowrie" no se encuentra"
    echo "Posibles causas:"
    echo "1. La instalacion de T-Pot es diferente a "STANDARD""
    echo "2. La plataforma T-Pot presenta fallas"
    echo "Se recomienda volver a instalar T-Pot "
    echo "Saliendo.."
    sleep 3
    exit 1
fi
#
#Estableciendo zona horaria..."
timedatectl set-timezone UTC
timedatectl set-ntp true
#
CRON_DIR="/etc/crontab"
vt_toml="/root/.vt.toml"
#Configuraciones
#Configurando VIRUSTOTAL
wget https://github.com/VirusTotal/vt-cli/releases/download/0.13.0/Linux64.zip &&unzip Linux64.zip && rm Linux64.zip
#
function vt_init(){
    /home/tsec/SCRIPT/vt init
}
#
while true
    do
        if [ -f "$vt_toml" ]; then
        toilet -f future 'OK'; sleep 2
        break         
        else
        toilet -f future 'Enter a valid API key'; sleep 3; clear; vt_init
        fi
    done
#d7b8d0be41b03de429347d44f5c34814003bb2584a62803cd1921fc915ee4554
#Sincronizando Nube
echo "Instalando rclone"
sudo -v ; curl https://rclone.org/install.sh | sudo bash
toilet -f ivrit "rclone"
rclone config
#rclone sync /home/tsec/CHECKS nexcloud:PRUEBA_tsec ###CAMBIALA a los crons al terminar
#rclone mkdir nexcloud:Exito
#https://cloudsecuritylab.dev/remote.php/dav/files/lab/
#
#
toilet -f ivrit 'Instalando dependencias...'
sleep 2
apt install -y tcpdump wireshark-common
#
echo "Directorios y scripts"
mkdir -vp /home/tsec/CHECKS \
          /home/tsec/PCAP
#
echo "Configurando Demonios..."
sed -i -e '$i\/home/tsec/SCRIPT/tcpdump_start.sh &' /etc/rc.local
#
#
function CMIN(){
    grep -A 1 Daily $CRON_DIR |head -n 2 | tail -n 1 | cut -c 1-2 
}
#
function CHOUR(){
    grep -A 1 Daily $CRON_DIR |head -n 2 | tail -n 1 |cut -c 4-5
}
#
echo >> $CRON_DIR
echo "#Stop tcpdump & check captures everyday" >> $CRON_DIR
echo $(CMIN)  $(expr $(CHOUR) - 1) "* * *      root    killall tcpdump && sleep 30 && /home/tsec/SCRIPT/checker.sh" >> $CRON_DIR
#Finished
toilet -f ivrit '...Instalado'
sleep 3
dialog --keep-window --no-ok --no-cancel --backtitle "$myBACKTITLE" --title "[ Reiniciando el sistema... ]" --pause "" 7 80 5
clear 
reboot