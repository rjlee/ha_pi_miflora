#!/bin/bash

# Get the image up to date
apt-get update && apt-get dist-upgrade -y

# Install docker
if [ ! -f "/usr/bin/docker" ]; then
    cd /tmp
    curl -fsSL https://get.docker.com -o get-docker.sh
    chmod u+x ./get-docker.sh
    ./get-docker.sh
    docker run hello-world
fi

# Retrieve config
if [ ! -f "/etc/miflora-mqtt-daemon/config.ini" ]; then
  mkdir /etc/miflora-mqtt-daemon
  wget -O /etc/miflora-mqtt-daemon/config.ini https://raw.githubusercontent.com/ThomDietrich/miflora-mqtt-daemon/master/config.ini.dist
fi

# Build docker image
if [ ! -d "/tmp/miflora-mqtt-daemon.git" ]; then
  cd /tmp
  apt-get install git -y
  git clone https://github.com/ThomDietrich/miflora-mqtt-daemon.git
  cd miflora-mqtt-daemon
  # https://github.com/ThomDietrich/miflora-mqtt-daemon/pull/129
  wget -O requirements.txt https://raw.githubusercontent.com/ThomDietrich/miflora-mqtt-daemon/a5cb8baff6f1a82809e7bb9b72f44bb70e16e773/requirements.txt
  docker build -t miflora-mqtt-daemon .
fi

# Add cron entry in case the sensor dies
# Enable auto updates
(
cat <<UPDATEFILE
#!/bin/bash
apt-get update && apt-get dist-upgrade -y && apt autoremove -y
exit 0
UPDATEFILE
) > /etc/cron.daily/auto-update
chmod u+x /etc/cron.daily/auto-update

docker rm -f /miflora-mqtt-daemon
docker run -d --network host --restart unless-stopped --name miflora-mqtt-daemon -v /etc/miflora-mqtt-daemon:/config miflora-mqtt-daemon
