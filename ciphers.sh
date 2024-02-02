#!/usr/bin/env bash
    
# OpenSSL requires the port number.
SERVER=$1
if [ -n "$2" ]; then CIPHER=$2 ; fi
DELAY=5
    
function checkCipher () {
  echo -n Testing $1...
  result=$(echo -n | openssl s_client -cipher "$1" -connect $SERVER 2>&1)
  if [[ "$result" =~ ":error:" ]] ; then
    error=$(echo -n $result | cut -d':' -f6)
    echo NO \($error\)
  else
    if [[ "$result" =~ "Cipher is ${1}" || "$result" =~ "Cipher    :" ]] ; then
      echo YES
    else
      echo UNKNOWN RESPONSE
      echo $result
    fi
  fi
}

if [ -n "$CIPHER" ] ; then
checkCipher $CIPHER
else
  echo Obtaining cipher list from $(openssl version).
  ciphers=$(openssl ciphers 'ALL:eNULL' | sed -e 's/:/ /g')
  for cipher in ${ciphers[@]}
  do
    checkCipher $cipher
    sleep $DELAY
  done
fi
