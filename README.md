# icinga2-keepalived

icinga2-keepalived is an icinga2 plugin to remotely check the status of keepalived instances.

For the plugin to function correctly you have to add a notification script to the keepalived.conf for each instance that you want to monitor.

    vrrp_instance VI1 {
    	...
      notify "/path/to/script/keepalived_notify.sh"
    }

Add the script itself.

keepalived_notify.sh

    #!/bin/bash
    echo $1 $2 is in $3 state > /var/run/keepalived_$1_$2.state

-> resulting filename with the example will be /var/run/keepalived_INSTANCE_VI1.state

Add the check plugin itself.

/usr/lib/nagios/plugins/check_keepalived.conf
```
#!/bin/bash

# $1 = master/backup
# $2 = notification_file

if [ "$#" -ne 2 ]; then
    echo "Illegal number of parameters"
    echo "Usage: $0 disired_state notification_output_file"
    exit 255
fi

# set to 'true' if the host is supposed to be in MASTER state
# or set to 'false' if the host is supposed to be in BACKUP state
# nrpe cannot receive external variables UNLESS is forced in config
if [ $1 == "master" ]; then
        MASTER='true'
else
        MASTER='false'
fi

OK=0            # - Service is OK.
WARNING=1       # - Service has a WARNING.
CRITICAL=2      # - Service is in a CRITICAL status.
UNKNOWN=3       # - Service status is UNKNOWN.

# checking if there are alive keepalived processes so we can trust the content of the notify 'state' file
KEEPALIVENUM=$(ps aux | grep -v grep | grep keepalived -c)

if [ $KEEPALIVENUM -gt 0 ]; then

        KEEPALIVESTATE=$(cat $2)

        if [ "$MASTER" == "true" ]; then

                if [[ $KEEPALIVESTATE == *"MASTER"* ]];then
                        echo OK: $KEEPALIVESTATE
                        exit $OK
                fi

                if [[ $KEEPALIVESTATE == *"BACKUP"* ]];then
                        echo WARNING: $KEEPALIVESTATE
                        exit $WARNING
                fi

        else

                if [[ $KEEPALIVESTATE == *"BACKUP"* ]];then
                        echo OK: $KEEPALIVESTATE
                        exit $OK
                fi

                if [[ $KEEPALIVESTATE == *"MASTER"* ]];then
                        echo WARNING: $KEEPALIVESTATE
                        exit $WARNING
                fi

          fi
fi

echo "Keepalived is in UNKNOWN state"
exit $UNKNOWN
```

Add the following variables to the host definition file.
```
object Host "blablabla" {
	...
   	vars.keepalived_instance["VI1"] = { statefile = "/var/run/keepalived_INSTANCE_VI1.state", state_expected = "master" }
   	vars.keepalived_instance["VI2"] = { statefile = "/var/run/keepalived_INSTANCE_VI2.state", state_expected = "master" }
   	vars.by_ssh_keepalived_host = "333.444.555.666"
   	vars.by_ssh_keepalived_login = "sshuser"
   	vars.by_ssh_keepalived_key = "/var/lib/nagios/.ssh/id_rsa"
   	vars.by_ssh_keepalived_command = "/usr/lib/nagios/plugins/check_keepalived.sh"

}
```

Add the service definition (services/by_ssh_keepalived.conf).
```
apply Service for (keepalived_instance => config in host.vars.keepalived_instance) {
    import "generic-service"
    check_command = "check_by_ssh_keepalived"

    vars += config
    vars.keepalived_instance = keepalived_instance
    vars.statefile = vars.statefile
    vars.state_expected = vars.state_expected
    display_name = "keepalived_instance_" + vars.keepalived_instance

    assign where host.vars.keepalived_instance
}
```

Add the command definition (commands/check_by_ssh_keepalived.conf).
```
object CheckCommand "check_by_ssh_keepalived" {
   import "plugin-check-command"
   command = [ PluginDir + "/check_by_ssh" ]
   arguments = {
     "-H" = {
       required = true
       value = "$by_ssh_keepalived_host$"
     }
     "-l" = {
       required = true
       value = "$by_ssh_keepalived_login$"
     }
     "-i" = {
       required = true
       value = "$by_ssh_keepalived_key$"
     }
     "-C" = {
       required = true
       value = "$by_ssh_keepalived_command$ $service.vars.state_expected$ $service.vars.statefile$"
     }
     "-o" = {
        value = "StrictHostKeyChecking=no"
     }
     "-t" = {
        value = "30"
     }
   }
}
```

Restart icinga2 and check for errors.
