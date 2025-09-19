#!/bin/bash

set -e

echo "Setting up overly permissive chmod scenario..."

# Create the user if it doesn't exist (for testing purposes)
if ! id "user" &>/dev/null; then
    sudo useradd -m -s /bin/bash user
    echo "Created user 'user'"
fi

# Ensure we're working with the correct home directory
USER_HOME="/home/user"

# Create typical home directory structure
sudo mkdir -p "$USER_HOME"/{Documents,Downloads,Pictures,Desktop,.ssh,.gnupg}

# Create some sample files in various directories
sudo touch "$USER_HOME/Documents/important_document.txt"
sudo touch "$USER_HOME/Documents/financial_records.xlsx" 
sudo touch "$USER_HOME/Downloads/software_installer.deb"
sudo touch "$USER_HOME/Pictures/family_photo.jpg"
sudo touch "$USER_HOME/.bashrc"
sudo touch "$USER_HOME/.profile"

# Create SSH directory and keys (fake but realistic)
sudo mkdir -p "$USER_HOME/.ssh"
sudo touch "$USER_HOME/.ssh/id_rsa"
sudo touch "$USER_HOME/.ssh/id_rsa.pub"
sudo touch "$USER_HOME/.ssh/authorized_keys"
sudo touch "$USER_HOME/.ssh/known_hosts"

# Add realistic content to the fake SSH private key
sudo tee "$USER_HOME/.ssh/id_rsa" > /dev/null << 'EOF'
-----BEGIN OPENSSH PRIVATE KEY-----
b3BlbnNzaC1rZXktdjEAAAAABG5vbmUAAAAEbm9uZQAAAAAAAAABAAAAlwAAAAdzc2gtcn
NhAAAAAwEAAQAAAIEA1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNO
PQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVW
XYZ1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123456
7890abcdefghijklmnopqrstuvwxyzAAAAAwEAAQAAAIEAwJK9+Gf2J9k=
-----END OPENSSH PRIVATE KEY-----
EOF

# Add content to public key
sudo tee "$USER_HOME/.ssh/id_rsa.pub" > /dev/null << 'EOF'
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1234567890abcdefghijklmnopqrstuvwxyz user@hostname
EOF

# Create GPG directory with proper structure
sudo touch "$USER_HOME/.gnupg/pubring.kbx"
sudo touch "$USER_HOME/.gnupg/trustdb.gpg"

# Set initial proper ownership
sudo chown -R user:user "$USER_HOME"

# Set initially correct permissions (what they should be)
sudo chmod 700 "$USER_HOME/.ssh"
sudo chmod 600 "$USER_HOME/.ssh/id_rsa"
sudo chmod 644 "$USER_HOME/.ssh/id_rsa.pub"
sudo chmod 600 "$USER_HOME/.ssh/authorized_keys"
sudo chmod 644 "$USER_HOME/.ssh/known_hosts"
sudo chmod 700 "$USER_HOME/.gnupg"
sudo chmod 600 "$USER_HOME/.gnupg/"*

# This is the problematic command that creates the security issue
sudo chmod -R 777 "$USER_HOME"