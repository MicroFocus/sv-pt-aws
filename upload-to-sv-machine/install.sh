sudo chmod +x *.sh
sudo dnf update
sudo dnf install htop -y
sudo dnf install docker -y
sudo usermod -aG docker ec2-user

# manual Docker Compose installation according to https://docs.docker.com/compose/install/linux/#install-the-plugin-manually
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.20.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

sudo systemctl enable docker
sudo systemctl start docker

# create a service which updates host-data file - it is used to pass host os and other host data to the container
sudo cp create-host-data.service /etc/systemd/system
sudo systemctl enable create-host-data
sudo systemctl start create-host-data
# need to re-login to 