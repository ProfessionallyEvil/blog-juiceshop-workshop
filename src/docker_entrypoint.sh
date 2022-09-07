#!/bin/bash

# https://elrey.casa/bash/scripting/harden
set -euxvo pipefail
(
    rm -f /completed /failed
    echo "echo waiting for install to finish && echo ; echo ; while true; do ps -aux | grep '[s]leep' >/dev/null && break || (ps -aux ; sleep 5) ; done && clear" >> ~/.bashrc
    npm install -g aws-cdk@$(grep '^aws-cdk' Pipfile | awk -F'["=]' '{print $5}')
    pip3 install pipenv
    pipenv sync --dev --bare --system
) && touch /completed || touch /failed
sleep infinity
