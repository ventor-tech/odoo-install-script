#!/bin/bash
# ---------------------------------------------------
# NGINX RELATED SECTION
# --------------------------------------------------

if [ $WEB_SERVER = "nginx" ]; then

echo -e "* Install $WEB_SERVER"
sudo apt-get install -y $WEB_SERVER

echo -e "Configuring Odoo with Nginx"

domains="$DOMAIN_NAME"
for alias in ${DOMAIN_ALIASES[@]} ; do
    domains="$domains $alias"
done

cat <<EOF > $OE_WEBSERV_CONF
# odoo server
upstream $OE_WEBSERVER_HOST {
 server 127.0.0.1:$OE_PORT;
}
upstream chat_$OE_WEBSERVER_HOST {
 server 127.0.0.1:$OE_LONGPOOL_PORT;
}

server {
 server_name $domains;
 listen 80;

 proxy_read_timeout 720s;
 proxy_connect_timeout 720s;
 proxy_send_timeout 720s;

 # Add Headers for odoo proxy mode
 proxy_set_header X-Forwarded-Host \$host;
 proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
 proxy_set_header X-Forwarded-Proto \$scheme;
 proxy_set_header X-Real-IP \$remote_addr;

 # log
 access_log /var/log/nginx/$OE_INIT.access.log;
 error_log /var/log/nginx/$OE_INIT.error.log;

 # Redirect requests to odoo backend server
 location / {
   proxy_redirect off;
   proxy_pass http://$OE_WEBSERVER_HOST;
 }
 location /longpolling {
     proxy_pass http://chat_$OE_WEBSERVER_HOST;
 }

 # Specifies the maximum accepted body size of a client request,
 # as indicated by the request header Content-Length.
 client_max_body_size 200m;

 # common gzip
 gzip_types text/css text/less text/plain text/xml application/xml application/json application/javascript;
 gzip on;
}
EOF

mkdir -p $OE_AUTO_SCRIPTS_DIR/etc/nginx/sites-available/
mv $OE_WEBSERV_CONF $OE_AUTO_SCRIPTS_DIR/etc/nginx/sites-available/

cat <<EOT >>$OE_AUTO_SCRIPTS_DIR/DEBIAN/postinst
echo -e "* Enable site"
ln -f -s /etc/nginx/sites-available/$OE_WEBSERV_CONF /etc/nginx/sites-enabled/$OE_WEBSERV_CONF

echo -e "* Disable default sites"
rm -f /etc/nginx/sites-enabled/default

service nginx reload

exit 0

EOT

fi
