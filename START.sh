#!/bin/bash
#
#CHECHEO DE PLATAFORMA
if [ -f "/etc/systemd/system/tpot.service" ]; then
    echo "El archivo se encuentra en la ruta especificada."
    if [ -f "/home/tsec/PCAP/tcpdump.pcap" ]; then
        echo "Este script solo se puede ejecutar una vez"
        sleep 3
        exit 1
    else
        echo "Echale al root-INSTALANDO..."
    fi
else
    echo "Este script solo funciona en la plataforma T-Pot."
    echo "Saliendo..."
    sleep 5
    exit 1
fi
#Este script solo se ejectuta una vez despues de la instalacion
#Ejecutar en root
# Got root?
myWHOAMI=$(whoami)
if [ "$myWHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    sudo ./$0
    exit
fi
#Checar Plataforma T-Pot

CRON_DIR="/etc/crontab"
#Configuraciones
#Cambiar Hora a UTC
echo "Estableciendo zona horaria..."
timedatectl set-timezone UTC
timedatectl set-ntp true
echo "ok"
#
echo "Directorios y scripts"
mkdir -vp /home/tsec/CHECKS \
          /home/tsec/PCAP

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
#
echo >> $CRON_DIR
echo "#Stop tcpdump & check captures" >> $CRON_DIR
echo $(CMIN)  $(expr $(CHOUR) - 1) "* * 1-6      root    killall tcpdump && sleep 30 && /home/tsec/SCRIPT/checker.sh" >> $CRON_DIR

#Finished
toilet -f ivrit '...Instalado' 
sleep 3
reboot