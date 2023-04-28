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
    toilet -f pagga 'plataforma T-POT'
    if [ -f "/home/tsec/PCAP/tcpdump.pcap" ]; then
        echo "Este script solo se ejectuta una vez despues de la instalacion"
        sleep 3
        exit 1
    else
        echo "Plataforma T-Pot: OK"
    fi
else
    echo "Este script solo funciona en la plataforma T-Pot."
    echo "Saliendo..."
    sleep 5
    exit 1
fi
#Checar Contenedor Cowrie
#Mini menu
function MINI(){
    echo "El contenedor "cowrie" no se encuentra"
    echo "Posibles causas:"
    echo "1. La instalacion de T-Pot es diferente a "STANDARD""
    echo "2. La instalacion de T-Pot no funciona"
    echo "Se recomienda volver a instalar T-Pot "
    echo "Saliendo.."
    sleep 5
    exit 1
}
#
if docker ps -a | grep cowrie > /dev/null; then
    echo "El contenedor está en ejecución."
else
    MINI
fi
#
#Configuraciones
#Cambiar Hora a UTC
CRON_DIR="/etc/crontab"
#
echo "Estableciendo zona horaria..."
timedatectl set-timezone UTC
timedatectl set-ntp true
echo "ok"
#
#
toilet -f ivrit 'Instalando dependencias...'
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
#
echo >> $CRON_DIR
echo "#Stop tcpdump & check captures" >> $CRON_DIR
echo $(CMIN)  $(expr $(CHOUR) - 1) "* * 1-6      root    killall tcpdump && sleep 30 && /home/tsec/SCRIPT/checker.sh" >> $CRON_DIR

#Finished
toilet -f ivrit '...Instalado' 
sleep 3
reboot