#!/bin/bash
echo $1 $2 is in $3 state > /var/run/keepalived_$1_$2.state

-> resulting filename with the example will be 
/var/run/keepalived_INSTANCE_VI1.state
