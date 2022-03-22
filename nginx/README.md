# nginx appliance

This appliance is a small immutable nginx routing webserver.
It typically doesn't host any files (although it can), instead
it just terminates SSL and forwards connections to the appropriate hosts
inside the network.

In order to support Let's Encrypt certificates, the `sites-enabled`
will have to forward the `/.well-known/acme-challenge/*` paths to
the machine that controls the keys and can build a new appliance image.

```
        location /.well-known/acme-challenge/ {
                proxy_pass http://safeboot:9090;
        }
```


To rewnew, run 
```
certbot \
  --config-dir local/etc/letsencrypt \
  --logs-dir /tmp/certbot/logs \
  --work-dir /tmp/certbot \
  certonly \
  --standalone \
  --http-01-port 9090 \
  --https-port 9443 \
  -d example.com
```

and then rebuild the nginx image.
