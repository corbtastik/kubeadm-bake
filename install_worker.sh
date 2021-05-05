#!/bin/bash
source functions.sh
init
hostSetup
configIpTables
installDocker
kubeInstall