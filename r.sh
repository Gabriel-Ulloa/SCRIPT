#!/bin/bash
#
if [ -f "/etc/systemd/system/tpot.service" ]; then
    echo "El archivo se encuentra en la ruta especificada."
else
    echo "El archivo no se encuentra en la ruta especificada."
fi
