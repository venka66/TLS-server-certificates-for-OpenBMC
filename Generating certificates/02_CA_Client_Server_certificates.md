### Create a new CA certificate
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

### Create client certificate signed by given CA certificate
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

### Create server certificate signed by given CA certificate
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
