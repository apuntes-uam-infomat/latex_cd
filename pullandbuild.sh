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
	latexmk -pdf -silent -shell-escape "$1" &> /dev/null
}

function check_conflicts() {
	dir=$(basename "$(pwd)")
	texfile="$dir/$1"

	cd ..

	if ! grep "<<< HEAD" "$texfile" &> /dev/null ; then
		return
	fi

	echo "Conflict markers present in $texfile."

	git checkout master@{1}

	if ! grep "<<< HEAD" "$texfile" &> /dev/null ; then
		echo "Conflict master present before this pull"
		git checkout master
		cd "$dir"
		return
	fi

	git bisect start master master@{1}
	git bisect run grep "<<< HEAD" "$texfile"
	bad_commit=$(git rev-parse HEAD)
	author=$(git --no-pager show -s --format='%an <%ae>' HEAD)
	markers=$(grep -n -C 3 "<<< HEAD" "$texfile" | sed 's/\\/\\\\/g' | iconv -f latin1 -t ascii//TRANSLIT)
	git bisect reset
	git checkout master

	commit_api_url="https://api.github.com/repos/VicdeJuan/Apuntes/commits/$bad_commit"
	author_ghname="$(curl $commit_api_url | grep login | awk '{print $2}' | tr -d '"' | tr -d ',' | head -n 1)"

	msg_title="Marcadores de conflicto en $texfile"
	msg_contents="Marcadores introducidos en commit $bad_commit por @$author_ghname."
	errors_msg="Marcadores: \n\n \`\`\`\n$markers \n \`\`\` \n"

	rvm $RUBYVER do /usr/local/bin/ghi open -m "$(echo -e "$msg_title\n $msg_contents \n\n $errors_msg \n Mensaje creado automáticamente.")"
	echo $msg_contents
}

function report_build_failed() {
	texfile="$1"
	[ ! -z "$texfile" ] || return 0

	logfile=$(echo "$texfile" | sed 's/.tex/.log/')
	errors=$(cat "$logfile" | grep -A 4 '!' | sed 's/\\/\\\\/g' | iconv -f latin1 -t ascii//TRANSLIT)

	git checkout master@{1}

	target_dir=$(basename "$(pwd)")

	if ! latexmk -pdf -silent -shell-escape "$texfile" &> /dev/null; then
		echo "Error present before this pull."
		git checkout master
		return
	fi

	cd ..
	git checkout master
	git bisect start master master@{1}
	git bisect run bash -c "cd \"$target_dir\"; latexmk -g -pdf -silent -shell-escape \"$texfile\""
	bad_commit=$(git rev-parse HEAD)
	author=$(git --no-pager show -s --format='%an <%ae>' HEAD)
	git bisect reset
	cd "$target_dir"

	if ! latexmk -pdf -silent -shell-escape "$texfile" &> /dev/null; then
		echo "Error not introduced in this commit. Possibly caused by a merge..."
		git checkout master
		return
	fi


	latexmk -C

	commit_api_url="https://api.github.com/repos/VicdeJuan/Apuntes/commits/$bad_commit"
	author_ghname="$(curl $commit_api_url | grep login | awk '{print $2}' | tr -d '"' | tr -d ',' | head -n 1)"

	msg_title="Fallo de compilación en $texfile"
	msg_contents="Error introducido en commit $bad_commit por @$author_ghname."
	errors_msg="Log de error: \n\n \`\`\`\n$errors \n \`\`\` \n"

	rvm $RUBYVER do	/usr/local/bin/ghi open -m "$(echo -e "$msg_title\n $msg_contents \n\n $errors_msg \n Mensaje creado automáticamente.")"
	echo $msg_contents
}


echo "Latex CD build start $(date)"

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

if [ "$1" = "--force" ]; then
	packages_changed=true
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
			echo "$texfile compile successful."
			(( dir_upd += 1))
			updated="$updated $texfile"
			echo "Uploading $texfile..."
			wd=$(pwd)
			cd "$cwd"
			rvm $RUBYVER do bundle exec ruby dbupload.rb "$db_token" "$wd/${texfile/.tex/.pdf}"
			cd "$wd"
		else
			(( dir_err += 1))
			echo "Compilation failed for $texfile"
			report_build_failed "$texfile"
			failed="$failed $texfile"
		fi
	fi

	check_conflicts "$texfile"

	cd "$cwd"
	echo
done

echo "Found $dir_num courses, updated $dir_upd, failed $dir_err."
[[ -z "$failed" ]] || echo "Compilation failed for $failed "
[[ -z "$updated" ]] || echo "Updated $updated"
echo "done: $(date)"
