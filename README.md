# TLS Server certificates for OpenBMC

## Introduction
With help of this guidebook you should be able to create both client and
server certificates signed by a CA that can be used to authenticate user
requests to an OpenBMC server. You will also learn how to enable and test
the OpenBMC TLS authentication.

## Ensuring a certificate is valid
For a certificate to be marked as valid, the following conditions have to be met:

* `KeyUsage` contains required purpose `digitalSignature` and `keyAgreement`
(see rfc 3280 4.2.1.3)
* `ExtendedKeyUsage` contains required purpose `clientAuth` for client
certificate and `serverAuth` for server certificate (see rfc 3280 4.2.1.13)
* public key meets minimal bit length requirement
* certificate has to be in its validity period
* `notBefore` and `notAfter` fields have to contain valid time
* has to be properly signed by certificate authority
* certificate is well-formed according to X.509
* issuer name has to match CA's subject name for client certificate
* issuer name has to match the fully qualified domain name of your OpenBMC
host

If you already have certificates you can skip to [Enable TLS authentication
](#Enable-TLS-authentication) or go to [Verify certificates](#Verify-certificates)
and check if they meet the above requirements.

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
