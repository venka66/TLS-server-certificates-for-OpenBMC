# TLS Server certificates for OpenBMC

## Introduction
Create client and server certificates signed by a CA that can be used to authenticate user requests to an OpenBMC server. 
The guide uses [OpenSSL](https://www.openssl.org/) toolkit to generate CSR requests and certificates that will be used for authentication.

## Certificate generation procedure
Listed below in brief are the steps that need to be done to generate the certificates for TLS on OpenBMC.
For comprehensive information and commands usage, refer [certificate_generate.md](#TLS-server-certificates-for-OpenBMC/certificate_generate.md)
1) [Create a copy and modify the default openssl configuration file.](https://github.com/venka66/TLS-server-certificates-for-OpenBMC/blob/main/certificate_generate.md#prepare-configuration-files)
2) [Create your own SSL certificate authority (CA)](https://github.com/venka66/TLS-server-certificates-for-OpenBMC/blob/main/certificate_generate.md#create-a-new-ca-certificate)
3) [Create a client certificate signed by the CA.](https://github.com/venka66/TLS-server-certificates-for-OpenBMC/blob/main/certificate_generate.md#create-client-certificate-signed-by-given-ca-certificate) The client certificates will be used to authenticate to the OpenBMC without the need of a passsword.
4) [Create a server certificate signed by the CA.](https://github.com/venka66/TLS-server-certificates-for-OpenBMC/blob/main/certificate_generate.md#create-server-certificate-signed-by-given-ca-certificate)
5) [Verify the generated CA, client and server certificates are all valid.](https://github.com/venka66/TLS-server-certificates-for-OpenBMC/blob/main/certificate_generate.md#verify-certificates)

## Install CA and Server Certificates on OpenBMC
Install CA certificate on OpenBMC via any one of the below interfaces
 1) Redfish
 2) BMC web

## Enable TLS authentication for OpenBMC
Ensure TLS authentication is enabled in the BMC.

## Access OpenBMC resources using TLS authentication
If TLS is enabled, valid CA certificate was uploaded and the server
certificate was replaced it should be possible to execute curl requests
using only client certificate, key, and CA like below.

```
curl --cert client-cert.pem --key client-key.pem -vvv --cacert CA-cert.pem https://${bmc}/redfish/v1/SessionService/Sessions
```
## Common mistakes during TLS configuration

* Invalid date and time on OpenBMC,

* Testing Redfish resources, like `https://${bmc}/redfish/v1` which are
always available without any authentication will always result with success,
even when TLS is disabled or certificates are invalid.

* Certificates do not meet the requirements. See paragraphs
[Verify certificates](#Verify-certificates).

* Attempting to load the same certificate twice will end up with an error.
