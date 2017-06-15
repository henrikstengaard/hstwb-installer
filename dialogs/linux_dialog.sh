#! /bin/bash

# displays a folder dialog for selecting a directory
# @param $2 title
# @param $3 message
# @param $4 path
# @return path to selected directory
folder_dialog() 
{
	RESULT=$(yad --title "$2" --field="$3":DIR "$4")
	echo $RESULT
}

# displays a dialog for collecting a single line of text input
# @param $1 the text of the prompt
# @return the input text
# function text_dialog() {
# }

# displays a confirmation dialog with a Yes/No button.
# @param $2 title
# @param $3 message
# @return "0" - No, "1" - Yes
confirm_dialog() {
	if yad \
		--image "dialog-question" \
		--title "$2" \
		--button=gtk-yes:0 \
		--button=gtk-no:1 \
		--text "$3"
	then
		echo "1"
	else
		echo "0"
	fi
}

if [ $1 == 'confirm_dialog' ] then confirm_dialog
elif [ $1 == 'folder_dialog' ] then folder_dialog
fi