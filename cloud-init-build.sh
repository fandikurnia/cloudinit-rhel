#! /bin/bash

set -e

# Build and install cloud-init on RHEL 6 AMIs
# (Please note: RHEL5 not supported because python 2.4 is too old for even boto)
# This will have undefined behavior on non-RHEL6 systems but should work on CentOS 6.
# Ubuntu and Amazon already have cloud-init.

# temporary build directory
cd /tmp

# Ensure lsb_release is available on the system
sudo yum -y install redhat-lsb

# not all systems (i.e., Amazon) have lsb_release installed
R=$(lsb_release -rs | cut -f1 -d.)
r=$(lsb_release -rs | cut -f2 -d.)

# download pip from EPEL
# optional if EPEL mirrors already configured-- highly recommended!
# rpm -Uvh http://dl.fedoraproject.org/pub/epel/$R/x86_64/epel-release-$R-$r.noarch.rpm
wget http://dl.fedoraproject.org/pub/epel/$R/x86_64/python-pip-0.8-1.el$R.noarch.rpm

# install needed rhel rpms and pip, bzr is available in epel
yum install -y bzr rpm-build python-devel python-simplejson python-pip*rpm make python-setuptools python-cheetah

# Pull in python deps. Note non-default epel filename for pip
# Please note, this list contains deps that should be installed on the target system
# with pip since we're removing the dependency checks from the RPM below
pip-python install --upgrade  virtualenv argparse boto requests paste prettytable oauth configobj pylint nose mocker PyYAML

# optional, use standard pip name
ln -s /usr/bin/pip-python /usr/bin/pip

# download a temporary copy of cloud-init
bzr branch lp:cloud-init
cd cloud-init

# simple hack to switching configobj to simplejson and work around broken
# dep checks which rely on deps being installed via RPM, using pip instead
# because RHEL5 doesn't support some of the packages
mv Requires Requires.old
echo "simplejson" > Requires
sed -i "s/configobj/simplejson/g" packages/brpm

# make the RPM packages:
# Wrote out redhat package '/tmp/cloud-init/cloud-init-0.7.2-bzr780.el6.noarch.rpm'
# Wrote out redhat package '/tmp/cloud-init/cloud-init-0.7.2-bzr780.el6.src.rpm'
make rpm

# deps already installed via pip (prettytable, oauth not available in EPEL5)

# optional clean-up
sudo yum remove bzr python-cheetah

# If your build system is separate from your AMI image, be sure to:
# 1) install the python packages shown above using pip (or yum)
# 2) create the appropriate config files in /etc/cloud/ based on the templates
#    in /tmp/cloud-init/doc/. (The defaults are for ubuntu, but that's not
#    appropriate on a RHEL platform.) Warning, the defaults will replace your
#    SSH server keys, opening a huge man-in-the-middle attack!)
# 3) rpm -i cloud-init-*.noarch.rpm


