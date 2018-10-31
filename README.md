# Summary
Sets up an Indy Chaos experiment development environment comprised of 1 client
and 4 validator nodes. The client(s) are configured with a python virtual
environment (chaostk) in which all dependencies for Chaos development
are installed.

# TODOs
1. Support an arbitrary number of validator nodes and clients. Perhaps by
   prompting the user for the number of clients (>1) and validator nodes (> 4),
   or reading settings from a settings/properties file.

# Overview
Topics covered in this README:
* Installation
  * Setup
  * Virtualbox
  * Vagrant
* Login
  * Client(s)
  * Validator(s)
* Aliases
* Running Experiments
* Writing Experiments
* Debugging Experiments
 
# Installation

## Setup
Run the setup script. The setup script will do the following:

1. Create an 'ssh' directory in the root of this vagrant project. The 'ssh'
   directory is included in .gitignore file, because we don't want to
   store keys in git.
2. Generate an SSH key pair and PEM file in the 'ssh' directory. Each vagrant VM
   will use this key pair for the vagrant and ubuntu user.
3. Check that the following three repos have been cloned to the root of this
   Vagrant project. Note that all files and folders found in the root of this
   project (where the Vagrantfile is located) are shared (bi-directionally) on
   each VM in the /vagrant directory. In other words, changes made to these
   repos while logged into the vagrant VMs are effectively making changes to the
   clones in the root of this vagrant project. Commits should be authored from
   the vagrant host (not in the VM)

   1. **indy-node**:
      Shared as /vagrant/indy-node on each VM. Only the client node(s) have a
      symlink (/home/[vagrant|ubuntu]/indy-node -> /vagrant/indy-node) in the
      'vagrant' and 'ubuntu' home directories. The indy-node repo contains a
      perf_processes.py batch script used for load/stress testing and is used by
      Chaos experiments to generate load when needed. The Choas experiments
      expect a clone of the indy-node repo to be present in the home directory
      of the the user running chaos experiments.

   2. **indy-test-automation**:
      Shared as /vagrant/indy-test-automation on each VM. A 'cdindy' alias is
      placed in /home/[vagrant|ubuntu]/.profile for convenience. When on client
      machines (i.e. cli01), running 'cdindy' changes directory to
      /vagrant/indy-test-automation/chaos.

      Chaos experiments are found under the 'chaos' directory. This project has
      a 'run.py' script capable of running any/all chaos experiments, even in
      other repos (clones present on the same machine). The run script is
      maintained in this repo, because it is assumed (at this time) that all
      experiments either directly or indirectly (i.e. plugins) test
      indy-node/indy-plenum functionality. See
      '/vagrant/indy-test-automation/run.py --help' for details.

      A run\<repo\> (i.e. replace \<repo\> with indy or sovrin) alias is placed
      in /home/[vagrant|ubuntu]/.profile for convenience in running _**all**_ of
      the experiments in the given repo. Login to a client (i.e. cli01) and run
      the 'alias' command to list all available aliases and get familiar with
      run\<repo\> aliases.

      Several monitor\<suffix\> (i.e. replace \<suffix\> with 'all', 'catchup',
      'master', 'replicas', services', etc.) aliases are placed in
      /home/[vagrant|ubuntu]/.profile for convenience in monitoring aspects of
      the pool, ledgers, etc. Login to a client (i.e. cli01) and run the
      'alias' command to list all available aliases and get familiar with
      monitor\<suffix\> aliases.

      Several reset\<suffix\> (i.e. replace \<suffix\> with 'pool', etc.)
      aliases are placed in /home/[vagrant|ubuntu]/.profile for convenience in
      resetting aspects of the pool, ledgers, etc. Login to a client
      (i.e. cli01) and run the 'alias' command to list all available aliases and
      get familiar with reset\<suffix\> aliases.

   3. **sovrin-test-automation**:
      Shared as /vagrant/sovrin-test-automation on each VM. A 'cdsovrin' alias
      is placed in /home/[vagrant|ubuntu]/.profile for convenience. When on
      client machines (i.e. cli01), running 'cdsovrin' changes directory to
      /vagrant/sovrin-test-automation/chaos.

      Chaos experiments are found under the 'chaos' directory.

## Virtualbox

[Install Virtualbox](https://www.virtualbox.org/wiki/Downloads)

Tested with VirtualBox 5.2.16 r123759 (Qt5.6.3) on macOS 10.12.6 

## Vagrant

[Install Vagrant](https://www.vagrantup.com/docs/installation/)

Tested with Vagrant 2.1.2 on macOS 10.12.6 

Run `vagrant up`

# Login

You can ssh to any of the nodes using either `vagrant ssh \<host\>` or
`ssh vagrant@127.0.0.1 -p \<port\> -i ./ssh/id_rsa` where `./ssh/id_rsa` is the
ssh key created by running the setup script. Note that the port may be different
if the ports are already in use when you run `vagrant up`. Vagrant will pick the
next available port to map to port 22 if the configured port (in the
Vagrantfile) is already in use. If you want to use `ssh` instead of
`vagrant ssh` and you feel the port-picking feature of vagrant is annoying, you
can configure each VM in the Vagrantfile to use specific ports.
## Client(s)
### Vagrant
```
vagrant ssh cli01
```
### SSH
```
ssh vagrant@127.0.0.1 -p 2222 -i ./ssh/id_rsa
```
## Validator(s)
### Vagrant
```
vagrant ssh validator01
vagrant ssh validator02
vagrant ssh validator03
vagrant ssh validator04
```
### SSH
```
ssh vagrant@127.0.0.1 -p 2200 -i ./ssh/id_rsa
ssh vagrant@127.0.0.1 -p 2201 -i ./ssh/id_rsa
ssh vagrant@127.0.0.1 -p 2202 -i ./ssh/id_rsa
ssh vagrant@127.0.0.1 -p 2203 -i ./ssh/id_rsa
```

# Aliases
Login to the client (cli01) and run `alias` to familiarize yourself with aliases
added for your convenience.
In summary:
- **cd\<repo\>** aliases change the working directory to the \<repo\> source
  directory mounted on the VM from the vagrant host.
- **monitor\<suffix\>** aliases monitor aspects of the pool/ledger/etc;
  producing human readable tabluar output refreshed periodically.
- **reset\<suffix\>** aliases reset aspects of the pool/ledger/etc.
- **run\<repo\>** aliases run _all_ of the Chaos experiments in a repo.

# Running Experiments
See ['Executing Experiments'](https://github.com/ckochenower/indy-test-automation/blob/master/chaos/README.md#executing-experiments) for details
In summary: There are two ways to run an experiment.
1. Using run.py
   See '/vagrant/indy-test-automation/run.py --help' for details.
2. Using the scripts/run-\<experiment\> script
   Each experiment
   ('/vagrant/\<repo\>-test-automation/chaos/experiments/\<experiment\>') has a
   corresponding 'run' script
   ('/vagrant/\<repo\>-test-automation/chaos/scripts/run-\<experiment\>')
   See the --help output for each 'run' script for details.

# Writing Experiments
See the
[README.md](https://github.com/hyperledger/indy-test-automation/chaos/README.md)
located in the indy-test-automation/chaos directory for details.
Finding a similar experiment, copying it
(\<repo\>/chaos/experiments/\<experiment\>.json) and it's associated 'run' script
(\<repo\>/chaos/scripts/run-\<experiment\> may be a good start.

# Debugging Experiments
You can place a 'import pdb; pdb.set_trace()' anywhere in python code and the
interpreter will hault when encountered.
