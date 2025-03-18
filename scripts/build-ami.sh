#!/bin/bash
set -e

# Install necessary dependencies
sudo yum update -y
sudo yum install -y nginx nodejs

# Configure Nginx to proxy requests to Node.js
sudo tee /etc/nginx/nginx.conf > /dev/null <<EOL
events {}
http {
    server {
        listen 80;
        location / {
            proxy_pass http://127.0.0.1:3000;
        }
    }
}
EOL

sudo systemctl enable nginx
sudo systemctl start nginx

# Create a basic Node.js API
mkdir -p /opt/payment-api
tee /opt/payment-api/server.js > /dev/null <<EOL
const http = require('http');
const server = http.createServer((req, res) => {
    res.writeHead(200, {'Content-Type': 'application/json'});
    res.end(JSON.stringify({ status: "Payment Processed", timestamp: new Date().toISOString() }));
});
server.listen(3000);
EOL

# Setup systemd service for Node.js API
tee /etc/systemd/system/payment-api.service > /dev/null <<EOL
[Unit]
Description=Payment Processing API
After=network.target

[Service]
ExecStart=/usr/bin/node /opt/payment-api/server.js
Restart=always
User=nobody
Group=nobody
Environment=PATH=/usr/bin
WorkingDirectory=/opt/payment-api

[Install]
WantedBy=multi-user.target
EOL

sudo systemctl enable payment-api
sudo systemctl start payment-api

# Create AMI
AMI_ID=$(aws ec2 create-image --instance-id i-XXXXXXXXXXXXX --name "payment-api-ami" --no-reboot --query 'ImageId' --output text)
echo "AMI Created: $AMI_ID"
echo $AMI_ID > ami-id.txt
