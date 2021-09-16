# Reference
* https://docs.microsoft.com/en-us/dotnet/core/additional-tools/self-signed-certificates-guide

# With OpenSSL

Create working folder
```
mkdir dev-certs
cd dev-certs
```

Run the bash
```
PARENT="localhost"
echo ${PARENT}
openssl req \
-x509 \
-newkey rsa:4096 \
-sha256 \
-days 365 \
-nodes \
-keyout $PARENT.key \
-out $PARENT.crt \
-subj "/CN=${PARENT}" \
-extensions v3_ca \
-extensions v3_req \
-config <( \
  echo '[req]'; \
  echo 'default_bits= 4096'; \
  echo 'distinguished_name=req'; \
  echo 'x509_extension = v3_ca'; \
  echo 'req_extensions = v3_req'; \
  echo '[v3_req]'; \
  echo 'basicConstraints = CA:FALSE'; \
  echo 'keyUsage = nonRepudiation, digitalSignature, keyEncipherment'; \
  echo 'subjectAltName = @alt_names'; \
  echo '[ alt_names ]'; \
  echo "DNS.1 = www.${PARENT}"; \
  echo "DNS.2 = ${PARENT}"; \
  echo '[ v3_ca ]'; \
  echo 'subjectKeyIdentifier=hash'; \
  echo 'authorityKeyIdentifier=keyid:always,issuer'; \
  echo 'basicConstraints = critical, CA:TRUE, pathlen:0'; \
  echo 'keyUsage = critical, cRLSign, keyCertSign'; \
  echo 'extendedKeyUsage = serverAuth, clientAuth')

openssl x509 -noout -text -in $PARENT.crt
```

To get a .pfx, use the following command:
```
openssl pkcs12 -export -out $PARENT.pfx -inkey $PARENT.key -in $PARENT.crt

Enter Export Passowrd: localhost
```

The `.aspnetcore 3.1` example will use `.pfx` and a password. Starting with the `.net 5 runtime`, Kestrel can also take `.crt` and PEM-encoded `.key` files.

# Linux Trusting certificate
* https://stackoverflow.com/questions/55485511/how-to-run-dotnet-dev-certs-https-trust

Verify cert should yield localhost.crt: OK
```
openssl verify -CAfile localhost.crt localhost.crt
```

==============================================
# How to run 'dotnet dev-certs https --trust'?
* https://stackoverflow.com/questions/55485511/how-to-run-dotnet-dev-certs-https-trust

**Workaround:** (tested on Openssl 1.1.1c)

1. manually generate self-signed cert
2. trust this cert
3. force your application to use this cert

**In detail:**

## 1. manually generate self-signed cert:

* create localhost.conf file with the following content:

```
[req]
default_bits       = 2048
default_keyfile    = localhost.key
distinguished_name = req_distinguished_name
req_extensions     = req_ext
x509_extensions    = v3_ca

[req_distinguished_name]
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_default          = localhost
commonName_max              = 64

[req_ext]
subjectAltName = @alt_names

[v3_ca]
subjectAltName = @alt_names
basicConstraints = critical, CA:false
keyUsage = keyCertSign, cRLSign, digitalSignature,keyEncipherment

[alt_names]
DNS.1   = localhost
DNS.2   = 127.0.0.1
```
* generate cert using :
```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout localhost.key -out localhost.crt -config localhost.conf
```
* convert cert to pfx using:
```
openssl pkcs12 -export -out localhost.pfx -inkey localhost.key -in localhost.crt
```
* (optionally) verify cert using :
```
openssl verify -CAfile localhost.crt localhost.crt
```
which should yield `localhost.crt: OK`
* as it's not trusted yet using `openssl verify localhost.crt` should fail with
```
CN = localhost
error 18 at 0 depth lookup: self signed certificate
error localhost.crt: verification failed
```

## 2. trust this cert:

* copy localhost.crt to /usr/local/share/ca-certificates
```
sudo cp localhost.crt /usr/local/share/ca-certificates
```
* trust the certificate using :
```
sudo update-ca-certificates
```
* verify if the cert is copied to `/etc/ssl/certs/localhost.pem` (extension changes)
```
ls /etc/ssl/certs/localhost.pem
```
* verifying the cert without the CAfile option should work now
```
$ openssl verify localhost.crt 
localhost.crt: OK
```

## 3. force your application to use this cert

update your `appsettings.json` with the following settings:
```
"Kestrel": {
  "Certificates": {
    "Default": {
      "Path": "localhost.pfx",
      "Password": ""
    }
  }
}
```


## 4. delete trust certificates

```
sudo rm /usr/local/share/ca-certificates/localhost.crt
sudo rm /etc/ssl/certs/localhost.pem
sudo update-ca-certificates
ls /etc/ssl/certs/localhost.pem
openssl verify localhost.crt 
```

===

**For Chrome:**

* Click "Not Secure" in address bar.
* Click Certificate.
* Click Details.
* Click Export -> `{FILE_NAME}`

Run: 
```
sudo apt-get update       
sudo apt-get install libnss3-tools
sudo certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n {FILE_NAME} -i {FILE_NAME}

sudo certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n /home/tvt/workspace/ubuntu/dev-certs/localhost -i /home/tvt/workspace/ubuntu/dev-certs/localhost
```
Restart Chrome.

=============
# Linux Cert Management
* https://chromium.googlesource.com/chromium/src/+/refs/heads/main/docs/linux/cert_management.md

List all certificates
```
certutil -d sql:$HOME/.pki/nssdb -L
```
Delete a certificate
```
certutil -d sql:$HOME/.pki/nssdb -D -n <certificate nickname>

certutil -d sql:$HOME/.pki/nssdb -D -n /home/tvt/workspace/ubuntu/dev-certs/localhost
```

Note: to trust a self-signed server certificate, we should use
```
certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n <certificate nickname> \
-i <certificate filename>

certutil -d sql:$HOME/.pki/nssdb -A -t "P,," -n tvt-devcert \
-i localhost.crt
```


==============
# ASP.NET Core dev-cert for Ubuntu
* https://blog.wille-zone.de/post/aspnetcore-devcert-for-ubuntu
* https://github.com/BorisWilhelms/create-dotnet-devcert
* https://github.com/iotspace/create-dotnet-devcert
* https://stackoverflow.com/questions/55485511/how-to-run-dotnet-dev-certs-https-trust

While the answer provided by @chrsvdb is helpful it does not solve all problems. I still had issue with service-to-service communication (HttpClient - PartialChain error) and also you must reconfigure Kestrel to use your own certificate. It is possible to create a self-signed certificate and import it to the .NET SDK. All you need is to specify the `1.3.6.1.4.1.311.84.1.1` extension in the certificate.

After that the cert can be imported into .NET Core SDK and trusted. Trusting in Linux is a bit hard as each application can have it's own certificate store. E.g. Chromium and Edge use nssdb which can be configured with `certutil` as described John Duffy. Unfortunately the location to the nssdb maybe different when you install application as snap. Then each application has its own database. E.g. for Chromium Snap the path will be `$HOME/snap/chromium/current/.pki/nssdb`, for Postman Snap the will be `$HOME/snap/postman/current/.pki/nssdb` and so on.

Therefor I have created a script which generates the cert, trusts it for Postman Snap, Chmromium Snap, current user nssdb and on system level. It also imports the script into the .NET SDK so it will be used by ASP.NET Core without changing the configuration. You can find more informations about the script in my blog post `https://blog.wille-zone.de/post/aspnetcore-devcert-for-ubuntu`

# Prerequisites
* dotnet-sdk (Version >= 5.0)
* libnss3-tools (install via `sudo apt install libnss3-tools` or `sudo pacman -S nss`)

# Usage
Simply run the script needed for your distribution.

Ubuntu based distributions: `./scripts/ubuntu-create-dotnet-devcert`

Arch based distributions: `./scripts/arch-create-dotnet-devcert`

# Turning
```
$ sudo ./ubuntu-create-dotnet-devcert2.sh
Generating a RSA private key
........................................................................................+++++
..........................................................................+++++
writing new private key to '/var/tmp/localhost-dev-cert/dotnet-devcert.key'
-----

Welcome to .NET 5.0!
---------------------
SDK Version: 5.0.401

Telemetry
---------
The .NET tools collect usage data in order to help us improve your experience. It is collected by Microsoft and shared with the community. You can opt-out of telemetry by setting the DOTNET_CLI_TELEMETRY_OPTOUT environment variable to '1' or 'true' using your favorite shell.

Read more about .NET CLI Tools telemetry: https://aka.ms/dotnet-cli-telemetry

----------------
Installed an ASP.NET Core HTTPS development certificate.
To trust the certificate run 'dotnet dev-certs https --trust' (Windows and macOS only).
Learn about HTTPS: https://aka.ms/dotnet-https
----------------
Write your first app: https://aka.ms/dotnet-hello-world
Find out what's new: https://aka.ms/dotnet-whats-new
Explore documentation: https://aka.ms/dotnet-docs
Report issues and find source on GitHub: https://github.com/dotnet/core
Use 'dotnet --help' to see available commands or visit: https://aka.ms/dotnet-cli
--------------------------------------------------------------------------------------
HTTPS development certificates successfully removed from the machine.
The certificate was successfully imported.
rm: cannot remove '/etc/ssl/certs/dotnet-devcert.pem': No such file or directory
Updating certificates in /etc/ssl/certs...
1 added, 0 removed; done.
Running hooks in /etc/ca-certificates/update.d...
done.
```