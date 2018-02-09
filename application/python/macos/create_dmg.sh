#!/bin/sh

# https://asmaloney.com/2013/07/howto/packaging-a-mac-os-x-application-using-a-dmg/
# https://github.com/sindresorhus/create-dmg


BUILD_DIR="dist"
APP_NAME="HstWB Installer"
VERSION="2.0.0"
VOL_NAME="${APP_NAME} ${VERSION}" 
DMG_FILE="${VOL_NAME}.dmg"
DMG_TMP_FILE="${DMG_FILE}.temp.dmg"
DMG_BACKGROUND_IMG="dmg-background.png"
DMG_BACKGROUND_IMG2="dmg-background@2x.png"

DMG_WIDTH=660
DMG_HEIGHT=400
DMG_TOPLEFT_X=200
DMG_TOPLEFT_Y=200
DMG_BOTTOMRIGHT_X=`expr $DMG_TOPLEFT_X + $DMG_WIDTH`
DMG_BOTTOMRIGHT_Y=`expr $DMG_TOPLEFT_Y + $DMG_HEIGHT`

if [ -f "${DMG_FILE}" ]; then
  rm -f "${DMG_FILE}"
fi

if [ -f "${DMG_TMP_FILE}" ]; then
  rm -f "${DMG_TMP_FILE}"
fi


# calculate size in mb
SIZE=`du -sh "${BUILD_DIR}" | egrep '^[0-9]+(,[0-9]+)*M.*$' | sed 's/\([0-9]*\)\(.*\)/\1/'`

if [ "$SIZE" == "" ]; then
    SIZE=0
fi

SIZE=`echo "${SIZE} + 1.0" | bc | awk '{print int($1+0.5)}'`


# create the temp DMG file
hdiutil create -srcfolder "${BUILD_DIR}" -volname "${VOL_NAME}" -fs HFS+ \
      -fsargs "-c c=64,a=16,e=16" -format UDRW -size ${SIZE}M "${DMG_TMP_FILE}"
 
echo "Created DMG: ${DMG_TMP_FILE}"
 
# mount it and save the device
DEVICE=$(hdiutil attach -readwrite -noverify "${DMG_TMP_FILE}" | \
         egrep '^/dev/' | sed 1q | awk '{print $1}')
 
sleep 2

# add a link to the Applications dir
echo "Add link to /Applications"
pushd /Volumes/"${VOL_NAME}"
ln -s /Applications
popd

# add a background image
mkdir /Volumes/"${VOL_NAME}"/.background
cp "${DMG_BACKGROUND_IMG}" /Volumes/"${VOL_NAME}"/.background/
cp "${DMG_BACKGROUND_IMG2}" /Volumes/"${VOL_NAME}"/.background/

# tell the Finder to resize the window, set the background,
#  change the icon size, place the icons in the right position, etc.
echo '
   tell application "Finder"
     tell disk "'${VOL_NAME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {'${DMG_TOPLEFT_X}', '${DMG_TOPLEFT_Y}', '${DMG_BOTTOMRIGHT_X}', '${DMG_BOTTOMRIGHT_Y}'}
           set viewOptions to the icon view options of container window
           set arrangement of viewOptions to not arranged
           set icon size of viewOptions to 72
           set background picture of viewOptions to file ".background:'${DMG_BACKGROUND_IMG}'"
           set position of item "'${APP_NAME}'.app" of container window to {180, 170}
           set position of item "Applications" of container window to {480, 170}
           close
           open
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript

sync

# unmount it
hdiutil detach "${DEVICE}"

# now make the final image a compressed disk image
echo "Creating compressed image"
hdiutil convert "${DMG_TMP_FILE}" -format UDZO -imagekey zlib-level=9 -o "${DMG_FILE}"

if [ -f "${DMG_TMP_FILE}" ]; then
  rm -f "${DMG_TMP_FILE}"
fi

