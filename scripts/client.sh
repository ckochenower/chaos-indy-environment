#!/bin/bash

display_usage() {
	echo "Usage:\t$0 <TIMEZONE> "
	echo "EXAMPLE: $0 /usr/share/zoneinfo/America/Denver"
}

# if less than one argument is supplied, display usage
if [  $# -ne 3 ]
then
    display_usage
    exit 1
fi

TIMEZONE=$1
NODEIPLIST=$2
REPO=$3

echo "TIMEZONE=${TIMEZONE}"
echo "NODEIPLIST=${NODEIPLIST}"
echo "REPO=${REPO}"

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
add-apt-repository "deb https://repo.sovrin.org/sdk/deb xenial ${REPO}"
apt-get update

# Indy node is needed to provide the "generate_indy_pool_transactions"
# executable used below.
# The following deps are for Chaos: python3 python3-venv libffi-dev
DEBIAN_FRONTEND=noninteractive apt-get install -y unzip make screen indy-node indy-cli libsovtoken tmux vim wget python3 python3-venv libffi-dev

# Required by generate_indy_pool_transactions script
awk '{if (index($1, "NETWORK_NAME") != 0) {print("NETWORK_NAME = \"sandbox\"")} else print($0)}' /etc/indy/indy_config.py> /tmp/indy_config.py
mv /tmp/indy_config.py /etc/indy/indy_config.py

#--------------------------------------------------------
echo 'Setup SSH and Chaos pool configuration...'
usernames=(
  "ubuntu"
  "vagrant"
)

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

  # Setup pool directory in user's home directory
  echo 'Generate pool (pool1) directory required by Chaos experiments'
  mkdir -m 700 -p /home/${username}/pool1
  cp -f /home/${username}/.ssh/config /home/${username}/pool1/ssh_config
  chmod 600 /home/${username}/pool1/ssh_config
  cp -f /home/${username}/.indy-cli/networks/sandbox/pool_transactions_genesis /home/${username}/pool1/
  chmod 644 /home/${username}/pool1/pool_transactions_genesis
  echo '["cli01"]' > /home/${username}/pool1/clients
  chmod 644 /home/${username}/pool1/clients
  chown -R ${username} /home/${username}/pool1

  # Give the user passwordless sudo
  echo "Give user ${username} passwordless sudo rights..."
  echo "${username} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/chaos_${username}

  # Must have a clone of indy-node in user's home directory (symlink is
  # sufficient). Needed for loading the cluster with traffic using the
  # indy-node/scripts/performance/perf_load/perf_processes.py script.
  echo "Creating synlink to indy-node in ${username}'s home directory..."
  ln -sf /vagrant/indy-node /home/${username}/indy-node

  # Create a Chaos python virtualenv
  echo "Setting up Chaos python virtualenv..."
  su - ${username} -c "python3 -m venv /home/${username}/.venvs/chaostk"

  # Note: Can't activate a virtualenv and then install dependencies. Rather the
  #       pip3 and python3 executables within chaostk should be used (relative
  #       or absolute path) in order to get dependencies installed within the
  #       chaostk virtualenv.

  echo "Pre-installing all requirements. For some reason the python3 setup.py"
  echo "develop commands below don't work the same when executing from a"
  echo "vagrant init script vs. when the command is run from a shell on the VM."
  # Must install wheel first!
  echo "Installing wheel in chaostk..."
  su - ${username} -c "/home/${username}/.venvs/chaostk/bin/pip3 install wheel"

  # Force all requirements to be pip3 installed.
  echo "Preinstalling all chaosindy dependecies defined in requirements.txt and requirements-dev.txt..."
  su - ${username} -c "/home/${username}/.venvs/chaostk/bin/pip3 install $(cat /vagrant/indy-test-automation/chaos/requirements.txt | xargs)"
  su - ${username} -c "/home/${username}/.venvs/chaostk/bin/pip3 install $(cat /vagrant/indy-test-automation/chaos/requirements-dev.txt | xargs)"
  # Install chaosindy in the virtualenv
  echo "Installing chaosindy within chaostk virtualenv..."
  # Important - Running the python3 setup.py develop as as the given user
  #             results in a permission denied, because the
  #             indy-test-automation clone is shared from the vagrant host
  cd /vagrant/indy-test-automation/chaos && /home/${username}/.venvs/chaostk/bin/python3 setup.py develop

  # Force all requirements to be pip3 installed.
  echo "Preinstalling all chaossovtoken dependecies defined in requirements.txt and requirements-dev.txt..."
  su - ${username} -c "/home/${username}/.venvs/chaostk/bin/pip3 install $(cat /vagrant/sovrin-test-automation/chaos/requirements.txt | xargs)"
  su - ${username} -c "/home/${username}/.venvs/chaostk/bin/pip3 install $(cat /vagrant/sovrin-test-automation/chaos/requirements-dev.txt | xargs)"
  # Install chaossovtoken in the virtualenv
  echo "Installing chaossovtoken within chaostk virtualenv..."
  # Important - Running the python3 setup.py develop as as the given user
  #             results in a permission denied, because the
  #             sovrin-test-automation clone is shared from the vagrant host
  cd /vagrant/sovrin-test-automation/chaos && /home/${username}/.venvs/chaostk/bin/python3 setup.py develop

  # Enhance the .profile 
  profilefile="/home/${username}/.profile"

  # Source chaostk virtualenv on login
  echo 'source ~/.venvs/chaostk/bin/activate' >> ${profilefile}

  # Setup aliases
  # TODO: install indy-test-automation (at minimum) and create aliases for all
  #       monitor-* and reset-* scripts found in the
  #       /vagrant/indy-test-automation/chaos/scripts. Doing so allows the repo
  #       to add/remove scripts. Aliases effectively become dynamic when
  #       provisioning on 'vagrant up' and/or 'vagrant up --provision'.

  # Aliases convenient for changing directory to chaos directory under each source repo
  repos=(
    "indy"
    "sovrin"
  )

  for repo in "${repos[@]}"
  do
    aliasname="cd${repo}"
    if ! grep -q ${aliasname} "${profilefile}"; then
      echo alias cd${repo}="\"cd /vagrant/${repo}-test-automation/chaos\"" >> ${profilefile}
      echo alias run${repo}="\"cd /vagrant/indy-test-automation/chaos && ./run.py pool1 --experiments='{\\\"path\\\": [\\\"/vagrant/${repo}-test-automation/chaos\\\"]}'\"" >> ${profilefile}
    fi
  done

  # Aliases convenient for monitoring pool stats using 'watch' command
  monitors=(
    "all"
    "services"
    "catchup"
    "master"
    "replicas"
  )

  for monitor in "${monitors[@]}"
  do
    aliasname="monitor${monitor}"
    if ! grep -q ${aliasname} "${profilefile}"; then
      echo alias monitor${monitor}="\"watch -n5 '/vagrant/indy-test-automation/chaos/scripts/monitor-${monitor} 2>/dev/null'\"" >> ${profilefile}
    fi
  done

  # Aliases convenient for resetting pool stats using 'watch' command
  resets=(
    "pool"
  )

  for reset in "${resets[@]}"
  do
    aliasname="reset${reset}"
    if ! grep -q ${aliasname} "${profilefile}"; then
      echo alias reset${reset}="/vagrant/indy-test-automation/chaos/scripts/reset-${reset}" >> ${profilefile}
    fi
  done
done

#--------------------------------------------------------
echo 'Cleaning Up'
rm /etc/update-motd.d/10-help-text
apt-get update
#DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
updatedb
