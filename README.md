# Netflix CS244 Project

## From VM:
1. Download and install VirtualBox (https://www.virtualbox.org/wiki/Downloads) (you should already have it if you have taken CS 244)
1. Get our disk image here (https://drive.google.com/drive/u/1/folders/0B3JhOxYOciwzamJUS2pTakVwakU), and double click it to import it into VirtualBox
1. Log in to Ubuntu
    * Username: cs244
    * Password: cs244
1. Double click the “live experiment” icon on the desktop, and watch it run for 90 seconds before seeing the charts appear.

If you are running this experiment after June 15th, 2017, we will have disabled the credentials in the VM. Replace them with your own (see below).

It should be noted that we also included an “offline experiment” script that performs the same analysis on logs we captured under pristine network conditions (outside of the VM). These results are closer to the paper’s own results than some of what can be obtained under spotty conditions when running the live experiment in the VM. All data captured is available in the data subdirectory of the experiment code.

### Troubleshooting steps - if the live experiment does not run
* Internet connection - Check that you can connect to the internet on the VM, if you cannot, your Virtual Box configurations may be wrong. Make sure you have two adapters enabled for the image (NAT and host-only, and both have “Cable Connected enabled”).
* Netflix credentials - We will take down the used Netflix credentials after June 15th, 2017 (as stated above); and the account may be throttled before then.
Thus, to replace the credentials, open netflix_and_chill/run_live.sh with your favorite editor to read and replace them with your own as needed.

## From source:

### Instructions

1. run `bundle install` in this directory
2. ...finish instructions

### Running

1. From file:
ruby run_experiment.rb <netflix log file> <packet trace file>
e.g. ruby run_experiment.rb master.log master.cap
2. Live:
ruby run_experiment.rb live <netflix email> <netflix password>


