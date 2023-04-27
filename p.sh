#!/bin/bash
#
if grep -q "cowrie_local:" /opt/tpot/etc/tpot.yml; then
    echo "La palabra se encuentra en el archivo."
else
    echo "La palabra no se encuentra en el archivo."
fi

