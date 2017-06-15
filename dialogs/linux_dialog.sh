#! /bin/bash

# displays a folder dialog for selecting a directory
# @param $2 title
# @param $3 message
# @param $4 path
# @return path to selected directory
folder_dialog() 
{
  RESULT=$(yad --form --title "$1" --field="$2":DIR "$3" 2>/dev/null)
  if [ "$RESULT" != "" ]
  then
	OIFS=IFS
	IFS="|"
	echo $RESULT
    #echo $RESULT
	IFS=OIFS
  fi
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
		--title "$1" \
		--button=gtk-yes:0 \
		--button=gtk-no:1 \
		--text "$2" 2>/dev/null
	then
		echo "1"
	else
		echo "0"
	fi
}

if [ "$1" == "confirm_dialog" ]
then 
  confirm_dialog "$2" "$3"
elif [ "$1" == "folder_dialog" ]
then
  folder_dialog "$2" "$3" "$4"
else
  echo -n ''
fi
