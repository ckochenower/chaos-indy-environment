#!/bin/bash

display_usage() {
	echo -e "Usage:\t$0 <NODENAME> <NODEIP> <NODEPORT> <CLIENTIP> <CLIENTPORT> <TIMEZONE>"
	echo -e "EXAMPLE: $0 Node1 0.0.0.0 9701 0.0.0.0 9702 /usr/share/zoneinfo/America/Denver"
}

# if less than one argument is supplied, display usage
if [  $# -ne 8 ]
then
    display_usage
    exit 1
fi

HOSTNAME=$1
NODEIP=$2
NODEPORT=$3
CLIENTIP=$4
CLIENTPORT=$5
TIMEZONE=$6
NODEIPLIST=$7
REPO=$8

echo "HOSTNAME=$HOSTNAME"
echo "NODEIP=$NODEIP"
echo "NODEPORT=$NODEPORT"
echo "CLIENTIP=$CLIENTIP"
echo "CLIENTPORT=$CLIENTPORT"
echo "TIMEZONE=$TIMEZONE"
echo "NODEIPLIST=$NODEIPLIST"
echo "REPO=$REPO"

#--------------------------------------------------------
echo 'Setting Up Networking'
cp /vagrant/etc/hosts /etc/hosts
perl -p -i -e 's/(PasswordAuthentication\s+)yes/$1no/' /etc/ssh/sshd_config
service sshd restart

#--------------------------------------------------------
echo 'Setting up timezone'
cp $TIMEZONE /etc/localtime

#--------------------------------------------------------
echo "Installing Required Packages"
apt-get update
apt-get install -y software-properties-common python-software-properties
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 68DB5E88
add-apt-repository "deb https://repo.sovrin.org/deb xenial ${REPO}"
apt-get update
#DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
DEBIAN_FRONTEND=noninteractive apt-get install -y unzip make screen indy-node sovtoken sovtokenfees tmux vim wget

awk '{if (index($1, "NETWORK_NAME") != 0) {print("NETWORK_NAME =\"sandbox\"")} else print($0)}' /etc/indy/indy_config.py> /tmp/indy_config.py
mv /tmp/indy_config.py /etc/indy/indy_config.py

#--------------------------------------------------------
[[ $HOSTNAME =~ [^0-9]*([0-9]*) ]]
NODENUM=${BASH_REMATCH[1]}
echo "Setting Up Indy Node Number $NODENUM"
su - indy -c "init_indy_node $HOSTNAME $NODEIP $NODEPORT $CLIENTIP $CLIENTPORT"  # set up /etc/indy/indy.env
echo "Generating indy pool transactions"
su - indy -c "generate_indy_pool_transactions --nodes 4 --clients 4 --nodeNum $NODENUM --ips $NODEIPLIST"

#--------------------------------------------------------
echo 'Fixing Bugs'
echo 'Fixing indy-node init file...'
if grep -Fxq '[Install]' /etc/systemd/system/indy-node.service
then
  echo '[Install] section is present in indy-node target'
else
  perl -p -i -e 's/\\n\\n/[Install]\\nWantedBy=multi-user.target\\n/' /etc/systemd/system/indy-node.service
fi
echo 'Fixing indy_config.py file...'
if grep -Fxq 'SendMonitorStats' /etc/indy/indy_config.py
then
  echo 'SendMonitorStats is configured in indy_config.py'
else
  printf "\n%s\n" "SendMonitorStats = False" >> /etc/indy/indy_config.py
fi

#--------------------------------------------------------
echo 'Enable and start indy-node service'
systemctl start indy-node
systemctl enable indy-node
systemctl status indy-node.service

#--------------------------------------------------------
# Ensure each user in the usernames array below has the ssh key pair generated
# by the setup.sh script
echo 'Setup SSH...'
declare -a usernames=("ubuntu" "vagrant")

for username in "${usernames[@]}"
do
  # Create user
  useradd ${username}
  mkdir -m 700 -p /home/${username}/.ssh
  cp -f /vagrant/ssh/id_rsa* /home/${username}/.ssh/
  cp -f /vagrant/ssh_config /home/${username}/.ssh/config
  sed -i.bak s/\<USERNAME\>/${username}/g /home/${username}/.ssh/config
  PUB_KEY=$(cat /home/${username}/.ssh/id_rsa.pub)
  grep -q -F "${PUB_KEY}" /home/${username}/.ssh/authorized_keys 2>/dev/null || echo "${PUB_KEY}" >> /home/${username}/.ssh/authorized_keys
  chmod 600 /home/${username}/.ssh/authorized_keys
  chown -R ${username} /home/${username}

  # Generate the pool_transactions_genesis file
  echo 'Generating Genesis Transaction Files required by Chaos experiments for user ${username}'
  su - ${username} -c "generate_indy_pool_transactions --nodes 4 --clients 4 --ips ${NODEIPLIST}"

  # Give the user passwordless sudo
  echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/chaos_${username}
done


#--------------------------------------------------------
echo 'Cleaning Up'
rm /etc/update-motd.d/10-help-text
rm /etc/update-motd.d/97-overlayroot
apt-get update
updatedb
