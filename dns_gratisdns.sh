#!/usr/bin/env sh

# Author: Peter Bryde <bryde at bryde dot it>
# Repository: https://github.com/zylopfa
#
# Instructions:
#
#   gratisdns.dk is one of the biggest free dns providers in Denmark, 
#   the have a control panel at: https://admin.gratisdns.com .
#   To create a txt record this module logs in to gratisdns checks if the root domain exist
#   and then create a txt record with the given content.
#   The same is the case when deleting a TXT record.
#   the delete function looks for the given txt content and delete the record with that content.
#
#   For regular cert for subdomain:
#     ./acme.sh --issue -d test.example.com --dns dns_gratisdns --dnssleep 660
#   For wildcard cert:
#     ./acme.sh --issue -d '*.example.com' --dns  dns_gratisdns --dnssleep 660
#
#   NB. we use a dnssleep timer of 660 seconds, so we are sure the record has been updated,
#   if we use the default dnssleep the dns records will not be updated once they are checked.
#
#   Values to export:
#     export GRATISDNS_Username="LDXXXXXXX"
#     export GRATISDNS_Password="xxxxxxxxxx"

GRATISDNS_API="https://admin.gratisdns.com"


# Usage: add  _acme-challenge.www.domain.com   "XKrxpRBosdIKFzxW_CT3KLZNf6q0HG9i01zxXp5CPBs"
# Used to add txt record
dns_gratisdns_add() { 

  fulldomain=$1
  txtvalue=$2

  GRATISDNS_Username="${GRATISDNS_Username:-$(_readaccountconf_mutable GRATISDNS_Username)}"
  GRATISDNS_Password="${GRATISDNS_Password:-$(_readaccountconf_mutable GRATISDNS_Password)}"
  if [ -z "$GRATISDNS_Username" ] || [ -z "$GRATISDNS_Password" ]; then
    GRATISDNS_Username=""
    GRATISDNS_Password=""
    _err "You didn't specify gratisdns username and password."
    _err "Please specify and try again."
    return 1
  fi

  GRATISDNS_COOKIE="$(_gratisdns_login "$GRATISDNS_Username" "$GRATISDNS_Password")"

  # split our full domain name into two parts...
  i="$(echo "$fulldomain" | tr '.' ' ' | wc -w)"
  i="$(_math "$i" - 1)"
  top_domain="$(echo "$fulldomain" | cut -d. -f "$i"-100)"
  i="$(_math "$i" - 1)"
  sub_domain="$(echo "$fulldomain" | cut -d. -f -"$i")"

  _debug "top_domain: $top_domain"
  _debug "sub_domain: $sub_domain"

  _H1="Cookie: $GRATISDNS_COOKIE"
  htmlpage="$(_get "${GRATISDNS_API}/?action=dns_primarydns")"
  
  if ! _contains "$htmlpage" "$top_domain"; then
    _err "The top domain $top_domain is not registered under this gratisdns account ($GRATISDNS_Username)"
    return 1
  fi

  acmeDomain="${sub_domain}.${top_domain}"

  editurl="$GRATISDNS_API/?action=dns_primary_record_add_txt&user_domain=$top_domain"

  htmlpage="$(_post "action=dns_primary_record_added_txt&name=$(printf '%s' "$acmeDomain" | _url_encode)&ttl=300&txtdata=$(printf '%s' "$txtvalue" | _url_encode)&user_domain=$(printf '%s' "$top_domain" | _url_encode)" "$editurl")"

  _debug "edit url: $editurl"

}

# Usage: fulldomain txtvalue
# Used to remove the txt record after validation
dns_gratisdns_rm() { 
  fulldomain=$1
  txtvalue=$2

  GRATISDNS_Username="${GRATISDNS_Username:-$(_readaccountconf_mutable GRATISDNS_Username)}"
  GRATISDNS_Password="${GRATISDNS_Password:-$(_readaccountconf_mutable GRATISDNS_Password)}"
  if [ -z "$GRATISDNS_Username" ] || [ -z "$GRATISDNS_Password" ]; then
    GRATISDNS_Username=""
    GRATISDNS_Password=""
    _err "You didn't specify gratisdns username and password."
    _err "Please specify and try again."
    return 1
  fi

  GRATISDNS_COOKIE="$(_gratisdns_login "$GRATISDNS_Username" "$GRATISDNS_Password")"

  # split our full domain name into two parts...
  i="$(echo "$fulldomain" | tr '.' ' ' | wc -w)"
  i="$(_math "$i" - 1)"
  top_domain="$(echo "$fulldomain" | cut -d. -f "$i"-100)"
  i="$(_math "$i" - 1)"
  sub_domain="$(echo "$fulldomain" | cut -d. -f -"$i")"

  _debug "top_domain: $top_domain"
  _debug "sub_domain: $sub_domain"

  _H1="Cookie: $GRATISDNS_COOKIE"
  htmlpage="$(_get "${GRATISDNS_API}/?action=dns_primarydns")"

  if ! _contains "$htmlpage" "$top_domain"; then
    _err "The top domain $top_domain is not registered under this gratisdns account ($GRATISDNS_Username)"
    return 1
  fi

  acmeDomain="${sub_domain}.${top_domain}"

  htmlpage="$(_get "${GRATISDNS_API}/?action=dns_primary_changeDNSsetup&user_domain=$(printf '%s' "$top_domain" | _url_encode)")"

  if ! _contains "$htmlpage" "$txtvalue"; then
    _err "The TXT value $txtvalue has not been found in the dns record"
    return 1
  fi

  recordId=$(echo "$htmlpage" | tr '\r\n' ' ' | grep -oP ">${txtvalue}.*?action=dns_primary_delete_txt&id=[0-9]*" | grep -o 'action=dns_primary_delete_txt&id=[0-9]*' | grep -o '[0-9]*' | tr -d '\r\n' )
  _debug "Record ID is: |$recordId|"

  htmlpage="$(_get "${GRATISDNS_API}/?action=dns_primary_delete_txt&id=$recordId&user_domain=$(printf '%s' "$top_domain" | _url_encode)")"

  if ! _contains "$htmlpage" "Record was deleted"; then
    _err "The TXT record with value $txtvalue has not been deleted!"
    return 1
  fi

}




####################  Private functions below ##################################


# usage: _gratisdns_login username password
# print string "cookie=value"
# return 0 success

_gratisdns_login() {

  username="$1"
  password="$2"

  htmlpage="$(_post "login=$(printf '%s' "$username" | _url_encode)&password=$(printf '%s' "$password" | _url_encode)&action=logmein" "$GRATISDNS_API")"
  cookies="$(grep -i '^Set-Cookie.*ORGID.*$' "$HTTP_HEADER" | _head_n 1 | tr -d "\r\n" | cut -d " " -f 2)"

  _H1="Cookie: $cookies"
  htmlpage="$(_get "$GRATISDNS_API")"

  if ! _contains "$htmlpage" "$GRATISDNS_Username"; then
    _err "Gratis DNS login failed for user $username"
    return 1
  fi

  if [ -z "$cookies" ]; then
    _debug3 "htmlpage: $htmlpage"
    _err "Gratis DNS login failed for user $username. check $HTTP_HEADER file"
    return 1
  fi

  printf "%s" "$cookies"
  return 0

}

