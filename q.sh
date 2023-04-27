#!/bin/bash
#
if [ -d "/etc/systemd/system/tpot.service" ]; then
    ls /etc/systemd/system/tpot.service
else
    echo "El directorio no se encuentra."
fi
