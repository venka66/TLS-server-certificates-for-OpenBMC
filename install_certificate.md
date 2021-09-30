# Certificate install/replacement on OpenBMC

### Installing CA certificate on OpenBMC via Redfish

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
curl --user root:password -d @install_ca.json -k -X POST https://${bmc}/redfish/v1/Managers/bmc/Truststore/Certificates

```

Credentials `root:password` can be replaced with any system user name and
password of your choice but with proper access rights to resources used here.


After successful certificate installation you should get positive HTTP
response and a new certificate should be available under this resource
collection.
```
curl --user root:password -k https://${bmc}/redfish/v1/Managers/bmc/Truststore/Certificates

```
### Replacing HTTPs certificate on OpenBMC via Redfish
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
curl --user root:password -d @replace_cert.json -k -X POST https://${bmc}/redfish/v1/CertificateService/Actions/CertificateService.ReplaceCertificate/

```

