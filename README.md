# TLS Server certificates for OpenBMC

## Introduction
Create client and server certificates signed by a CA that can be used to authenticate user requests to an OpenBMC server. 
The guide uses [OpenSSL](https://www.openssl.org/) toolkit to generate CSR requests and certificates that will be used for authentication.

## Steps needed to create the files
    1) Create a copy and modify the default openssl configuration file.

    2) Create two additional configuration files for the client and server certificates respectively. Without these files no extensions are added to the certificate.

    3) Create your own SSL certificate authority (CA)

    4) Create a client certificate signed by the CA. The client certificates will be used to authenticate to the OpenBMC without the need of a passsword.

    5) Create a server certificate signed by the CA.

    6) Verify CA, client and server certificates generated are all valid.

    7) Install CA certificate on OpenBMC via any one of the below interfaces
      a) Redfish
      b) BMC web

    8) Ensure TLS authentication is enabled in the BMC.

    9) Access OpenBMC resources using TLS authentication method.

## Using TLS to access OpenBMC resources

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

* Not having phosphor-bmcweb-cert-config in the build.
