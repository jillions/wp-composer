#!/bin/bash

set -xe

#Variables
PROJECT_NAME="template-wpengine/pipelines"

WP_DEV_SSH="devInstall@devInstall.ssh.wpengine.net"
WP_DEV_INSTALL="devInstall"
WP_DEV_URL="devInstall.wpengine.com"

WP_STG_SSH="stgInstall@stgInstall.ssh.wpengine.net"
WP_STG_INSTALL="stgInstall"
WP_STG_URL="stgInstall.wpengine.com"

WP_PRD_SSH="prdInstall@prdInstall.ssh.wpengine.net"
WP_PRD_INSTALL="prdInstall"
WP_PRD_URL="prdInstall.wpengine.com"
WP_PRD_WWW_URL="prdInstall.wpengine.com"

#DO NOT CHANGE - DYNAMICALLY SOURCED FROM GITHUB ACTIONS
pwd="pwd"
REPO_NAME="gitRepoName"
BRANCH="gitBranchName"