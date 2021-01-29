#!/bin/bash
# --------------------------------------
# Apache2 installation section
# --------------------------------------
if [ $WEB_SERVER = "apache2" ]; then

echo -e "* Install $WEB_SERVER"
sudo apt-get install -y $WEB_SERVER

echo -e "Configuring Odoo with Apache"

echo -e "* Enable apache modules"
sudo a2enmod proxy 
sudo a2enmod proxy_http 
sudo a2enmod rewrite 
sudo a2enmod headers
sudo a2enmod ssl

echo -e "* Create new site with the following content"

cat <<EOF > $OE_WEBSERV_CONF
<VirtualHost *:80>
    ServerName $DOMAIN_NAME
EOF
for alias in ${DOMAIN_ALIASES[@]} ; do
cat <<EOT >>$OE_WEBSERV_CONF
    ServerAlias $alias
EOT
done
cat <<EOT >>$OE_WEBSERV_CONF

    ServerSignature Off

    ErrorLog \${APACHE_LOG_DIR}/$OE_INIT-error.log
    CustomLog \${APACHE_LOG_DIR}/$OE_INIT-access.log combined

    ProxyRequests Off

    <Proxy *>
        Order deny,allow
        Allow from all
    </Proxy>

    ProxyVia On
    ProxyTimeout 12000
    ProxyPreserveHost On

    ProxyPass /longpolling/ http://127.0.0.1:$OE_LONGPOOL_PORT/longpolling/
    ProxyPassReverse /longpolling/ http://127.0.0.1:$OE_LONGPOOL_PORT/longpolling/

    ProxyPass /webdav/ http://127.0.0.1:$OE_PORT/webdav/
    <Location /webdav/ >
        ProxyPassReverse /webdav/
        <Limit OPTIONS PROPFIND GET REPORT MKACTIVITY PROPPATCH PUT MOVE COPY DELETE LOCK UNLOCK>
            Order Deny,Allow
            Allow from all
            Satisfy Any
        </Limit>
    </Location>

    ProxyPass / http://127.0.0.1:$OE_PORT/

    RequestHeader set "X-Forwarded-Proto" "http"

    # Fix IE problem (httpapache proxy dav error 408/409)
    # SetEnv proxy-nokeepalive 1

    <FilesMatch "\.(cgi|shtml|phtml|php)$">
        SSLOptions +StdEnvVars
    </FilesMatch>

    <Directory /usr/lib/cgi-bin>
        SSLOptions +StdEnvVars
    </Directory>

    BrowserMatch "MSIE [2-6]" \
                 nokeepalive ssl-unclean-shutdown \
                 downgrade-1.0 force-response-1.0
    # MSIE 7 and newer should be able to use keepalive
    BrowserMatch "MSIE [17-9]" ssl-unclean-shutdown

</VirtualHost>
EOT

mkdir -p $OE_AUTO_SCRIPTS_DIR/etc/apache2/sites-available
mv $OE_WEBSERV_CONF $OE_AUTO_SCRIPTS_DIR/etc/apache2/sites-available/

cat <<EOT >>$OE_AUTO_SCRIPTS_DIR/DEBIAN/postinst
echo -e "* Enable site"
a2ensite $OE_WEBSERV_CONF

echo -e "* Disable default sites"
a2dissite default-ssl
a2dissite 000-default

service apache2 reload

exit 0
EOT

fi
