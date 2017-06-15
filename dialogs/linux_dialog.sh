#! /bin/bash

# displays a file dialog for choosing a *folder* not a file
# @return the file path
function folder_dialog() 
{
	RESULT=$(yad --title "title" --field="message":DIR "")
	echo $RESULT
}

# displays a dialog for collecting a single line of text input
# @param $1 the text of the prompt
# @return the input text
function text_dialog() {
}

# displays a confirmation dialog with a Yes/No button.
# @param $1 the text of the prompt
# @return the response of the user: "0" - No, "1" - Yes
function confirm_dialog() {
	if yad \
		--image "dialog-question" \
		--title "title" \
		--button=gtk-yes:0 \
		--button=gtk-no:1 \
		--text "message"
	then
		echo "1"
	else
		echo "0"
	fi
}

folder_dialog()
confirm_dialog()