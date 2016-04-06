
mx2cc=""
mx2cc_new=""

if [ "$OSTYPE" = "linux-gnu" ]
then
	mx2cc="../bin/mx2cc_linux"
	mx2cc_new="mx2new/mx2cc.buildv003/desktop_release_linux/mx2cc"
else
	mx2cc="../bin/mx2cc_macos"
	mx2cc_new="mx2new/mx2cc.buildv003/desktop_release_macos/mx2cc.app/Contents/MacOS/mx2cc"
fi
