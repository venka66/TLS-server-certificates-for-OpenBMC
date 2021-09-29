# Generate Certificates

## Pre-requisities to ensure the certificates generated are valid 
For a certificate to be marked as valid, following conditions need to be met.

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

## Prepare configuration files

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

## Create a new CA certificate
First we need to create a private key to sign the CA certificate.
```
openssl genrsa -out CA-key.pem 2048
```

Now we can create a CA certificate, using the previously generated key.
You will be prompted for information which will be incorporated into the
certificate, such as Country, City, Company Name, etc.

```
openssl req -new -config openssl-client.cnf -key CA-key.pem -x509 -days 1000 -out CA-cert.pem
```

## Create client certificate signed by given CA certificate
To create a client certificate, a signing request must be created first. For
this another private key will be needed.

Generate a new key that will be used to sign the certificate signing request:
```
openssl genrsa -out client-key.pem 2048
```
Generate a certificate signing request.

You will be prompted for the same information as during CA generation, but
provide **the OpenBMC system user name**  for the `CommonName` attribute of
this certificate.  In this example, use **root**.

```
openssl req -new -config openssl-client.cnf -key client-key.pem -out signingReqClient.csr
```

Sign the certificate using your `CA-cert.pem` certificate with following
command:
```
openssl x509 -req -extensions my_ext_section -extfile myext-client.cnf -days 365 -in signingReqClient.csr -CA CA-cert.pem -CAkey CA-key.pem -CAcreateserial -out client-cert.pem
```
The file `client-cert.pem` now contains a signed client certificate.

## Create server certificate signed by given CA certificate
For convenience we will use the same CA generated in paragraph [Create a new
CA certificate](#Create-a-new-CA-certificate), although a different one could
be used.

Generate a new key that will be used to sign the server certificate signing
request:
```
openssl genrsa -out server-key.pem 2048
```
Generate a certificate signing request. You will be prompted for the same
information as during CA generation, but provide **the fully qualified
domain name of your OpenBMC server** for the `CommonName` attribute of this
certificate. In this example it will be `bmc.example.com`. A wildcard can
be used to protect multiple host, for example a certificate configured for
`*.example.com` will secure www.example.com, as well as mail.example.com,
blog.example.com, and others.

```
openssl req -new -config openssl-server.cnf -key server-key.pem -out signingReqServer.csr
```

Sign the certificate using your `CA-cert.pem` certificate with following
command:
```
openssl x509 -req -extensions my_ext_section -extfile myext-server.cnf -days 365 -in signingReqServer.csr -CA CA-cert.pem -CAkey CA-key.pem -CAcreateserial -out server-cert.pem
```
The file `server-cert.pem` now contains a signed client certificate.

## Verify certificates
To verify the signing request and both certificates you can use following
commands.

```
openssl x509 -in CA-cert.pem -text -noout
openssl x509 -in client-cert.pem -text -noout
openssl x509 -in server-cert.pem -text -noout
openssl req -in signingReqClient.csr -noout -text
openssl req -in signingReqServer.csr -noout -text
```

Below are example listings that you can compare with your results. Pay special
attention to attributes like:
 * Validity in both certificates,
 * `Issuer` in `client-cert.pem`, it must match to `Subject` in `CA-cert.pem`,
 * Section *X509v3 extensions* in `client-cert.pem` it should contain proper
values,
 * `Public-Key` length, it cannot be less than 2048 bits.
 * `Subject` CN in `client-cert.pem`, it should match existing OpemBMC user
name.
In this example it is **root**.
 * `Subject` CN in `server-cert.pem`, it should match OpemBMC host name.
In this example it is **bmc.example.com **. (see rfc 3280
4.2.1.11 for name constraints)

Below are fragments of generated certificates that you can compare with.
```
CA-cert.pem
    Data:
        Version: 3 (0x2)
        Serial Number:
            44:77:bf:0e:3f:0f:6e:43:41:30:8d:91:1d:05:a1:82:52:f4:64:ed
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = venkapxe
        Validity
            Not Before: Sep 29 03:40:31 2021 GMT
            Not After : Jun 25 03:40:31 2024 GMT
        Subject: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = venkapxe
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:9f:98:d7:ba:8a:d3:5b:18:cb:62:eb:c4:80:c2:
                    ...
                    20:69:1a:e3:f2:e9:71:71:3c:3e:1c:a8:bb:93:4f:
                    8b:dd
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Subject Key Identifier: 
                F5:71:F3:03:79:A2:56:7A:EE:5E:3D:EC:8A:7B:BA:B9:71:5D:D6:34
            X509v3 Authority Key Identifier: 
                keyid:F5:71:F3:03:79:A2:56:7A:EE:5E:3D:EC:8A:7B:BA:B9:71:5D:D6:34

            X509v3 Basic Constraints: critical
                CA:TRUE
    Signature Algorithm: sha256WithRSAEncryption
         40:43:7f:a3:47:65:b4:7e:c1:30:4b:65:7d:e2:03:8d:0b:8b:
         ...
         e9:86:22:4e:dc:61:ad:fc:27:49:1f:76:47:af:b8:cc:73:08:
         e6:ee:e0:bd
```
```
client-cert.pem
    Data:
        Version: 3 (0x2)
        Serial Number: 10150871893861973895 (0x8cdf2434b223bf87)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, ST=California, L=San Francisco, O=Intel, CN=Test CA
        Validity
            Not Before: May 11 11:42:58 2020 GMT
            Not After : May 11 11:42:58 2021 GMT
        Subject: C=US, ST=California, L=San Francisco, O=Intel, CN=root
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:cf:d6:d0:a2:09:62:df:e9:a9:b1:e1:3d:7f:2f:
                    ...
                    30:7b:48:dc:c5:2c:3f:a9:c0:d1:b6:04:d4:1a:c8:
                    8a:51
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage:
                Digital Signature, Key Agreement
            X509v3 Extended Key Usage:
                TLS Web Client Authentication
            X509v3 Authority Key Identifier:
                keyid:ED:FF:80:A7:F8:DA:99:7F:94:35:95:F0:92:74:1A:55:CD:DF:BA:FE

    Signature Algorithm: sha256WithRSAEncryption
         7f:a4:57:f5:97:48:2a:c4:8e:d3:ef:d8:a1:c9:65:1b:20:fd:
         ...
         25:cb:5e:0a:37:fb:a1:ab:b0:c4:62:fe:51:d3:1c:1b:fb:11:
         56:57:4c:6a
```
```
server-cert.pem
    Data:
        Version: 3 (0x2)
        Serial Number: 10622848005881387807 (0x936beffaa586db1f)
    Signature Algorithm: sha256WithRSAEncryption
        Issuer: C=US, ST=z, L=z, O=z, OU=z, CN=bmc.example.com
        Validity
            Not Before: May 22 13:46:02 2020 GMT
            Not After : May 22 13:46:02 2021 GMT
        Subject: C=US, ST=z, L=z, O=z, OU=z, CN=bmc.example.com
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                Public-Key: (2048 bit)
                Modulus:
                    00:d9:34:9c:da:83:c6:eb:af:8f:e8:11:56:2a:59:
                    ...
                    92:60:09:fc:f9:66:82:d0:27:03:44:2f:9d:6d:c0:
                    a5:6d
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage:
                Digital Signature, Key Agreement
            X509v3 Extended Key Usage:
                TLS Web Server Authentication
            X509v3 Authority Key Identifier:
                keyid:5B:1D:0E:76:CC:54:B8:BF:AE:46:10:43:6F:79:0B:CA:14:5C:E0:90

    Signature Algorithm: sha256WithRSAEncryption
         bf:41:e2:2f:87:44:25:d8:54:9c:4e:dc:cc:b3:f9:af:5a:a3:
         ...
         ef:0f:90:a6

```