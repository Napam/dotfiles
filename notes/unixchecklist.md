Append ```bashrc to ```~/.bashrc```

Update everything using alias "update"

Install pygments for ccat alias:
```
sudo apt install python3-pygments
```

Python virtualenvwrapper:
```
mkdir ~/.virtualenv
sudo apt install virtualenv
sudo apt install python3-pip
pip3 install virtualenvwrapper
bashrc should have configuration in it for virtualenvwrapper
```
See https://itnext.io/how-to-set-up-python-virtual-environment-on-ubuntu-20-04-a2c7a192938d

# Python3.10
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.10
sudo apt install python3.10-distutils
curl -sS https://bootstrap.pypa.io/get-pip.py | python3.10

# Maven settings.xml
The settings.xml is for maven and should be placed in ~/.m2/

# Other
How to get all deliberate apt install stuff 
```
(zcat $(ls -tr /var/log/apt/history.log*.gz); cat /var/log/apt/history.log) 2>/dev/null | egrep '^(Start-Date:|Commandline:)' | grep -v aptdaemon | egrep '^Commandline:'
```
