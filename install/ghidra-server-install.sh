#!/usr/bin/env bash

# Copyright (c) 2021-2025 community-scripts ORG
# Author: mspearey
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghidra-sre.org/

# Import Functions und Setup
source /dev/stdin <<< "$FUNCTIONS_FILE_PATH"
color
verb_ip6
catch_errors
setting_up_container
network_check
update_os

# Installing Dependencies
msg_info "Installing Dependencies"
$STD apt-get install -y \
#  openjdk-17-jre
  # \
  #[PACKAGE_2] \
  #[PACKAGE_3]
msg_ok "Installed Dependencies"

msg_info "Setting up TemurinJDK"
mkdir -p /etc/apt/keyrings
curl -fsSL "https://packages.adoptium.net/artifactory/api/gpg/key/public" | tee /etc/apt/keyrings/adoptium.asc
echo "deb [signed-by=/etc/apt/keyrings/adoptium.asc] https://packages.adoptium.net/artifactory/deb $(awk -F= '/^VERSION_CODENAME/{print$2}' /etc/os-release) main" | tee /etc/apt/sources.list.d/adoptium.list
$STD apt-get update
$STD apt-get install -y temurin-21-jdk
sudo update-alternatives --set java /usr/lib/jvm/temurin-21-jdk-amd64/bin/java
msg_ok "Installed TemurinJDK"

# Setup App
msg_info "Setup ${APPLICATION}"
#Ghidra_11.3.2_build
TAG=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
VERSION=${TAG:7:${#TAG}-13}
RELEASE=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | grep "browser_download_url" | awk '{print substr($2, 2, length($2)-2) }')
curl -fsSL -o "${TAG}.zip" "${RELEASE}"
unzip -q "${TAG}.zip"
mv "ghidra_${VERSION}_PUBLIC/" "/opt/${APPLICATION}"
# 
# 
#
echo "${VERSION}" >/opt/${APPLICATION}_version.txt
msg_ok "Setup ${APPLICATION}"

# Creating Service (if needed)
msg_info "Creating Service"
#cat <<EOF >/etc/systemd/system/${APPLICATION}.service
#[Unit]
#Description=${APPLICATION} Service
#After=network.target

#[Service]
#ExecStart=[START_COMMAND]
#Restart=always

#[Install]
#WantedBy=multi-user.target
#EOF
#systemctl enable -q --now ${APPLICATION}

$GHIDRA_SVR="./opt/${APPLICATION}/server"
$REPO_DIR=" /var/lib/${APPLICATION}/repositories"

sed -i "s/^ghidra.repositories.dir=.\/repositories/ghidra.repositories.dir=${REPO_DIR}/" $GHIDRA_SVR/server.conf
sed -i "s/^wrapper.app.parameter.2=\${ghidra.repositories.dir}/wrapper.app.parameter.2=-u\nwrapper.app.parameter.3=\${ghidra.repositories.dir}/" $GHIDRA_SVR/server.conf

$GHIDRA_SVR/svrInstall

$GHIDRA_SVR/svrAdmin -add root

msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f ${TAG}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
