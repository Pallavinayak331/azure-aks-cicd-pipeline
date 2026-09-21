#!/bin/bash
# Run this ON the Dev-VM (after SSH-ing in)
set -e

sudo apt update
sudo apt install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker azure-dev-user

sudo apt install -y git

echo "Docker and Git installed. Log out and back in for the docker group to apply."
