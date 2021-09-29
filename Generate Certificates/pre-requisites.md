# Pre-requisites to complete

## Certificates
For a certificate to be marked as valid, it (and every certificate in the
chain) has to meet these conditions:

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

### Prepare configuration files

To generate certificates with required parameters some modification must be
made to the default openssl configuration file.

First create a new folder named `ca` and create a configuration file using
the default configuration as a template (we do not want to change the
original one). The location of the configuration file may vary depending on
the operating system. For Ubuntu it is usually `/usr/lib/ssl/openssl.cnf`,
but can also can be at `/etc/ssl/openssl.cnf`. For Cygwin it might be
`/etc/defaults/etc/pki/tls/openssl.cnf` or `/etc/pki/tls/openssl.cnf`.

```
mkdir ~/ca
cd ~/ca
cp /usr/lib/ssl/openssl.cnf openssl-client.cnf
```

Then open the client `~/ca/openssl-client.cnf` file in your favorite editor,
for example `vi`.

```
vi ~/ca/openssl-client.cnf
```

Find the sections listed below and add or choose the presented values.

```
[ req ]
req_extensions = v3_req

[ usr_cert ]
extendedKeyUsage = clientAuth

[ v3_req ]
extendedKeyUsage = clientAuth
keyUsage = digitalSignature, keyAgreement
```

Now create a server configuration `openssl-server.cnf` by copying the client
file

```
cp ~/ca/openssl-client.cnf openssl-server.cnf
```

and changing values presented in the sections listed below.

```
[ usr_cert ]
extendedKeyUsage = serverAuth

[ v3_req ]
extendedKeyUsage = serverAuth
```

Create two additional configuration files `myext-client.cnf` and
`myext-server.cnf` for the client and server certificates respectively.
Without these files no extensions are added to the certificate.

```
cat << END > myext-client.cnf
[ my_ext_section ]
keyUsage = digitalSignature, keyAgreement
extendedKeyUsage = clientAuth
authorityKeyIdentifier = keyid
END
```
```
cat << END > myext-server.cnf
[ my_ext_section ]
keyUsage = digitalSignature, keyAgreement
extendedKeyUsage = serverAuth
authorityKeyIdentifier = keyid
END
```
