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


## Installing CA certificate on OpenBMC

The CA certificate can be installed via Redfish Service. The file `CA-cert.pem`
can not be uploaded directly but must be sent embedded in a valid JSON
string, which requires `\`, `"`, and control characters must be escaped.
This means all content is placed in a single string on a single line by
encoding the line endings as `\n`. The command below prepares a whole POST
body and puts it into a file named: `install_ca.json`.

```
cat << END > install_ca.json
{
  "CertificateString":"$(cat CA-cert.pem | sed -n -e '1h;1!H;${x;s/\n/\\n/g;p;}')",
  "CertificateType": "PEM"
}
END
```

To install the CA certificate on the OpenBMC server post the content of
`install_ca.json` with this command:

Where `${bmc}` should be `bmc.example.com`. It is convenient to export it
as an environment variable.

```
curl --user root:0penBmc -d @install_ca.json -k -X POST https://${bmc}/redfish/v1/Managers/bmc/Truststore/Certificates

```

Credentials `root:0penBmc` can be replaced with any system user name and
password of your choice but with proper access rights to resources used here.


After successful certificate installation you should get positive HTTP
response and a new certificate should be available under this resource
collection.
```
curl --user root:0penBmc -k https://${bmc}/redfish/v1/Managers/bmc/Truststore/Certificates

```

An auto-generated self-signed server certificate is already present on
OpenBMC by default. To use the certificate signed by our CA it must be
replaced. Additionally we must upload to OpenBMC the private key that was
used to sign the server certificate. A proper message mody can be prepared
the with this command:

```
cat << END > replace_cert.json
{
  "CertificateString":"$(cat server-key.pem server-cert.pem | sed -n -e '1h;1!H;${x;s/\n/\\n/g;p;}')",
   "CertificateUri":
   {
      "@odata.id": "/redfish/v1/Managers/bmc/NetworkProtocol/HTTPS/Certificates/1"
   },
  "CertificateType": "PEM"
}
END
```

To replace the server certificate on the OpenBMC server post the content of
`replace_cert.json` with this command:

```
curl --user root:0penBmc -d @replace_cert.json -k -X POST https://${bmc}/redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate/

```

## Enable TLS authentication

To check current state of the TLS authentication method use this command:

```
curl --user root:0penBmc -k https://${bmc}/redfish/v1/AccountService
```
and verify that the attribute `Oem->OpenBMC->AuthMethods->TLS` is set to true.

To enable TLS authentication use this command:

```
curl --user root:0penBmc  -k -X PATCH -H "ContentType:application/json" --data '{"Oem": {"OpenBMC": {"AuthMethods": { "TLS": true} } } }' https://${bmc}/redfish/v1/AccountService
```

To disable TLS authentication use this command:

```
curl --user root:0penBmc  -k -X PATCH -H "ContentType:application/json" --data '{"Oem": {"OpenBMC": {"AuthMethods": { "TLS": false} } } }' https://${bmc}/redfish/v1/AccountService
```

Other authentication methods like basic authentication can be enabled or
disabled as well using the same mechanism. All supported authentication
methods are available under attribute `Oem->OpenBMC->AuthMethods` of the
`/redfish/v1/AccountService` resource.

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
