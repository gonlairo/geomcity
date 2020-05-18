#!/bin/sh

GREP_OPTIONS=''

cookiejar=$(mktemp cookies.XXXXXXXXXX)
netrc=$(mktemp netrc.XXXXXXXXXX)
chmod 0600 "$cookiejar" "$netrc"
function finish {
  rm -rf "$cookiejar" "$netrc"
}

trap finish EXIT
WGETRC="$wgetrc"

prompt_credentials() {
    echo "Enter your Earthdata Login or other provider supplied credentials"
    read -p "Username (gonlairo): " username
    username=${username:-gonlairo}
    read -s -p "Password: " password
    echo "machine urs.earthdata.nasa.gov login $username password $password" >> $netrc
    echo
}

exit_with_error() {
    echo
    echo "Unable to Retrieve Data"
    echo
    echo $1
    echo
    echo "https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W001.zip"
    echo
    exit 1
}

prompt_credentials
  detect_app_approval() {
    approved=`curl -s -b "$cookiejar" -c "$cookiejar" -L --max-redirs 2 --netrc-file "$netrc" https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W001.zip -w %{http_code} | tail  -1`
    if [ "$approved" -ne "302" ]; then
        # User didn't approve the app. Direct users to approve the app in URS
        exit_with_error "Please ensure that you have authorized the remote application by visiting the link below "
    fi
}

setup_auth_curl() {
    # Firstly, check if it require URS authentication
    status=$(curl -s -z "$(date)" -w %{http_code} https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W001.zip | tail -1)
    if [[ "$status" -ne "200" && "$status" -ne "304" ]]; then
        # URS authentication is required. Now further check if the application/remote service is approved.
        detect_app_approval
    fi
}

setup_auth_wget() {
    # The safest way to auth via curl is netrc. Note: there's no checking or feedback
    # if login is unsuccessful
    touch ~/.netrc
    chmod 0600 ~/.netrc
    credentials=$(grep 'machine urs.earthdata.nasa.gov' ~/.netrc)
    if [ -z "$credentials" ]; then
        cat "$netrc" >> ~/.netrc
    fi
}

fetch_urls() {
  if command -v curl >/dev/null 2>&1; then
      setup_auth_curl
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        curl -f -b "$cookiejar" -c "$cookiejar" -L --netrc-file "$netrc" -g -o $stripped_query_params -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  elif command -v wget >/dev/null 2>&1; then
      # We can't use wget to poke provider server to get info whether or not URS was integrated without download at least one of the files.
      echo
      echo "WARNING: Can't find curl, use wget instead."
      echo "WARNING: Script may not correctly identify Earthdata Login integrations."
      echo
      setup_auth_wget
      while read -r line; do
        # Get everything after the last '/'
        filename="${line##*/}"

        # Strip everything after '?'
        stripped_query_params="${filename%%\?*}"

        wget --load-cookies "$cookiejar" --save-cookies "$cookiejar" --output-document $stripped_query_params --keep-session-cookies -- $line && echo || exit_with_error "Command failed with error. Please retrieve the data manually."
      done;
  else
      exit_with_error "Error: Could not find a command-line downloader.  Please install curl or wget"
  fi
}

fetch_urls <<'EDSCEOF'
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42E001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41E003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42E002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41E002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41E001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40W001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N41W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N37W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42E003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W004.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43E001.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43E002.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W008.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W009.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W006.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N40E000.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W005.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W003.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N36W007.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N39W010.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N42W010.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N43W010.zip
https://e4ftl01.cr.usgs.gov//ASTER_B/ASTT/ASTGTM.003/2000.03.01/ASTGTMV003_N38W010.zip
EDSCEOF