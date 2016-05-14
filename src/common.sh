
mx2cc=""
mx2cc_new=""
ted2=""
ted2_new=""

if [ "$OSTYPE" = "linux-gnu" ]
then
	mx2cc="../bin/mx2cc_linux"
	mx2cc_new="mx2new/mx2cc.buildv004/desktop_release_linux/mx2cc"
	ted2="../bin/ted2_linux"
	ted2_new="ted2/ted2.buildv004/desktop_release_linux/ted2"
else
	mx2cc="../bin/mx2cc_macos"
	mx2cc_new="mx2new/mx2cc.buildv004/desktop_release_macos/mx2cc.app/Contents/MacOS/mx2cc"
	ted2="../bin/ted2.app"
	ted2_new="ted2/ted2.buildv004/desktop_release_macos/ted2.app"
fi
