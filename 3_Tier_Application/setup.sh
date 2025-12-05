#!/bin/bash

sudo apt update 
sudo apt-get install docker.io docker-compose-v2 -y

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker $USER && newgrp docker