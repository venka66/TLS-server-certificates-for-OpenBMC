# TLS Server certificates for OpenBMC

## Introduction
Create client and server certificates signed by a CA that can be used to authenticate user requests to an OpenBMC server. 
The guide uses [OpenSSL](https://www.openssl.org/) toolkit to generate CSR requests and certificates that will be used for authentication.

## Certificate generation procedure
Listed below in brief are the steps that need to be done to generate the certificates for TLS on OpenBMC.
For comprehensive information and commands usage, refer [certificate_generate.md](#TLS-server-certificates-for-OpenBMC/certificate_generate.md)
[Create a copy and modify the default openssl configuration file.](#TLS-server-certificates-for-OpenBMC/certificate_generate.md#Pre-requisities to ensure the certificates generated are valid)
2) [Create your own SSL certificate authority (CA)]
3) [Create a client certificate signed by the CA.] The client certificates will be used to authenticate to the OpenBMC without the need of a passsword.
4) [Create a server certificate signed by the CA.]
5) [Verify CA, client and server certificates generated are all valid.]

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
