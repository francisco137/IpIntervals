#!/bin/bash

#this script runs inside container created inside minikube

ROOT_DIR=$(cd "$(dirname "$0")" ; pwd -P)
cd $ROOT_DIR

/etc/init.d/postgresql stop

sed -i "s!#listen_addresses = 'localhost'!listen_addresses = '*'    !" /etc/postgresql/${PG_VERSION}/main/postgresql.conf
sed -i "s!data_directory = '/var/lib/postgresql/${PG_VERSION}/main'!data_directory = '/data/postgresql/${PG_VERSION}/main' #!" /etc/postgresql/${PG_VERSION}/main/postgresql.conf
sed -i "s#host    all             all             127.0.0.1/32            md5#host    all             all             127.0.0.1/32            md5\nhost    all             all             192.168.0.1/0           md5#" /etc/postgresql/${PG_VERSION}/main/pg_hba.conf

if [ ! -d /data/postgresql/${PG_VERSION} ] ; then

  echo "Initialization, please wait..."

  chmod 755 /data/postgresql
  mkdir -p /data/postgresql/${PG_VERSION}/main
  cp -r /var/lib/postgresql/${PG_VERSION}/main/* /data/postgresql/${PG_VERSION}/main/
  chown -R postgres:postgres /data/postgresql
  chmod 700 -R /data/postgresql/${PG_VERSION}/main

  /etc/init.d/postgresql restart
  sleep 3

  su - postgres -c "psql -c \"CREATE USER root SUPERUSER;\" postgres"
  su - postgres -c "psql -c \"ALTER USER root PASSWORD 'root';\" postgres"

  su - postgres -c "psql -c \"CREATE USER ${PG_USER} SUPERUSER;\" postgres"
  su - postgres -c "psql -c \"ALTER USER ${PG_USER} PASSWORD '${PG_PASS}';\" postgres"
  su - postgres -c "psql -c \"DROP DATABASE ${PG_BASE};\" postgres"
  su - postgres -c "psql -c \"CREATE DATABASE ${PG_BASE} OWNER ${PG_USER};\" postgres"

  su - postgres -c "psql ${PG_BASE} < /home/francisco/francisco.sql"
  su - postgres -c "psql ${PG_BASE} < /home/francisco/francisco_test_data.sql"

fi

/etc/init.d/postgresql restart
sleep 3

while (true) ; do sleep 10; echo "."; done;
