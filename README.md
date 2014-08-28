smashNgrab
======

PURPOSE: demonstrate some basic deployment tasks

1. Reference (`reference/`)
2. Deliverables (all else)

##Reference
These are a couple of kick-off scripts; samples of my real work from my last employer. It was started in BASH but that was abondoned for Python when reporting became a requirement mid-stream. I'm fluent in BASH; this part took a few months. The Python version of this script is much more intense. The constraint was Python version 2.4; as a result, it was written to be independant of any version. I had to work for every bit of the code; this, and subsequent porting, took a year to reproduce.

##Deliverables
These are more of a 'smash-and-grab' nature. A framework of scripts, for immediate action, that were just laying around the house. A Vagrant file was later added to round out the concept.

####Prerequisites
* This has only been tested and verified on Linux and OS X.
  - In principal it should also work on Windows.
* Install [Vagrant](http://www.vagrantup.com/downloads), if you don't already.
* Install [Git](http://git-scm.com/book/en/Getting-Started-Installing-Git) as well.

To automatically:
* Provision and boot an OS
* Deploy and secure some apps
* In just a few minutes, follow these steps:

```
git clone git@github.com:todd-dsm/smashNgrab.git
cd smashNgrab
vagrant up
vagrant ssh
sudo su -
/vagrant/config.sh | tee -i config_out.log
```
Then, kick back and watch the show.

To get the extended club remix, add `set -x` at the top of `config.sh` and you'll see all the raunchy stuff.
