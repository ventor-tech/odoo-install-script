<h3>Installation procedure</h3>
- 1. Download the script:
```
git clone -b All git@git.xpansa.com:external/installscript.git
cd installscript/odoo_install
git checkout All
```
- 2. Modify the parameters as you wish.
There are a few things you can configure, this is the most used list:<br/>
```OE_USER``` will be the username for the system user.<br/>
```OE_HOME``` will be the home directory of the system user.<br/>
```OE_VERSION``` is the Odoo version to install, for example ```10.0``` for Odoo V10.<br/>
```OE_INSTALL_DIR``` is the path where all environment will be installed to.<br/>
```OE_REPO``` is the path where odoo will be clonned to.<br/>
```INSTALL_WKHTMLTOPDF``` set to ```False``` if you do not want to install it, if you want to install it you should set it to ```True```.<br/>
```OE_PORT``` is the port where Odoo should run on, for example 8069.<br/>
```OE_NETRPC_PORT``` is the port where Odoo net-rpc should run on, for example 8070.<br/>
```OE_LONGPOOL_PORT``` is the port where Odoo long pool should run on, for example 8070.<br/>
```IS_ENTERPRISE``` will install the Enterprise version on top of community version if you set it to ```True```, set it to ```False``` if you want the community version of Odoo.<br/>
```OE_SUPERADMIN``` is the master password for this Odoo installation.<br/>
```OE_DB_PASSWORD``` is the password of postgres user.<br/>
```OE_WORKERS``` is the number of Odoo workers
```PG_VERSION``` is a version of postgresql installed

- 3. Become root
```
sudo su
```
- 3. Make the script executable
```
sudo chmod +x run.sh
```
- 4. Execute the script:
```
sudo ./run.sh
```
