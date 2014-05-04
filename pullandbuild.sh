#!/bin/bash

packages_dir="Cosas guays LaTeX"
packages_changed=false
repo_dir="repo"
ruby_bin="/home/gjulianm/.rvm/rubies/ruby-2.0.0-p451/bin/ruby"
failed=""

function packages_install() {
	cd "$packages_dir"
	sudo ./install
}

function prebuild() {
	mkdir -p tikzgen
}

function build() {
	latexmk -pdf -silent -shell-escape $1
}

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
cd "$(dirname ${BASH_SOURCE[0]})"

cd $repo_dir

if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
	echo "Dirty repo. stashing changes."
	git stash save "auto stash $(date)"
fi

echo "Pulling repository"
git pull

changes=$(git diff --name-only master@{1})

if echo $changes | grep "$packages_dir" &> /dev/null; then
	echo "Packages changed."
	cwd=$(pwd)
	packages_changed=true
	packages_install
	cd "$cwd"
fi

cd ..

db_token=$(cat dbtoken)

IFS=$'\n'

for texfile in $(ls $repo_dir/*/*.tex); do
	cwd=$(pwd)
	cd "$(dirname $texfile)"

	texfile="$(basename $texfile)"

	if [ "$packages_changed" = true ]; then 
		latexmk -C
	fi

	prebuild

	if ! latexmk -pdf -r "$cwd/uptodatecheck.latexmkrc" "$texfile" &>/dev/null ; then
		echo "$texfile out of date. Compiling..."
		if build "$texfile" ; then
			echo "Uploading $texfile..."
			$ruby_bin "$cwd/dbupload.rb" "$db_token" "${texfile/.tex/.pdf}"
		else
			echo "Compilation failed for $texfile"
			failed="$failed $texfile"
		fi
	fi

	cd "$cwd"
	echo
done

[[ -z "$failed" ]] || echo "Compilation failed for $failed "
echo "done"
