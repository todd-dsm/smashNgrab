InfraGauntlet
======

PURPOSE: InfraGauntlet Test deliverables; 90 minutes.

1. Reference (`reference/`)
2. Deliverables (all else)

##Reference
These are a couple of kick-off scripts; samples of my real work from my last employer. It was started in BASH but that was abondoned for Python when reporting became a requirement mid-stream. I'm fluent in BASH; this part took a few months. T Python version of this script is much more intense. However, I had to work for every bit of the code; this took a year to reproduce.

##Deliverables
These are more of a 'smash-and-grab' nature. A framework of scripts, for immediate action, that were just laying around the house.

A Vagrant file was later added to round out the concept. I could automatically kick it off with `vagrant up` but it wouldn't log the way it's currently implemented. To get the full effect.

```
vagrant up
vagrant ssh
sudo su -
/vagrant/config.sh | tee -i config_out.log
```

If you like you can do a `set -x` in config.sh before staring to get all the raunchy details in the outupt.
