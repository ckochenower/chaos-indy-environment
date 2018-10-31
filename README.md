#Installation

Run the setup script. This will do the following:

1. Create an 'ssh' directory in the root of this vagrant project. The 'ssh'
   directory is included in .gitignore file, because we don't want to
   store keys in git.
2. Generate an SSH key pair and place it in the 'ssh' directory.
3. Checks that the following three repos have been cloned to the root of this
   Vagrant project. Note that all files and folders found in the root of this
   project (where the Vagrantfile is located) are shared (bi-directionally) on
   each VM in the /vagrant directory.

indy-node - Shared as /vagrant/indy-node on each VM. Only cli01 (the one client)
    has a symlink (/home/[vagrant|ubuntu]/indy-node -> /vagrant/indy-node) in
    the 'vagrant' and 'ubuntu' home directories. The indy-node repo contains a
    perf_processes.py batch script used for load/stress testing and is used by
    Chaos experiments to generate load when needed.

indy-test-automation - Shared as /vagrant/indy-test-automation on each VM. A
    'cdindy' alias is placed in /home/[vagrant|ubuntu]/.profile for convenience.
    When on client machines (i.e. cli01), running 'cdindy' changes directory to
    /vagrant/indy-test-automation.

    Chaos experiments are found under the 'chaos' directory. This project has a
    'run.py' script capable of running any/all chaos experiments, even in other
    repos (clones present on the same machine). Run 'run.py --help' for details.

sovrin-test-automation - Shared as /vagrant/sovrin-test-automation on each VM. A
    'cdsovrin' alias is placed in /home/[vagrant|ubuntu]/.profile for
    convenience. When on client machines (i.e. cli01), running 'cdsovrin'
    changes directory to /vagrant/sovrin-test-automation.

    Chaos experiments are found under the 'chaos' directory.
