#!/bin/bash

# run git worktree add comman
git worktree add $@

# get the newly create folder name
if [[ $1 != -* ]]; then
	dir_path="$1"
else
	dir_path="$3"
fi

# cd into the folder
cd "$dir_path" || {
	echo "Error: failed to change directory to $dir_path"
	exit 1
}

# Copy all the .env files from main folder
if [[ -d "../main" ]]; then
	find "../main/" -type f -name '.env*' -exec cp -f {} "./" \;
elif [[ -d "../../main" ]]; then
	find "../../main/" -type f -name '.env*' -exec cp -f {} "./" \;
else
	echo "Error: couldn't find the main folder to copy .env files from."
fi

# Open in VSCode
code .

# Install dependencies and start the server
yarn install
yarn dev
