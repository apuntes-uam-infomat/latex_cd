#!/bin/bash

packages_dir="Cosas guays LaTeX"
packages_changed=false
repo_dir="repo"
ruby_bin="/home/gjulianm/.rvm/rubies/ruby-2.0.0-p451/bin/ruby"
failed=""
updated=""

function packages_install() {
	cd "$packages_dir"
	./install
}

function prebuild() {
	mkdir -p tikzgen
}

function build() {
	latexmk -pdf -silent -shell-escape "$1"
}

echo "Latex CD build start $(date)"

# Load the ruby scripts in order to use the Dropbox upload
[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"
cd "$(dirname ${BASH_SOURCE[0]})"

cd $repo_dir

if [[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]]; then
	echo "Dirty repo. stashing changes."
	git stash save "auto stash $(date)"
fi

echo "Push to remote repo at $(date)"
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

dir_num=0
dir_upd=0
dir_err=0

for texfile in $(ls $repo_dir/*/*.tex); do
	cwd=$(pwd)
	cd "$(dirname $texfile)"
	(( dir_num += 1))	

	echo "Checking $texfile..."
	texfile="$(basename $texfile)"

	if [ "$packages_changed" = true ]; then 
		latexmk -C
	fi

	prebuild

	if ! latexmk -pdf -r "$cwd/uptodatecheck.latexmkrc" "$texfile" &>/dev/null ; then
		echo "$texfile out of date. Compiling..."
		if build "$texfile" ; then
			(( dir_upd += 1))
			updated="$updated $texfile"
			echo "Uploading $texfile..."
			$ruby_bin "$cwd/dbupload.rb" "$db_token" "${texfile/.tex/.pdf}"
		else
			(( dir_err += 1))
			echo "Compilation failed for $texfile"
			failed="$failed $texfile"
		fi
	fi

	cd "$cwd"
	echo
done

echo "Found $dir_num courses, updated $dir_upd, failed $dir_err."
[[ -z "$failed" ]] || echo "Compilation failed for $failed "
[[ -z "$updated" ]] || echo "Updated $updated"
echo "done: $(date)"
