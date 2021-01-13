#!/bin/bash
echo $1 $2 is in $3 state > /var/run/keepalived_$1_$2.state
