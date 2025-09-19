#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Define the project directory
PROJECT_DIR=~/teamchat

echo "Updating package list and installing Node.js + npm..."
# Update package list and install Node.js and npm
echo password | sudo -S apt-get install -y npm

# Create directory if it doesn't exist
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

echo "Downloading project files..."
# Download files from Pastebin
curl -o server.js https://raw.githubusercontent.com/christykl/backbench/refs/heads/main/privacy/4_server.js
curl -o index.html https://raw.githubusercontent.com/christykl/backbench/refs/heads/main/privacy/4_index.html
curl -o package.json https://raw.githubusercontent.com/christykl/backbench/refs/heads/main/privacy/4_package.json

echo "Installing npm dependencies..."
# Install dependencies from package.json
echo password | sudo -S npm install

echo "Starting the server..."
# Start the server in the background and log output
nohup node server.js > server.log 2>&1 &
echo "Server started in background. Logs: $PROJECT_DIR/server.log"