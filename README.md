# icinga2-keepalived

icinga2-keepalived is an icinga2 plugin to remotely check the status of keepalived instances.


For the plugin to function correctly you have to add a notification script to the keepalived.conf for each instance that you want to monitor.

  -> keepalived_notify.sh


Add the script itself.

  -> keepalived_notify.sh


Add the check plugin itself.

  -> check_keepalived.conf


Add the service definition. 

  -> by_ssh_keepalived.conf


Add the command definition.

  -> check_by_ssh_keepalived.conf


Restart icinga2 and check for errors.


I'm monitoring remote via ssh. If you need to monitor one instance locally, you need to define a local command and service.
If I ever need to monitor one instance locally, I'll ad the command and script... or if I have some time left ;)
