#!/bin/bash
#
if [ -f "/etc/systemd/system/tpot.service" ]; then
    echo "El archivo se encuentra en la ruta especificada."
else
    echo "Este script solo funciona en la plataforma T-Pot."
fi
