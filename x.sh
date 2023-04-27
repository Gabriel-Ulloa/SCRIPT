#!/bin/bash
#
if docker ps -a | grep cowrie > /dev/null; then
    echo "El contenedor está en ejecución."
else
    echo "El contenedor no está en ejecución."
    exit 1
fi
