
mx2cc=""
mx2cc_old=""
mx2cc_v001=""
mx2cc_v002=""
mx2cc_v003=""
mserver=""

if [ "$OSTYPE" = "linux-gnu" ]
then
	mx2cc="../bin/mx2cc_linux"
	mx2cc_old="../devtools/mx2v001/bin/mx2cc_linux"
	mx2cc_v001="mx2new/mx2cc.buildv001/desktop_release_linux/mx2cc"
	mx2cc_v002="mx2new/mx2cc.buildv002/desktop_release_linux/mx2cc"
	mx2cc_v003="mx2new/mx2cc.buildv003/desktop_release_linux/mx2cc"
	mserver="../devtools/MonkeyXFree86c/bin/mserver_linux"
	chmod +x $mx2cc_old
	chmod +x $mserver
else
	mx2cc="../bin/mx2cc_macos"
	mx2cc_old="../devtools/mx2v001/bin/mx2cc_macos"
	mx2cc_v001="mx2new/mx2cc.buildv001/desktop_release_macos/mx2cc.app/Contents/MacOS/mx2cc"
	mx2cc_v002="mx2new/mx2cc.buildv002/desktop_release_macos/mx2cc.app/Contents/MacOS/mx2cc"
	mx2cc_v003="mx2new/mx2cc.buildv003/desktop_release_macos/mx2cc.app/Contents/MacOS/mx2cc"
#	chmod +x $mx2cc_old
#	chmod +x $mserver
fi
