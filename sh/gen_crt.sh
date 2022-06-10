openssl genrsa -out ca.key 2048
openssl req -new -x509 -key ca.key -out ca.crt -days 7300
openssl genrsa -out server.key 2048
openssl req -new -key server.key -out server.csr
openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt -days 3650

openssl x509 -req -in esxi.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out esxi.crt -days 3650

```
[server]
hostname=192.168.1.230
port=5696
certificate_path=/etc/pykmip/certs/server.crt
key_path=/etc/pykmip/certs/server.key
ca_path=/etc/pykmip/certs/ca.crt
auth_suite=TLS1.2
policy_path=/etc/pykmip/policies
database_path=/etc/pykmip/pykmip.db
enable_tls_client_auth=true
tls_cipher_suites=
    TLS_ECDH_ECDSA_WITH_AES_128_CBC_SHA256
    AES128-SHA256
    TLS_RSA_WITH_AES_256_CBC_SHA256
    AES256-SHA256
logging_level=DEBUG
```