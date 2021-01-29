#!/bin/bash
#--------------------------------------------------
# Install PostgreSQL Server
#--------------------------------------------------

PG_ALREADY_INSTALLED="False"
export OE_DB_PORT
# Let's  first check if postgres already installed
if [ $INSTALL_PG_SERVER = "True" ]; then
    SERVER_RESULT=`sudo -E -u postgres bash -c "psql -X -p $OE_DB_PORT -c \"SELECT version();\""`
    if [ -z "$SERVER_RESULT" ]; then
        echo "No postgres database is installed on port $OE_DB_PORT. So we will install it."
    else
        if [[ $SERVER_RESULT == *"PostgreSQL $PG_VERSION"* ]]; then
            echo "We already have PostgreSQL Server $PG_VERSION installed and running port $OE_DB_PORT. Skipping it's installation."
            PG_ALREADY_INSTALLED="True"
        else
            echo "Version other than PostgreSQL $PG_VERSION Server installed on port $OE_DB_PORT. Make sure that you have configured port correctly. Aborting!"
            exit 1
        fi
    fi
else
    CLIENT_RESULT=`psql -V`
    if [ -z "$CLIENT_RESULT" ]; then
        echo "No PosgreSQL Client installed. Installing it."
    else
        if [[ $CLIENT_RESULT == *"$PG_VERSION"* ]]; then
            echo "We already have PostgreSQL Client version $PG_VERSION. Skipping installation."
            PG_ALREADY_INSTALLED="True"
        else
            echo "Not correct version of PostgreSQL Client installed. Required $PG_VERSION, installed '$CLIENT_RESULT'. We will try to reinstall again."
        fi
    fi
fi

echo -e "\n---- Install PostgreSQL Server ----"
if [ $PG_ALREADY_INSTALLED == "False" ]; then
    sudo apt-get install software-properties-common -y
    sudo add-apt-repository "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -sc)-pgdg main"
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
    sudo apt-get update
fi

if [ $INSTALL_PG_SERVER = "True" ]; then

    export PG_CONF="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
    export PG_HBA="/etc/postgresql/$PG_VERSION/main/pg_hba.conf"

    if [ $PG_ALREADY_INSTALLED == "False" ]; then
        echo -e "\n---- Install PostgreSQL Server ----"
        sudo apt-get install postgresql-$PG_VERSION -y

        # Edit postgresql.conf to change listen address to '*':
        sudo -u postgres sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" "$PG_CONF"

        # Edit postgresql.conf to change port to '$OE_DB_PORT':
        sudo -u postgres sed -i "s/port = 5432/port = $OE_DB_PORT/" "$PG_CONF"
    fi

    # Even if PostgresSQL Server is already installed, we may still want to optimize it for ERP and create DB user.
    export MEM=$(awk '/^MemTotal/ {print $2}' /proc/meminfo)
    export CPU=$(awk '/^processor/ {print $3}' /proc/cpuinfo | wc -l)
    export CONNECTIONS="100"

    # Explicitly set default client_encoding
    sudo -E -u postgres bash -c 'echo "client_encoding = utf8" >> "$PG_CONF"'

    # Explicitly set parameters for ERP/OLTP
    sudo -E -u postgres bash -c 'echo "effective_cache_size = $(( $MEM * 3 / 4 ))kB" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "checkpoint_completion_target = 0.9" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "shared_buffers = $(( $MEM / 4 ))kB" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "maintenance_work_mem = $(( $MEM / 16 ))kB" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "work_mem = $(( ($MEM - $MEM / 4) / ($CONNECTIONS * 3) ))kB" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "random_page_cost = 4         # or 1.1 for SSD" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "effective_io_concurrency = 2 # or 200 for SSD" >> "$PG_CONF"'
    sudo -E -u postgres bash -c 'echo "max_connections = $CONNECTIONS" >> "$PG_CONF"'

    # Now let's create new user
    export OE_DB_USER
    export OE_DB_PASSWORD
 
    # Append to pg_hba.conf to add password auth:
    sudo -E -u postgres bash -c 'echo "host    all             $OE_DB_USER             all                     md5" >> "$PG_HBA"'

    # Restart so that all new config is loaded:
    sudo service postgresql restart

    echo -e "\n---- Creating the ODOO PostgreSQL User  ----"
    sudo -E -u postgres bash -c "psql -X -p $OE_DB_PORT -c \"CREATE USER $OE_DB_USER WITH CREATEDB NOCREATEROLE NOSUPERUSER PASSWORD '$OE_DB_PASSWORD';\""

    # Restart so that all new config is loaded:
    sudo service postgresql restart
else
    echo -e "\n---- Install PostgreSQL Client ----"
    sudo apt-get install postgresql-client-$PG_VERSION -y
fi
