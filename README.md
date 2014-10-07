smashNgrab
======

PURPOSE: demonstrate some basic deployment tasks

1. Reference (`reference/`)
2. Deliverables (all else)

##Reference
These scripts are 2 different versions of the same program, one in BASH and the other in Python; they kick-off rather extensive programs. They are samples of my real work from my last employer. It was started in BASH (over 10k LOC) which was later ported to Python (over 12k LOC) when reporting became a requirement mid-stream. I'm fluent in BASH, this part took a few months; as you can see the Python version of this script is much more intense. The constraint was Python version 2.4; as a result, it was written to be independant of any version. I had to work for every bit of the code; this, and subsequent porting, took a year to reproduce.

##Deliverables
These are more of a 'smash-and-grab' nature. A framework of scripts, for immediate action, that were just laying around the house. A Vagrant file was later added to round out the concept.

####Prerequisites
* This has only been tested and verified on Linux and OS X.
  - In principal it should also work on Windows.
* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads).
* Install [Git](http://git-scm.com/book/en/Getting-Started-Installing-Git).
* Install [Vagrant](http://www.vagrantup.com/downloads).

To automatically:
* Provision and boot an OS
* Deploy and secure some apps
* In just a few minutes, follow these steps:

If you are on Windows, you will have to build a Linux VM to see the magic; don't forget to make your user an admin during install. Afterwards, login through the termial (Putty, etc) then:
```
git clone git@github.com:todd-dsm/smashNgrab.git
cd smashNgrab
sudo ./sudo_passwdless.sh
sudo ./setup_env.sh
```

If VirtualBox, Vagrant, Git, and sudo are already setup then just use these steps:
```
vagrant up
vagrant ssh
sudo su -
/vagrant/config.sh | tee -i config_out.log
```
Then, kick back and watch the show; the first time takes less than 10 minutes; subsequent runs about 4 minutes. To get the extended club remix, add `set -x` at the top of `config.sh` and you'll see all the raunchy stuff.

**If you want to reset the test so you can show some co-workers:**
```
exit
exit
vagrant halt
vagrant destroy
```

Then follow from the 'vagrant up' step all over again.


####Tear-down
* Uninstall the programs if they are not a part of your work day.
* Remove the ~/.vagrant.d directory
* That's it.


###POST-GAME
This is the simple version. A far greater method would be to integrate thus:

1. Auto-config bare metal VMs.
2. Install/config the OS (as demo'd here).
3. Prep VMs for automated testing.
4. Deply VMs to any services; EG: VMWare, VirtualBox, Amazon, Google, Rackspace, etc.

All of this without defects. Let me know if I can help.
