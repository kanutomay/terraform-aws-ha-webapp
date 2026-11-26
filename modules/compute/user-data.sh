#!/bin/bash
set -Eeuo pipefail # Exit on error, unset variable, or failed pipe command

# Install Apache service
dnf install -y httpd

# Configure Apache user and group permissions
usermod -a -G apache ec2-user
chown -R ec2-user:apache /var/www

## Get instance ID and Availability Zone
IMDS="http://169.254.169.254"
TOKEN=$(curl --fail --silent --show-error --connect-timeout 2 --max-time 5 \
  -X PUT "$IMDS/latest/api/token" \
  -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")

metadata() {
  curl --fail --silent --show-error --connect-timeout 2 --max-time 5 \
    -H "X-aws-ec2-metadata-token: $TOKEN" \
    "$IMDS/latest/meta-data/$1"
}

INSTANCE_ID=$(metadata instance-id)
AVAILABILITY_ZONE=$(metadata placement/availability-zone)

# Create index.html with instance ID and availability zone
cat > /var/www/html/index.html << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Instance Information</title>
</head>
<body>
    <h1>Instance ID: $INSTANCE_ID</h1>
    <h2>Availability Zone: $AVAILABILITY_ZONE</h2>
</body>
</html>
EOF

# Start and Enable Apache service
systemctl enable --now httpd
