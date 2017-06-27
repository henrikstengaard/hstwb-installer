#! /bin/bash

# Library which is similar to the "dialog" tool for linux. Instead of using the linux gui toolkit, we use AppleScript to display the dialogs. 
# Usage:
# Include this file using the "source" command then use one of the functions.	

# Reference for communicating with apple script:
# http://stackoverflow.com/questions/3502913/how-to-pass-a-variable-from-applescript-to-a-shell-script
# Reference for dialogs:
# http://en.wikibooks.org/wiki/AppleScript_Programming/Advanced_Code_List/Display_Dialog
# Reference for folder dialog
# http://docs.info.apple.com/article.html?path=AppleScript/2.1/en/as309.html

# displays a file dialog for choosing a *folder* not a file
# @return the file path

# displays a folder dialog for selecting a directory
# @param $1 title
# @param $2 message
# @param $3 path
# @return path to selected directory
function folder_dialog() 
{
	local file_path=$(osascript << EOT
		tell application "Finder"
			activate
			set fpath to POSIX path of (choose folder with prompt "$1")
			return fpath
		end tell
	EOT)
	
	echo $file_path
}

# displays a dialog for collecting a single line of text input
# @param $1 the text of the prompt
# @return the input text
function text_dialog() {
	local answer=$(osascript << EOT
		tell application "Finder"
			activate
			set response to text returned of (display dialog "$1" default answer "Response...")
			return response
		end tell
	EOT)
	
	echo $answer
}

# displays a confirmation dialog with a Yes/No button.
# @param $1 the text of the prompt
# @return the response of the user: "0" - No, "1" - Yes
function confirm_dialog() {
	local response=$(osascript << EOT
	tell application "Finder"
		activate
		try
			set response to button returned of (display dialog "$1")

			if (response is equal to "OK") then
				set response to 1
			end if
		on error errTet number errNum
			if (errNum is equal to -128) then
				-- user cancelled - not an error
				set response to 0
			end if
		end try
		return response
	end tell
	EOT)
	echo $response
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