# Creating an Application in Entra for Terraform/Tofu

## Creating a certificate for the Application in Entra

You should create this outside of the repository.
Then reference the path an password in environment variables.
ARM_CLIENT_CERTIFICATE_PATH=''
ARM_CLIENT_CERTIFICATE_PASSWORD=''

> [!CAUTION]
> Make sure the private key is stored securely!
> Production environments should use a Secret Store like Vault/OpenBao, Azure Key Vault.
> Or OIDC to eliminate the need for long lived secrets for applications.

### With openssl

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

### OR with smallstep

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

## Setting API permissions

```
Application.Read.All
Application.ReadWrite.All
Group.Read.All
Group.ReadWrite.All
Policy.Read.All
Policy.ReadWrite.ConditionalAccess
User.Read.All
User.ReadWrite.All
```
