#!/bin/bash

[ -z "$1" ] && echo "need repository remote path" && exit 1
gems="sinatra json dropbox-sdk"

git clone $1 repo || echo "Error cloning repository. Bailing out" && exit 1

echo "Checking ruby installation..."

if ! ( gem -v &> /dev/null && ruby -v &> /dev/null); then 
	echo "Please ensure you have ruby and gem installed and accesible."
	exit 1
fi

echo "Installing required gems $gems..."
echo "PS: Maybe you want to modify this script so gem runs with sudo"

for g in $gems; do
	echo "Installing $g"
	gem install $g
done

touch dbtoken

echo "You're ready to go! Save your Dropbox token in dbtoken, configure your git hooks and then execute webhook_start to start the listener"

