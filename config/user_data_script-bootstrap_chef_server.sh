#!/usr/bin/env bash

# A url directory with the scripts you'd like to stuff into the machine
REMOTE_FILE_URL_BASE="<%= bootstrap_scripts_url_base %>"

# Broaden the apt universe
if grep 'multiverse' /etc/apt/sources.list ; then true ; else
  sed -i 's/universe/multiverse universe/' /etc/apt/sources.list ;
  bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu lucid main restricted"     >> /etc/apt/sources.list ';
  bash -c 'echo "deb http://us.archive.ubuntu.com/ubuntu lucid universe multiverse" >> /etc/apt/sources.list ';
fi

# Update package index and update the basic system files to newest versions
apt-get -y update  ;
apt-get -y upgrade ;
apt-get -f install ;

# base packages
apt-get install -y ruby ruby1.8-dev libopenssl-ruby1.8 rubygems ri irb build-essential wget ssl-cert git-core zlib1g-dev libxml2-dev ;
# unchain rubygems from the tyrrany of ubuntu
gem install --no-rdoc --no-ri rubygems-update --version=1.3.6 ; /var/lib/gems/1.8/bin/update_rubygems; gem update --no-rdoc --no-ri --system ; gem --version ;

# install chef
gem install --no-rdoc --no-ri chef broham configliere ;

# This patches the ec2-set-hostname script to use /etc/hostname (otherwise it
# crams the ec2-assigned hostname in there regardless)
cp /usr/bin/ec2-set-hostname /usr/bin/ec2-set-hostname.`date "+%Y%m%d%H"`.orig ;
wget -nv ${REMOTE_FILE_URL_BASE}/ec2-set-hostname_replacement.py -O /usr/bin/ec2-set-hostname ;
chmod a+x /usr/bin/ec2-set-hostname


# unscrewup the hostname every way I can think of. Rabbitmq is a real buttmunch
# about the hostname -- it will hang forever on bootstrap if `hostname -s`
# doesn't resolve back to this host. One of the following fixes this, not sure which.
export HOSTNAME=<%= hostname %> 
PUBLIC_IP=<%= public_ip %>                 
kill `cat /var/run/dhclient.eth0.pid` # kill dhclient
bash -c "echo '$HOSTNAME' > /etc/hostname" ;
hostname -F /etc/hostname ;
sysctl -w kernel.hostname=`hostname -f` ;
# Your /etc/hosts needs to end up looking like this (order is important):
# 127.0.0.1      chef.YOURDOMAIN.COM chef localhost 
# XXX.XXX.XX.XX  chef.YOURDOMAIN.COM chef
sed -i "s/127.0.0.1 *localhost/127.0.0.1      `hostname -f` `hostname -s` localhost/" /etc/hosts
if grep -q $PUBLIC_IP /etc/hosts  ; then true ; else bash -c "echo '$PUBLIC_IP `hostname -f` `hostname -s `' >> /etc/hosts" ; fi

# # bootstrap chef from *server* scripts
wget -nv ${REMOTE_FILE_URL_BASE}/chef_bootstrap.rb -O /tmp/chef_bootstrap.rb ;
wget -nv ${REMOTE_FILE_URL_BASE}/chef_server.json  -O /tmp/chef_server.json ;
chef-solo -c /tmp/chef_bootstrap.rb -j /tmp/chef_server.json ;

# Make chef server also a client of itself
cp /etc/chef/client.rb /etc/chef/client-orig-`date +%Y%m%d%H`.rb ;
wget -nv ${REMOTE_FILE_URL_BASE}/client.rb -O /etc/chef/client.rb ;

# cleanup
apt-get autoremove;
updatedb;

echo "User data script (chef server bootstrap) complete: `date`"
