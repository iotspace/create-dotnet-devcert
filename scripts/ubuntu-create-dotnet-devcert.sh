#!/bin/sh
. ./common.sh

# MY_DIR=$(dirname $(readlink -f $0))
# echo $MY_DIR
# $MY_DIR/common.sh

$SUDO rm /etc/ssl/certs/dotnet-devcert.pem
echo $CRTFILE
$SUDO cp $CRTFILE "/usr/local/share/ca-certificates"
$SUDO update-ca-certificates

cleanup