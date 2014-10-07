smashNgrab
======

PURPOSE: demonstrate some basic deployment tasks

1. Reference (`reference/`)
2. Deliverables (all else)

##Reference
These are 2 scripts that kick-off rather extensive programs; they are samples of my real work from my last employer. It was started in BASH (over 10k LOC) which was later ported to Python (over 12k LOC) when reporting became a requirement mid-stream. I'm fluent in BASH, this part took a few months; as you can see the Python version of this script is much more intense. The constraint was Python version 2.4; as a result, it was written to be independant of any version. I had to work for every bit of the code; this, and subsequent porting, took a year to reproduce.

##Deliverables
These are more of a 'smash-and-grab' nature. A framework of scripts, for immediate action, that were just laying around the house. A Vagrant file was later added to round out the concept.

####Prerequisites
* This has only been tested and verified on Linux and OS X.
  - In principal it should also work on Windows.
* Install [VirtualBox](https://www.virtualbox.org/wiki/Downloads) as well.
* Install [Git](http://git-scm.com/book/en/Getting-Started-Installing-Git) as well.
* Install [Vagrant](http://www.vagrantup.com/downloads), if you don't already.

To automatically:
* Provision and boot an OS
* Deploy and secure some apps
* In just a few minutes, follow these steps:

```
git clone git@github.com:todd-dsm/smashNgrab.git
cd smashNgrab
sudo ./sudo_passwdless.sh
sudo ./setup_env.sh
vagrant up
vagrant ssh
sudo su -
/vagrant/config.sh | tee -i config_out.log
```
Then, kick back and watch the show; the first time takes less than 10 minutes; subsequent runs about 4 minutes.
To get the extended club remix, add `set -x` at the top of `config.sh` and you'll see all the raunchy stuff.

**If you want to reset the test so you can show some co-workers:**
```
exit
exit
vagrant halt
vagrant destroy
```

Then follow the first steps all over again.


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
