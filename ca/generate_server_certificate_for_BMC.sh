#!/bin/sh
#
# Author - Venkata Chandrappa (Venkata_Chandrappa@phoenix.com)
#
# Purpose - Generate BMC HTTPS certificate
#
#

if  [ $# -lt 1 ]
        then
                echo "\nScript execution requires BMC IP as an argument!"
                echo "\nRun script with required argument(s).\n"
		exit 1
fi

GREEN="\033[1;32m"
RED="\033[1;31m"
NOCOLOR="\033[0m"


############################ 3. Create server certificate signed by given CA certificate ####################################
rm -rf $1
mkdir -p ~/ca/$1

echo "\n${GREEN}*** Generating new Server key and certificate ***${NOCOLOR}\n"
sleep 5
# a. Generate a new key that will be used to sign the server certificate signing request
openssl genrsa -out ~/ca/$1/server-key.pem 2048

# b. Generate a certificate signing request. Provide the fully qualified domain name or IP address of your OpenBMC server for the CommonName attribute of this certificate
openssl req -new -config ~/ca/openssl-server.cnf -key ~/ca/$1/server-key.pem -out ~/ca/$1/signingReqServer.csr\
 -subj "/c=TW/ST=TPE/L=Taipei/O=Phoenix Technologies/OU=ServerBMC/CN=$1"

# c. Sign the certificate using your CA-cert.pem certificate
openssl x509 -req -extensions my_ext_section -extfile ~/ca/myext-server.cnf -days 365 -in ~/ca/$1/signingReqServer.csr\
 -CA ~/ca/CA-cert.pem -CAkey ~/ca/CA-key.pem -CAcreateserial -out ~/ca/$1/server-cert.pem

# The file server-cert.pem now contains a signed client certificate.


########################### 4. Verify server certificate #################################
echo "\n${GREEN}*** Verifying Server certificate ***${NOCOLOR}"
sleep 5
openssl x509 -in ~/ca/$1/server-cert.pem -text -noout
sleep 5


########################### 5. Generate a server certificate with private key embedded ####################################
# a. Private key that was used to sign the server certificate must be uploaded to OpenBMC
echo "\n${GREEN}*** Embedding private key to certificate ***${NOCOLOR}\n"
sleep 5
cat ~/ca/$1/server-key.pem ~/ca/$1/server-cert.pem > ~/ca/$1/server-cert-final.pem

# b. Move CA certificate to IP folder for collective access
echo "\n${GREEN}*** Moving CA certificate and Server certificate to ${RED}$1${GREEN} folder ***${NOCOLOR}\n"
sleep 5
cp ~/ca/CA-cert.pem ~/ca/$1/
ls -l ~/ca/$1/


########################## 6. Verify CA certificate and Server Certficate are ready for OpenBMC usage ######################
echo "\n${GREEN}*** Displaying contents of Server certificate ***${NOCOLOR}\n"
sleep 5
cat ~/ca/$1/server-cert-final.pem
echo "\n${GREEN}*** Verifying CA certificate is usage ready ***${NOCOLOR}\n"
sleep 5
openssl x509 -in ~/ca/$1/CA-cert.pem -text -noout
echo "\n${GREEN}*** Verifying HTTPs Server certificate is usage ready ***${NOCOLOR}\n"
sleep 5
openssl x509 -in ~/ca/$1/server-cert-final.pem -text -noout
echo  "\n${GREEN}*** CA certificate and HTTPs server certificate along with private key are ready for BMC usage. Certificates are located in ${RED}$1${GREEN} folder ***${NOCOLOR}\n"
sleep 2


