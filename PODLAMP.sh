#!/bin/bash

# Ensure Podman is installed and accessible
PODMAN_EXISTS=$(command -v podman > /dev/null ; echo $?)

################################################################################
#############  These are the functions that are called by the menu  ############
################################################################################

function SETUP {
podman machine init
podman machine set --rootful
podman machine start
[[ ! -d $HOME/htdocs ]] && mkdir $HOME/htdocs
podman pod create --name LAMP -p 80:80
podman run -d --name LAMP-mariadb --pod LAMP -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 mariadb:latest
podman run -d --name LAMP-PMA --pod LAMP -e PMA_HOST=127.0.0.1 -e PMA_PORT=3306 -v $HOME/htdocs:/var/www/html/htdocs phpmyadmin
echo -e "\nPODLAMP has been setup and should be running\nFiles in $HOME/htdocs will show up in http://localhost/htdocs/<filename>\n"
MENU
}

function START {
podman start LAMP-mariadb LAMP-PMA
echo -e "\nPODLAMP should now be running\nFiles in $HOME/htdocs will show up in http://localhost/htdocs/<filename>\n"
}

function STOP {
podman stop LAMP-mariadb LAMP-PMA
echo -e "\nPODLAMP should now be stopped\n"
}

function DESTROY {
STOP
podman rm LAMP-mariadb LAMP-PMA
podman pod rm LAMP
podman image rm mariadb phpmyadmin
podman machine stop
podman machine rm
echo "PODLAMP has been stopped and all remnants have been removed\nIf you wish to run PODLAMP again, you must run Setup\nYou can now manually remove the Podman package if you wish\n"
}

function TEST {
podman run --name hello-world hello-world
podman rm hello-world
podman image rm podman/hello
echo -e "\nIf you see something similar to what is seen here: https://github.com/containers/podman?tab=readme-ov-file#podman-hello\nThen podman is running properly\n"

}

################################################################################
##########################  This is the Menu fuction  ##########################
################################################################################

function MENU {

PS3=$'\n'"Please enter your choice: "    # NOTE: The prompt is displayed AFTER the menu

########  The options listed here should match the options in the Menu  ########
select menuitem in Setup Start Stop Destroy Test Quit

do
    case $menuitem in
        "Setup")
            SETUP;;
        "Start")
           START;;
        "Stop")
           STOP;;
        "Destroy")
           DESTROY;;
        "Test")
           TEST;;
         "Quit")
           echo -e "Good Bye \n\n"
           exit;;
        *)
           MENU;;
    esac
done
}

################################################################################
##################  End of functions, now just call the Menu  ##################
################################################################################

[[ $PODMAN_EXISTS = 0 ]] && MENU || echo -e "\nPodman doesn't appear to be installed.  Please install it from https://github.com/containers/podman/releases/latest and try again\n"
