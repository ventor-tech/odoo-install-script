#!/bin/bash
#--------------------------------------------------
# Install Dependencies
#--------------------------------------------------
if [ $OE_VERSION = "10.0" ] || [ $OE_VERSION = "11.0" ] || [ $OE_VERSION = "12.0" ] || [ $OE_VERSION = "13.0" ] || [ $OE_VERSION = "14.0" ]; then
    OE_BIN="odoo-bin"
else
    OE_BIN="openerp-server"
fi

echo -e "\n---- Python Dependencies ----"

if [ $PYTHON_VERSION = "3" ]; then
#----------------- Python 3 ------------------
    if [ $(which python3.6) ] || [ $(which python3.7) ] || [ $(which python3.8) ]; then
        sudo apt-get install -y python3-pip python3-dev python3-setuptools python3-venv
    else
        echo "System has wrong python version! Odoo supports only 3.6+ python"
        exit 1
    fi
    

else
#------------------ Python 2 -------------------
    sudo apt-get install -y python-dev python-virtualenv python-setuptools python-pip
fi

echo -e "\n---- Odoo Web Dependencies ----"

sudo apt-get install -y nodejs npm
sudo apt-get install -y node-less node-clean-css

sudo npm install -g less less-plugin-clean-css

#--------------------------------------------------
# Install Wkhtmltopdf if needed
#--------------------------------------------------

INSTALL_WKHTMLTOPDF_VERSION=`wkhtmltopdf --version`
if [ $INSTALL_WKHTMLTOPDF = "True" ] && [ -z "$INSTALL_WKHTMLTOPDF_VERSION" ]; then
  echo -e "\n---- Install wkhtml and place shortcuts on correct place for ODOO $OE_VERSION ----"

  OS_RELEASE=`lsb_release -sc`
  if [ "`getconf LONG_BIT`" == "64" ];then
      _url=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_RELEASE"_amd64.deb
  else
      _url=https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.5/wkhtmltox_0.12.5-1."$OS_RELEASE"_i386.deb
  fi
  wget $_url
  sudo dpkg -i `basename $_url`
  sudo apt-get install -f -y
else
  echo "Wkhtmltopdf isn't installed due to the choice of the user!"
fi

  
echo -e "\n---- Create Log directory ----"
mkdir -p $OE_LOG_PATH

#--------------------------------------------------
# Install ODOO
#--------------------------------------------------
if [ ! -d "$OE_REPO" ]; then
    echo -e "\n==== Installing ODOO Server ===="
    git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/odoo $OE_REPO/
fi
if [ ! -d "$OE_INSTALL_DIR/env" ]; then
    echo -e "* Create virtualenv"
    if [ $PYTHON_VERSION = "3" ]; then
        python3 -m venv $OE_INSTALL_DIR/env
    else
        virtualenv $OE_INSTALL_DIR/env
    fi
fi

source $OE_INSTALL_DIR/env/bin/activate
sudo apt-get install libicu-dev libpq-dev libxml2-dev libxslt1-dev libsasl2-dev libldap2-dev libssl-dev zlib1g-dev -y
pip install --upgrade pip

if [[ -f $OE_REPO/requirements.txt ]]; then
    echo "Installing from $OE_REPO/requirements.txt with pip."
    if [ $PYTHON_VERSION = "3" ]; then
        pip3 install -r $OE_REPO/requirements.txt
    else
        pip install -r $OE_REPO/requirements.txt
    fi
fi

if [ $IS_ENTERPRISE = "True" ]; then
    if [ ! -d "$OE_INSTALL_DIR/enterprise/addons" ]; then
        # Odoo Enterprise install!
        mkdir -p $OE_INSTALL_DIR/enterprise/addons

        echo -e "\n---- Adding Enterprise code under $OE_HOME/enterprise/addons ----"
        git clone --depth 1 --branch $OE_VERSION https://www.github.com/odoo/enterprise "$OE_INSTALL_DIR/enterprise/addons"
    fi
fi
if [ ! -d "$OE_INSTALL_DIR/all_addons" ]; then
    echo -e "\n---- Create custom module directory ----"
    mkdir -p $OE_INSTALL_DIR/all_addons
fi

if [ ! -f "$OE_CONFIG" ]; then
    echo -e "* Create server config file"

cat <<EOF > $OE_CONFIG
[options]
admin_passwd = $OE_SUPERADMIN
db_host = $OE_DB_HOST
db_port = $OE_DB_PORT
db_user = $OE_DB_USER
db_password = $OE_DB_PASSWORD
addons_path = $OE_ADDONS_PATH
data_dir = $OE_HOME/.local/share/odoo$OE_VERSION
log_level = info
logfile = $OE_LOG_PATH/odoo-server.log
syslog = False
log_handler = ["[':INFO']"]
xmlrpc = True
xmlrpc_interface = 127.0.0.1
xmlrpc_port = $OE_PORT
netrpc = True
netrpc_interface = 127.0.0.1
netrpc_port = $OE_NETRPC_PORT
longpolling_port = $OE_LONGPOOL_PORT
workers = $OE_WORKERS
limit_time_cpu = 1200
limit_time_real = 1200
limit_request = 1200
proxy_mode = True
EOF

fi

if [[ $EUID -eq 0 ]]; then
   echo -e "\n---- Setting permissions on home folder as we are executing script as a root----"
   chown -R $OE_USER:$OE_USER $OE_HOME
fi
