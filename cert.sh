#!/bin/bash
# ------------------------------------------------------
# Certificates installation section
# ------------------------------------------------------
echo -e "Install certificate when required"

if [ $INSTALL_CERTIFICATE = "True" ] && [ ! -z "$DOMAIN_NAME" ]; then

    #--------------------------------------------------
    # Install Libraries needed for let's encrypt
    #--------------------------------------------------
    sudo apt-get install -y dnsutils dirmngr git wget

    # Check if domain is reachable
    PUBLIC_IP=`dig +short myip.opendns.com @resolver1.opendns.com`
    REACHED_IP=`dig $DOMAIN_NAME A +short`
    if [[ $REACHED_IP == $PUBLIC_IP ]]; then
        INSTALL_CERTIFICATE="True"
    else
        INSTALL_CERTIFICATE="False"
        echo "IMPORTANT! Skipping certificate installation, as it is not possible to resolve domain ${DOMAIN_NAME} to IP ${PUBLIC_IP}"
    fi

    if [ $INSTALL_CERTIFICATE = "True" ]; then
        sudo add-apt-repository "deb http://ftp.debian.org/debian $(lsb_release -sc)-backports main"
        sudo apt-get update

        domains="-d $DOMAIN_NAME"
        for alias in ${DOMAIN_ALIASES[@]} ; do
            domains="$domains -d $alias"
        done
        if [ $WEB_SERVER = "apache2" ] ; then
            echo -e "Configuring certificate with Apache"
            sudo apt-get install python-certbot-apache -y
            sudo certbot --apache $domains  --non-interactive --agree-tos --redirect -m $LE_EMAIL
        fi

        if [ $WEB_SERVER = "nginx" ] ; then
            echo -e "Configuring certificate with Nginx"
            sudo apt-get install python-certbot-nginx -y
            sudo certbot --nginx $domains  --non-interactive --agree-tos --redirect -m $LE_EMAIL
        fi
    fi
fi