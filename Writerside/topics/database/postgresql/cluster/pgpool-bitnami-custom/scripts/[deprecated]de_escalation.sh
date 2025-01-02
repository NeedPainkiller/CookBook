#!/bin/bash
# This script is run by wd_escalation_command to bring down the virtual IP on other pgpool nodes
# before bringing up the virtual IP on the new active pgpool node.

set -o xtrace

POSTGRESQL_STARTUP_USER=root
SSH_KEY_FILE=id_ed25519
SSH_OPTIONS="-p 12222 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${SSH_KEY_FILE}"
SSH_TIMEOUT=5

PGPOOLS=(pg-node-1,pg-node-2,pg-node-3)
VIP=192.168.0.250
DEVICE=enp11s0

#for pgpool in "${PGPOOLS[@]}"; do
#    [ "$HOSTNAME" = "$pgpool" ] && continue
#    /usr/sbin/ip addr del ${VIP}/24 dev ${DEVICE}
#done
exit 0

