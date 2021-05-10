#!/bin/bash

url=$1
desired_http_code=$2
curl_http_code=''

declare -A colors;
colors=(\
    ['black']='\E[0;47m'\
    ['red']='\E[0;31m'\
    ['green']='\E[0;32m'\
    ['yellow']='\E[0;33m'\
    ['blue']='\E[0;34m'\
    ['magenta']='\E[0;35m'\
    ['cyan']='\E[0;36m'\
    ['white']='\E[0;37m'\
);

# declare -A status_colors;
# status_colors=(\
#     ['2xx']
# );

until [ "${curl_http_code}" == "${desired_http_code}" ]; do
    curdate=`date "+%D %T"`
    curl_http_code=`curl --connect-timeout 1 -I -A "curls.sh web check (by sz)" -sL --connect-timeout 3 -w "%{http_code}\n" "${url}" -o /dev/null`
    color="black"
    sleep 1
    if [ "${curl_http_code}" -ge "100" ] && [ "${curl_http_code}" -lt "200" ]; then status="Status is 1xx"; color="cyan";   fi
    if [ "${curl_http_code}" -ge "200" ] && [ "${curl_http_code}" -lt "300" ]; then status="Status is 2xx"; color="green";  fi
    if [ "${curl_http_code}" -ge "300" ] && [ "${curl_http_code}" -lt "400" ]; then status="Status is 3xx"; color="blue";   fi
    if [ "${curl_http_code}" -ge "400" ] && [ "${curl_http_code}" -lt "500" ]; then status="Status is 4xx"; color="yellow"; fi
    if [ "${curl_http_code}" -ge "500" ] && [ "${curl_http_code}" -lt "600" ]; then status="Status is 5xx"; color="red";    fi
    # echo -en "${colors[${color}]}${curdate} | STAUS CODE: ${curl_http_code} | URL: ${url}" ; tput sgr0; echo ""
    echo -e "${curdate} | STAUS CODE: ${colors[${color}]}${curl_http_code} $(tput sgr0)| URL: ${url}"
done
