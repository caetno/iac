# Creating a certificate for the Application in Entra

## With openssl

```
umask 077

openssl req -x509 -newkey rsa:3072 -sha256 \
  -days 365 -nodes \
  -subj "/CN=tofu-lab" \
  -keyout tofu.key \
  -out tofu.crt

openssl pkcs12 -export \
  -inkey tofu.key \
  -in tofu.crt \
  -out tofu.pfx
```

## OR with smallstep

```
umask 077

step certificate create tofu-lab tofu.crt tofu.key \
  --profile self-signed \
  --subtle \
  --kty RSA \
  --size 3072 \
  --not-after 8760h \
  --no-password \
  --insecure

step certificate p12 tofu.pfx tofu.crt tofu.key
```
