# acme.sh dns api for danish DNS provider gratisdns.dk
## acme.sh_dns_gratisdns

**Author:** Peter Bryde <bryde at bryde dot it>

**Repository:** https://github.com/zylopfa/acme.sh_dns_gratisdns

### What is this?

This is a dns api for use with [acme.sh](https://acme.sh)
It enables you to automatically update gratisdns.dk dns-records for
your domains hosted on their dns servers.


### Instructions

In order for this to work, download and install [acme.sh](https://acme.sh) and copy the
**dns_gratisdns.sh** file into the sub directory **dnsapi**. 

In the shell, you have to export the following

 `export GRATISDNS_Username="LDXXXXXXX"`

 `export GRATISDNS_Password="xxxxxxxxxx"`

Remember to fill in your correct gratisdns username and password in the above.

Then from the main directory issue one of  following commands

#### To issue regular certificate for subdomain
 `./acme.sh --issue -d test.example.com --dns dns_gratisdns --dnssleep 660`

#### To issue wildcard certificate for domain
 `./acme.sh --issue -d '*.example.com' --dns  dns_gratisdns --dnssleep 660`

```
  NB. we use a dnssleep timer of 660 seconds, so we are sure the record has been updated,
  if we use the default dnssleep the dns records will not be updated once they are checked.
```

To renew certificate use the **--renew** flag instead of the **--issue** one

