#!/bin/bash
#--------------------------------------------------
# ----- Creating debian installation file with all neccessary configs
#--------------------------------------------------

OE_AUTO_SCRIPTS_DIR=$OE_HOME/odoo_install_$OE_VERSION
rm -R $OE_AUTO_SCRIPTS_DIR
mkdir $OE_AUTO_SCRIPTS_DIR

# ---------------------------
# Build Debian package
# ---------------------------
mkdir -p $OE_AUTO_SCRIPTS_DIR/DEBIAN
cat <<EOF > $OE_AUTO_SCRIPTS_DIR/DEBIAN/control
Package: $OE_INIT
Version: $OE_PORT
Architecture: all
Maintainer: Odoo S.A. <info@odoo.com>
Section: net
Priority: optional
Homepage: http://www.odoo.com/
Description: Odoo description
EOF

cat <<EOF > $OE_AUTO_SCRIPTS_DIR/DEBIAN/postinst
#!/bin/sh

set -e

ODOO_CONFIGURATION_FILE=$OE_CONFIG
ODOO_GROUP=$OE_USER
ODOO_DATA_DIR=$OE_HOME
ODOO_LOG_DIR=$OE_LOG_PATH
ODOO_USER=$OE_USER

# Configuration file
chown \$ODOO_USER:\$ODOO_GROUP \$ODOO_CONFIGURATION_FILE
chmod 0640 \$ODOO_CONFIGURATION_FILE
# Log
chown \$ODOO_USER:\$ODOO_GROUP \$ODOO_LOG_DIR
chmod 0750 \$ODOO_LOG_DIR
# Data dir
chown \$ODOO_USER:\$ODOO_GROUP \$ODOO_DATA_DIR
# Different scripts
chown root:root /etc/init.d/$OE_INIT
chmod 755 /etc/init.d/$OE_INIT

update-rc.d $OE_INIT defaults

EOF

chmod 755 $OE_AUTO_SCRIPTS_DIR/DEBIAN/postinst

#--------------------------------------------------
# Adding init.d script
#--------------------------------------------------


echo -e "* Create init file"
cat <<EOF > $OE_INIT
#!/bin/sh
### BEGIN INIT INFO
# Provides: $OE_INIT
# Required-Start: \$remote_fs \$syslog
# Required-Stop: \$remote_fs \$syslog
# Should-Start: \$network
# Should-Stop: \$network
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start odoo daemon at boot time
# Description:       Enable service provided by daemon.
# X-Interactive:     true
### END INIT INFO
PATH=/sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
VIRTENV=$OE_INSTALL_DIR/env/bin/python
DAEMON=$OE_REPO/$OE_BIN
NAME=$OE_INIT
DESC=$OE_INIT
# Specify the user name (Default: odoo).
USER=$OE_USER
CONFIGFILE="${OE_CONFIG}"
# pidfile
PIDFILE=/var/run/\${NAME}.pid
# Additional options that are passed to the Daemon.
DAEMON_OPTS="-c \$CONFIGFILE"
[ -x \$DAEMON ] || exit 0
[ -f \$CONFIGFILE ] || exit 0
checkpid() {
[ -f \$PIDFILE ] || return 1
pid=\`cat \$PIDFILE\`
[ -d /proc/\$pid ] && return 0
return 1
}
case "\${1}" in
start)
echo -n "Starting \${DESC}: "
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$VIRTENV \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
stop)
echo -n "Stopping \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
echo "\${NAME}."
;;
restart|force-reload)
echo -n "Restarting \${DESC}: "
start-stop-daemon --stop --quiet --pidfile \$PIDFILE \
--oknodo
sleep 10
start-stop-daemon --start --quiet --pidfile \$PIDFILE \
--chuid \$USER --background --make-pidfile \
--exec \$VIRTENV \$DAEMON -- \$DAEMON_OPTS
echo "\${NAME}."
;;
*)
N=/etc/init.d/\$NAME
echo "Usage: \$NAME {start|stop|restart|force-reload}" >&2
exit 1
;;
esac
exit 0
EOF

echo -e "* Security Init File"
mkdir -p $OE_AUTO_SCRIPTS_DIR/etc/init.d/
mv $OE_INIT $OE_AUTO_SCRIPTS_DIR/etc/init.d/$OE_INIT
