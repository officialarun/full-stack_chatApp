#!/bin/bash
# MongoDB initialization script
set -e

# Update system
apt-get update
apt-get install -y curl wget gnupg2

# Install MongoDB
curl -fsSL https://www.mongodb.org/static/pgp/server-${mongodb_version}.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-archive-keyring.gpg
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-archive-keyring.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/${mongodb_version} multiverse" | tee /etc/apt/sources.list.d/mongodb-org-${mongodb_version}.list
apt-get update
apt-get install -y mongodb-org

# Create data directory and set permissions
mkdir -p /data/db /data/configdb
chown -R mongodb:mongodb /data

# Configure MongoDB
cat > /etc/mongod.conf << EOF
storage:
  dbPath: /data/db
  journal:
    enabled: true

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 0.0.0.0

security:
  authorization: enabled

replication:
  replSetName: rs0
EOF

# Start MongoDB service
systemctl start mongod
systemctl enable mongod

# Initialize replica set
sleep 5
mongo --eval "rs.initiate()" || true

# Create admin user
mongo admin << EOF
db.createUser({
  user: "${root_username}",
  pwd: "${root_password}",
  roles: ["root"]
})
EOF

echo "MongoDB installation completed for ${environment}"
