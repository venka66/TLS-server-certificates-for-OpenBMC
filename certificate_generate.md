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
        Serial Number:
            75:69:98:f0:ce:7e:f9:5e:e2:5c:a0:f0:85:92:10:dc:4c:6d:b7:b3
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = venkapxe
        Validity
            Not Before: Sep 29 03:40:36 2021 GMT
            Not After : Sep 29 03:40:36 2022 GMT
        Subject: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = root
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:d9:b6:57:79:a5:2d:b0:d9:46:df:31:37:39:7e:
                    ...
                    9e:23:22:ac:28:a6:77:6a:92:ca:6a:f0:ab:7e:ea:
                    52:f5
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: 
                Digital Signature, Key Agreement
            X509v3 Extended Key Usage: 
                TLS Web Client Authentication
            X509v3 Authority Key Identifier: 
                keyid:F5:71:F3:03:79:A2:56:7A:EE:5E:3D:EC:8A:7B:BA:B9:71:5D:D6:34

    Signature Algorithm: sha256WithRSAEncryption
         08:25:de:00:d1:4b:15:9b:3d:3d:f1:c5:d2:46:55:99:8d:e6:
         ...
         86:84:c3:1e:eb:9b:f6:d6:4c:52:dc:ca:d9:2b:98:74:29:71:
         9a:8e:b3:9b

```
```
server-cert.pem
  Data:
        Version: 3 (0x2)
        Serial Number:
            75:69:98:f0:ce:7e:f9:5e:e2:5c:a0:f0:85:92:10:dc:4c:6d:b7:b6
        Signature Algorithm: sha256WithRSAEncryption
        Issuer: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = venkapxe
        Validity
            Not Before: Sep 29 05:21:58 2021 GMT
            Not After : Sep 29 05:21:58 2022 GMT
        Subject: ST = TPE, L = Taipei, O = Phoenix Technologies, OU = ServerBMC, CN = 10.122.168.233
        Subject Public Key Info:
            Public Key Algorithm: rsaEncryption
                RSA Public-Key: (2048 bit)
                Modulus:
                    00:ab:cd:8f:ab:dc:68:c3:c8:23:f5:ae:fb:99:11:
                    ...
                    a2:fc:3f:98:50:7b:d1:4d:e0:23:ca:28:80:e5:a1:
                    ec:4f
                Exponent: 65537 (0x10001)
        X509v3 extensions:
            X509v3 Key Usage: 
                Digital Signature, Key Agreement
            X509v3 Extended Key Usage: 
                TLS Web Server Authentication
            X509v3 Authority Key Identifier: 
                keyid:F5:71:F3:03:79:A2:56:7A:EE:5E:3D:EC:8A:7B:BA:B9:71:5D:D6:34

    Signature Algorithm: sha256WithRSAEncryption
         2c:13:5c:b5:38:ed:89:71:02:ba:c0:b8:26:1b:ad:bf:47:53:
         ...
         9d:a8:b6:52:25:3b:91:17:ce:ca:2c:f6:c0:6a:ce:15:70:2d:
         da:f3:77:d2

```
