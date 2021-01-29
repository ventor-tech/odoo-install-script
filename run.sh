#!/bin/bash
################################################################################
# Script for installing Odoo on Ubuntu 14.04, 15.04 and 16.04 (could be used for other version too)
# Author: Yenthe Van Ginneken
#-------------------------------------------------------------------------------
# This script will install Odoo on your Ubuntu 14.04 server. It can install multiple Odoo instances
# in one Ubuntu because of the different xmlrpc_ports
#-------------------------------------------------------------------------------
# Make a new file:
# nano odoo-install.sh
# Place this content in it and then make the file executable:
# chmod +x odoo-install.sh
# Execute the script to install Odoo:
# ./odoo-install
################################################################################
 
if [[ $EUID -ne 0 ]]; then
   echo "Script is run as regular user. Odoo will be installed from his name" 
   OE_USER=$(whoami)
   OE_HOME=$HOME
else
   echo "Script is running as root, so creating new odoo user"
   OE_USER="odoo"
   OE_HOME="/opt/$OE_USER"

   echo -e "\n---- Create ODOO system user ----"
   adduser --system --quiet --shell=/bin/bash --home=$OE_HOME --gecos 'ODOO' --group $OE_USER
   #The user should also be added to the sudo'ers group.
   adduser $OE_USER sudo
fi

source conf.sh

export LANGUAGE=en_US.UTF-8
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

#--------------------------------------------------
# Update Server
#--------------------------------------------------
echo -e "\n---- Update Server ----"
sudo apt-get update
sudo apt-get upgrade -y

sudo apt-get install git wget build-essential dnsutils lsb-release software-properties-common sudo -y

source db.sh

source odoo.sh

source initd.sh

# -------------------------------
# INSTALL WEBSERVER SECTION
# -------------------------------

source apache.sh
source nginx.sh

dpkg -b $OE_HOME/odoo_install_$OE_VERSION
sudo dpkg -i $OE_HOME/odoo_install_$OE_VERSION.deb

source cert.sh

source logrotate.sh
# ----------------------------------------------------
# We are done! Let's start Odoo service
# ----------------------------------------------------
echo -e "* Starting Odoo Service"
sudo service $OE_INIT start

echo "-----------------------------------------------------------"
echo "Done! The Odoo server is up and running. Specifications:"
echo "Odoo System User Name: $OE_USER"
echo "Odoo System User Home Directory: $OE_HOME"
echo "Odoo Installation Directory: $OE_INSTALL_DIR"
echo "Odoo Python virtual environment (for python libraries): $OE_INSTALL_DIR/env"
echo "Odoo Configuration File: $OE_CONFIG"
echo "Odoo Logs: $OE_LOG_PATH/odoo-server.log"
echo "Odoo Master Password: $OE_SUPERADMIN"
if [ $WEB_SERVER = "nginx" ]; then
    echo "Nginx Odoo Site: /etc/nginx/sites-available/$OE_WEBSERV_CONF"
fi
if [ $WEB_SERVER = "apache2" ]; then
    echo "Apache Odoo Site: /etc/apache2/sites-available/$OE_WEBSERV_CONF"
fi
if [ $HTTP_PROTOCOL = "https" ] || [ $INSTALL_CERTIFICATE = "True" ]; then
    echo "SSL Certificate File: $SSL_CERTIFICATE"
    echo "SSL Certificate Key File $SSL_CERTIFICATE_KEY"
fi
echo "Protocol: $HTTP_PROTOCOL"
echo "PostgreSQL version: $PG_VERSION"
echo "PostgreSQL User: $OE_DB_USER"
echo "PostgreSQL Password: $OE_DB_PASSWORD"
echo "Start Odoo service: sudo service $OE_INIT start"
echo "Stop Odoo service: sudo service $OE_INIT stop"
echo "Restart Odoo service: sudo service $OE_INIT restart"
echo "-----------------------------------------------------------"
