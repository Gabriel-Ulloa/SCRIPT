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
