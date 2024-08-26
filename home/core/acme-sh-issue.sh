#!/usr/bin bash
/usr/local/bin/--issue --server $CA --dns dns_cf -d $DOMAIN

ln -sfr /acme.sh/**/fullchain.cer /acme.sh/certificate.pem
ln -sfr /acme.sh/**/*.key /acme.sh/certificate.key
