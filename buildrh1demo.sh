#!/bin/sh

if [ "${1}" = "-h" ] || [ "${1}" = "--help" ] ; then echo -e "\nUSAGE:\n$(basename ${0}) <api token>\n" ; exit ; fi

# Make sure you can get passwordless root
[[ $(sudo -A whoami) != "root" ]] && echo "You need to have passwordless sudo access" && exit

# Install ansible-core and git if necessary
[[ $(command -v ansible-playbook) ]] || sudo dnf -y install ansible-core
[[ $(command -v git) ]] || sudo dnf -y install git

if [ "${1}" = "" ] ; then
echo -e "\n\nGet an offline API token from https://console.redhat.com/ansible/automation-hub/token\n"
read -p "What is your offline token? " offline_token
else
offline_token=${1}
fi

# Clone the repos
git clone https://github.com/kubealex/rh1-image-mode-soe
git clone https://github.com/kubealex/rh1-image-mode-container-app
git clone https://github.com/kubealex/rh1-image-mode

# Create ansible.cfg
cat << EOF >> rh1-image-mode/aap-setup/ansible.cfg
[defaults]
inventory=./inventory
[galaxy]
server_list = automation_hub, galaxy

[galaxy_server.galaxy]
url=https://galaxy.ansible.com/

[galaxy_server.automation_hub]
url=https://console.redhat.com/api/automation-hub/content/published/ 
auth_url=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
token=${offline_token}
EOF

ansible-galaxy install -r rh1-image-mode/aap-setup/requirements.yml -f

#################################################
# Configure aap-setup/demo-setup-vars.yml first #
#################################################
ansible-playbook configure-aap.yml -e demo-setup-vars.yml -i inventory
