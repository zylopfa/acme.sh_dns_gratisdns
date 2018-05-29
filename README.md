# acme.sh_dns_gratisdns

**Author:** Peter Bryde <bryde at bryde dot it>
**Repository:** https://github.com/zylopfa/acme.sh_dns_gratisdns

### Instructions

gratisdns.dk is one of the biggest free dns providers in Denmark,
the have a control panel at: https://admin.gratisdns.com .
To create a txt record this module logs in to gratisdns checks if the root domain exist
and then create a txt record with the given content.
The same is the case when deleting a TXT record.
the delete function looks for the given txt content and delete the record with that content.

#### For regular cert for subdomain
 `./acme.sh --issue -d test.example.com --dns dns_gratisdns --dnssleep 660`

#### For wildcard cert
 `./acme.sh --issue -d '*.example.com' --dns  dns_gratisdns --dnssleep 660`

```
  NB. we use a dnssleep timer of 660 seconds, so we are sure the record has been updated,
  if we use the default dnssleep the dns records will not be updated once they are checked.
```

#### Values to export
 `export GRATISDNS_Username="LDXXXXXXX"`
 `export GRATISDNS_Password="xxxxxxxxxx"`


