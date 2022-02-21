#!/bin/bash
#!/usr/bin/env bash

curlopts=( --silent --fail --max-time 10 --stderr /dev/null )
keyfile='https://raw.githubusercontent.com/bitcoin/bitcoin/master/contrib/builder-keys/keys.txt'
pubring='pubring.kbx' #may be trustedkeys.kbx on some systems

if [ ! -e SHA256SUMS ] || [ ! -e SHA256SUMS.asc ]; then
  echo "missing SHA256SUMS/SHA256SUMS.asc files"
  echo "download from https://bitcoincore.org/en/download/"
  exit 1
fi

if ! keys=$(curl "${curlopts[@]}" $keyfile); then
  echo 'error fetching keys from github'
  exit 1
fi

#uncomment to update keys, but do it only if you clearly understand what are you doing
#while read -r KEY NAME; do
#  if ! gpg --list-key "$KEY" &>/dev/null; then
#    echo "trying to import $KEY $NAME"
#    if ! gpg --keyserver hkps://keys.openpgp.org --recv-keys "$KEY" &>/dev/null; then
#      gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys "$KEY" &>/dev/null
#    fi
#  fi
#done <<<"$keys"

#clean up expired keys
while read -r KEY; do
  echo "deleting expired key $KEY"
  gpg --batch --yes --delete-keys "$KEY" &>/dev/null
done < <(gpg --list-keys --with-colons | awk -F: '$1=="pub" && $2~"[er]" { print $5 }')

#goodsigs=$(gpgv --keyring $pubring --quiet SHA256SUMS.asc SHA256SUMS 2>&1 | grep -c '^gpgv: Good signature')
#if (( goodsigs > 0 )); then
#  echo "SHA256SUMS passed verification (found $goodsigs good signatures)"
#  sha256sum -c --ignore-missing <SHA256SUMS
#else
#  echo "SHA256SUMS did not pass verification!"
#fi
echo "Good signatures of SHA256SUMS:"
gpgv --keyring pubring.kbx --quiet SHA256SUMS.asc SHA256SUMS |& grep '^gpgv: Good signature'
echo "If you don't see any 'gpgv: Good signature' records, then something has gone wrong! Don't trust the release and following results!"
sha256sum -c --ignore-missing <SHA256SUMS
