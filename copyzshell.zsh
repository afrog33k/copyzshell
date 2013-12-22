#!/bin/zsh
if [[ ! ARGC -eq 1 ]] then
	echo "1 argument required, $# provided"
	exit 1
elif [[ $1 = '-h' || $1 = '--help' ]] then
	echo "HELP MSG"
	exit 0 
else
	echo "OK LETS GO"
	zmodload zsh/regex
	#check that the ZSH path is not wierd
	if [[ ! $ZSH -regex-match ^$HOME/(.+) ]] then
		echo "Your ZSH folder "$ZSH" doesn't seem to be in your home folder. Quitting"
		exit 1
	fi
	
	datestr=$(date "+%Y-%m-%d-%H:%M:%S")
	zsh_folder=${ZSH#$HOME/} # could be in multiple subfolders relative to $HOME TODO TEST!
	zsh_base=${ZSH##*/}
	zsh_folder_without_base=./${ZSH_folder%$zsh_base}
	echo $zsh_folder
	echo $zsh_folder_without_base
	#mkdir -p

	cd ~
	set -e
	echo We will copy shell settings to $1
	# We want to move all files in a batch so we don't have to ask for passwords so much.

	# move our files into a subdirectory of tmp so that we don't have to worry about 
	# permissions when overwriting old files on the remote machine.
	# Otherwise, this can happen with .git objects when a previous run of this script
	# failed for some reason.
	echo Transfering $ZSH, .zshrc and .gitconfig.
	tmpdir=/tmp/copyshell$datestr
	mkdir $tmpdir
	cp -r $ZSH $tmpdir/oh-my-zsh
	echo cp -r $ZSH $tmpdir/oh-my-zsh
	cp .zshrc $tmpdir
	cp .gitconfig $tmpdir
	echo 	scp -r $tmpdir $1":"$tmpdir
	scp -r $tmpdir $1":"$tmpdir
	echo "files should now be in "$tmpdir

	# rc=$?
	#DO NOT TRANSFER WIERD GIT FILES!
	# if [[ ! $rc = 1 && ! $rc = 0 ]] ; then
	# 	echo "failing because error " $rc
	# 	exit $rc
	# fi

	#TODO: better error msg in case of transfer failure (esp. permissions)
	echo File transfer complete. We will now setup the shell via ssh.

	#todo: take into account usernames!!
	ssh -t $1 '

	# this will be run in *gulp* bash ? TODO: MAKE SURE IT DOES
	cd ~
	# exit on failure!
	
	# check for pre-existing zsh folder!
	if [[ -d '$zsh_folder' ]]; then
		echo 1
		echo '$ZSH_folder' aldready exists, copying it to '$zsh_folder'_'$datestr';
		mv '$zsh_folder' '$zsh_folder_$datestr'; 
	fi

	#move the new zsh folder into position
	mkdir -p '$zsh_folder_without_base'
	mv '$tmpdir'/oh-my-zsh '$zsh_folder'

	# check for pre-existing files
	if [ -f .zshrc ]; then 
		mv .zshrc .zshrc_'$datestr' 
		echo "An existing .zshrc was found. It was moved to .zshrc_'$datestr'"
	fi
	if [ -f .gitconfig ]; then 
		mv .gitconfig .gitconfig_'$datestr'
		echo "An existing .gitconfig was found. It was moved to .gitconfig_'$datestr'"
	fi

	# move the new files into position
	mv '$tmpdir'/.zshrc .zshrc
	mv '$tmpdir'/.gitconfig .gitconfig

	#check that zsh is installed
	command -v zsh >/dev/null 2>&1
	if [[ $? -eq 1 ]]; then
    	echo "zsh does not appear to be installed. Your configuration is prepared, so install zsh and then change your shell using 'chsh -s /bin/zsh', and your configuration should become active."
	else
		chsh -s /bin/zsh
	fi
fi