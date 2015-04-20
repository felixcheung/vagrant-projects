#!/bin/bash

echo "== start lgn $(date +'%Y/%m/%d %H:%M:%S')"
STARTTIME=$(date +%s)

# Postgres

# psql password, required to authenticate with Lightning
sudo -u vagrant psql <<EOF
\password
1234
1234
\q
EOF

# [DEMO-only] To allow remote connection
sudo cp /vagrant/postgresql.conf /etc/postgresql/9.3/main/
sudo cp /vagrant/pg_hba.conf /etc/postgresql/9.3/main/
# restart postgresql to pick up config
sudo /etc/init.d/postgresql restart


# Lightning

sudo npm install -gq gulp

pushd /opt
sudo cp /vagrant/lightning.tar.gz ./
sudo tar -xzf lightning.tar.gz
sudo rm -f lightning.tar.gz
sudo cp /vagrant/database.js ./lightning/config/
pushd lightning
sudo npm -q install
sudo gulp build
sudo -u vagrant npm run createdb
sudo -u vagrant npm run migrate

sudo npm start
popd
popd

echo "== end lgn $(date +'%Y/%m/%d %H:%M:%S')"
echo "== $(($(date +%s) - $STARTTIME)) seconds"
