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
