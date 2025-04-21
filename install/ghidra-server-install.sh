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
  openjdk-17-jre
  # \
  #[PACKAGE_2] \
  #[PACKAGE_3]
msg_ok "Installed Dependencies"

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

./opt/${APPLICATION}/server/svrInstall

msg_ok "Created Service"

motd_ssh
customize

# Cleanup
msg_info "Cleaning up"
rm -f ${TAG}.zip
$STD apt-get -y autoremove
$STD apt-get -y autoclean
msg_ok "Cleaned"
