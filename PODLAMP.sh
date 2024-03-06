#!/bin/bash

# Ensure Podman is installed and accessible
PODMAN_EXISTS=$(command -v podman > /dev/null ; echo $?)

################################################################################
#############  These are the functions that are called by the menu  ############
################################################################################

function INSTALL_PODMAN {
read -n1 -p "Podman does not appear to be installed.  Would you like to install it now? (Y/N): " INSTALL_ANSWER
CAPS_ANSWER=$(echo "${INSTALL_ANSWER}" | tr '[:lower:]' '[:upper:]')

if [ "${CAPS_ANSWER}" = "Y" ] ; then
  PMVER=$(curl -I --silent https://github.com/containers/podman/releases/latest | grep location | awk '{print $2}' | cut -d "v" -f 2 | sed -e "s/\r//g")
  curl -L https://github.com/containers/podman/releases/download/v${PMVER}/podman-installer-macos-$(uname -m).pkg -o /tmp/podman-installer-macos-$(uname -m).pkg
  sudo installer -store -pkg "/tmp/podman-installer-macos-$(uname -m).pkg" -target /
  PODMAN_EXISTS=$(command -v podman > /dev/null ; echo $?)
  [[ $PODMAN_EXISTS = 0 ]] || echo -e "\nThe install appears to have failed.  Please install it manually from https://github.com/containers/podman/releases/latest and try again\n" || break
  MENU
else
  echo -e "\nPodman needs to be installed before running this script.  Please install it manually from https://github.com/containers/podman/releases/latest and try again\n"
fi
}

function SETUP {
podman machine init
podman machine set --rootful
podman machine start
[[ ! -d $HOME/Documents/htdocs ]] && mkdir $HOME/Documents/htdocs
podman pod create --name LAMP -p 80:80
podman run -d --name LAMP-mariadb --pod LAMP -e MARIADB_ALLOW_EMPTY_ROOT_PASSWORD=1 mariadb:latest
podman run -d --name LAMP-PMA --pod LAMP -e PMA_HOST=127.0.0.1 -e PMA_PORT=3306 -v $HOME/Documents/htdocs:/var/www/html/htdocs phpmyadmin
echo -e "\nPODLAMP has been setup and should be running\nFiles in $HOME/Documents/htdocs will show up in http://localhost/htdocs/<filename>\nphpMyAdmin can be accessed at http://localhost\n"
MENU
}

function START {
podman start LAMP-mariadb LAMP-PMA
echo -e "\nPODLAMP should now be running\nFiles in $HOME/Documents/htdocs will show up in http://localhost/htdocs/<filename>\nphpMyAdmin can be accessed at http://localhost\n"
MENU
}

function STOP {
podman stop LAMP-mariadb LAMP-PMA
echo -e "\nPODLAMP should now be stopped\n"
MENU
}

function DESTROY {
podman stop LAMP-mariadb LAMP-PMA
podman rm LAMP-mariadb LAMP-PMA
podman pod rm LAMP
podman image rm -f -i mariadb phpmyadmin
podman machine stop
podman machine rm -f
sudo /opt/podman/bin/podman-mac-helper uninstall
sudo rm /etc/paths.d/podman-pkg
sudo rm -rfv /opt/podman
echo -e "\nPODLAMP has been stopped and all remnants have been removed\nIf you wish to run PODLAMP again, you must run Setup\nYou can now manually remove the Podman package if you wish\n"
MENU
}

function TEST {
podman run --name hello-world hello-world
podman rm hello-world
podman image rm podman/hello
echo -e "\nIf you see something similar to what is seen here: https://github.com/containers/podman?tab=readme-ov-file#podman-hello\nThen podman is running properly\n"
MENU
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

#[[ $PODMAN_EXISTS = 0 ]] && MENU || echo -e "\nPodman doesn't appear to be installed.  Please install it from https://github.com/containers/podman/releases/latest and try again\n"
[[ $PODMAN_EXISTS = 0 ]] && MENU || INSTALL_PODMAN
