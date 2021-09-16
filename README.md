# create-dotnet-devcert

A simple script that creates and trusts a self-signed development certificate for dotnet on Ubuntu and Arch based distributions.

## What does the script do

The script uses openssl to create a self-signed certificate. The certificate will then be imported and trusted at:

- System certificates - to enable service-to-service communication
- User nssdb - to trust the certificate in supported application like Chromium or Microsoft Edge
- Snap Chromium nssdb - to trust the certificate in Chromium if installed via snap
- Snap Postman nssdb - to trust the certificate in Postman if installed via snap

In addition the certificate will be imported into dotnet so that it will be used as a development certificate in ASP.NET Core.

## Prerequisites

- dotnet-sdk (Version >= 5.0)
- libnss3-tools (install via `sudo apt install libnss3-tools` or `sudo pacman -S nss`)

## Usage

Simply run the script needed for your distribution.
```
chmod +x common.sh
chmod +x ubuntu-create-dotnet-devcert.sh
./ubuntu-create-dotnet-devcert.sh
```

Ubuntu based distributions:
```
sudo ./scripts/ubuntu-create-dotnet-devcert.sh
```

Arch based distributions:
```
`./scripts/arch-create-dotnet-devcert`
```
## More info

More information about this can be found on my blog post [https://blog.wille-zone.de/post/aspnetcore-devcert-for-ubuntu](https://blog.wille-zone.de/post/aspnetcore-devcert-for-ubuntu).

I also captures the self-signed certificate in many articles in to here you can read for more details
* 

# Extra steps to check and verify again

```
# Clean all HTTPS development certificates
sudo dotnet dev-certs https --clean

# Goto the generated certs tmp folder
cd /var/tmp/localhost-dev-cert

# Import PFX cert again (must use SUDO)
sudo dotnet dev-certs https --clean --import dotnet-devcert.pfx -p ""

# Verify cert using CA file (failed if the cert is not trusted)
openssl verify -CAfile dotnet-devcert.crt dotnet-devcert.crt

# remove previous trusted certificate
sudo rm /etc/ssl/certs/dotnet-devcert.pem

# copy the new cert
cp dotnet-devcert.crt "/usr/local/share/ca-certificates"

# update to trust cert
sudo update-ca-certificates

# check the pem file is generated
ls /etc/ssl/certs/dotnet-devcert.pem

# verify cert not using CAfile option
openssl verify dotnet-devcert.crt
```