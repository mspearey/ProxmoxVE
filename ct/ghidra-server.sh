#!/usr/bin/env bash
#git_source="community-scripts/ProxmoxVE/main"
git_source="https://raw.githubusercontent.com/mspearey/ProxmoxVE/refs/heads/feature/ghidra-server"

##source <(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/misc/build.func)
source <(curl -fsSL ${git_source}/misc/build.func)

# Copyright (c) 2021-2025 community-scripts ORG
# Author: mspearey
# License: MIT | https://github.com/community-scripts/ProxmoxVE/raw/main/LICENSE
# Source: https://ghidra-sre.org/

# App Default Values
APP="Ghidra-Server"
# Name of the app (e.g. Google, Adventurelog, Apache-Guacamole"
var_tags="RE"
# Tags for Proxmox VE, maximum 2 pcs., no spaces allowed, separated by a semicolon ; (e.g. database | adblock;dhcp)
var_cpu="1"
# Number of cores (1-X) (e.g. 4) - default are 2
var_ram="2048"
# Amount of used RAM in MB (e.g. 2048 or 4096)
var_disk="10"
# Amount of used disk space in GB (e.g. 4 or 10)
var_os="debian"
# Default OS (e.g. debian, ubuntu, alpine)
var_version="12"
# Default OS version (e.g. 12 for debian, 24.04 for ubuntu, 3.20 for alpine)
var_unprivileged="1"
# 1 = unprivileged container, 0 = privileged container

#VERBOSE="yes"

header_info "$APP"
variables
color
catch_errors

function update_script() {
    header_info
    check_container_storage
    check_container_resources

    # Check if installation is present | -f for file, -d for folder
    if [[ ! -f ["/opt/${APP}"] ]]; then
        msg_error "No ${APP} Installation Found!"
        exit
    fi

    # Crawling the new version and checking whether an update is required
    TAG=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | grep "tag_name" | awk '{print substr($2, 2, length($2)-3) }')
    VERSION=${TAG:7:${#TAG}-13}
    RELEASE=$(curl -fsSL https://api.github.com/repos/NationalSecurityAgency/ghidra/releases/latest | grep "browser_download_url" | awk '{print substr($2, 2, length($2)-2) }')

    if [[ "${VERSION}" != "$(cat /opt/${APP}_version.txt)" ]] || [[ ! -f /opt/${APP}_version.txt ]]; then
        # Stopping Services
        msg_info "Stopping $APP"
        ./opt/${APP}/server/svrUninstall

        msg_ok "Stopped $APP"

        # Creating Backup
        msg_info "Creating Backup"
        tar -czf "/opt/${APP}_backup_$(date +%F).tar.gz" "/opt/${APP}" $REPO_DIR
        msg_ok "Backup Created"

        # Execute Update
        msg_info "Updating $APP to v${VERSION}"
        curl -fsSL -o "${TAG}.zip" "${RELEASE}"
        unzip -q "${TAG}.zip"
        mv "ghidra_${VERSION}_PUBLIC/" "/opt/${APP}"
        msg_ok "Updated $APP to v${RELEASE}"

        # Starting Services
        msg_info "Starting $APP"
        GHIDRA_SVR="./opt/${APP}/server"
        REPO_DIR="/var/lib/${APP}/repositories"
        
        sed -i "s,^ghidra.repositories.dir=./repositories,ghidra.repositories.dir=${REPO_DIR}," ${GHIDRA_SVR}/server.conf
        sed -i "s,^wrapper.app.parameter.2=\${ghidra.repositories.dir},wrapper.app.parameter.2=-u\nwrapper.app.parameter.3=\${ghidra.repositories.dir}," ${GHIDRA_SVR}/server.conf

        $STD ${GHIDRA_SVR}/svrInstall

        msg_ok "Started $APP"

        # Cleaning up
        msg_info "Cleaning Up"
        $STD rm -f ${TAG}.zip
        msg_ok "Cleanup Completed"

        # Last Action
        echo "${VERSION}" >/opt/${APP}_version.txt
        msg_ok "Update Successful"
    else
        msg_ok "No update required. ${APP} is already at v${VERSION}"
    fi
    exit
}

start
build_container
description

msg_ok "Completed Successfully!\n"
echo -e "${CREATING}${GN}${APP} setup has been successfully initialized!${CL}"
echo -e "${INFO}${YW} Access it using the following URL:${CL}"
echo -e "${TAB}${GATEWAY}${BGN}${IP}:13100${CL}"
