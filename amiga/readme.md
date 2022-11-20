# AmigaDOS scripting tricks

## Runing a second script and skip back

If a script uses the ```Execute``` command to run a second script, then when that seocnd script is finished ```Skip``` command can not skip back to labels in the first script. This can fixed by running the script using ```Set``` command to run the script with following syntax:
```
set dummy "`Execute Other-Script`"
```

Example of first script:
```
LAB runscript
Echo "Run second script"
set dummy "`Execute Other-Script`"
SKIP BACK runscript
```

Example of second script:
```
Echo "Second script"
```

## Edit tricks

Edit command
https://wiki.amigaos.net/wiki/AmigaOS_Manual:_AmigaDOS_Using_the_Editors#EDIT_Commands

```
F/BindDrivers/
P
I
; execute menu startup, if it exists
IF EXISTS S:Menu-Startup
  Execute S:Menu-Startup
EndIF
Z
W
```

The lines in the edit file does the following:
1. Line 1 find the text "BindDrivers".
2. Line 2 moves to previous line.
3. Line 3 "I" indicates text block to be inserted.
4. Line 4-7 Insert text in .
5. Line 8 "Z" indicates text block end.
6. Line 9 writes changes.

```
F/execute s:boot-startup/
N
FROM .PACKAGEDIR:patches/BootMenu-Startup.
M*
FROM
CF .PACKAGEDIR:patches/BootMenu-Startup.
W
```

The lines in the edit file does the following:
1. Find the text "execute s:boot-startup".
2. Move to next line.
3. Select file "PACKAGEDIR:patches/BootMenu-Startup" for new input.
4. Append Copy all from the file.
5. Switch back to main file.
6. Close file "PACKAGEDIR:patches/BootMenu-Startup".
7. Write changes.
