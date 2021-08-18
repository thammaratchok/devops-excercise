#!/bin/bash
set -euo pipefail

if [ "$(id -u)" != "0" ]; then
    exec sudo "$0" "$@"
fi

apt-get update
apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --batch --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update
# Install docker
apt-get install -y docker-ce docker-ce-cli containerd.io
usermod -aG docker admin

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Clone the repo and deploy containers
su admin
git clone https://github.com/thammaratchok/devops-excercise.git
cd devops-excercise/devops-test && docker-compose up --build  -d
