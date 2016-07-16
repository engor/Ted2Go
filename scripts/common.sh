
mx2cc=""
mx2cc_new=""
ted2=""
ted2_new=""
launcher=""
launcher_new=""

if [ "$OSTYPE" = "linux-gnu" ]
then

	mx2cc="../bin/mx2cc_linux"
	mx2cc_new="../src/mx2cc/mx2cc.buildv1.0.2/desktop_release_linux/mx2cc"
	
	ted2="../bin/ted2_linux"
	ted2_new="../src/ted2/ted2.buildv1.0.2/desktop_release_linux"
	
	launcher="../Monkey2 (Linux)"
	launcher_new="../src/launcher/launcher.buildv1.0.2/desktop_release_linux/launcher"
	
else

	mx2cc="../bin/mx2cc_macos"
	mx2cc_new="../src/mx2cc/mx2cc.buildv1.0.2/desktop_release_macos/mx2cc"
	
	ted2="../bin/ted2_macos.app"
	ted2_new="../src/ted2/ted2.buildv1.0.2/desktop_release_macos/ted2.app"
	
	launcher="../Monkey2 (Macos).app"
	launcher_new="../src/launcher/launcher.buildv1.0.2/desktop_release_macos/launcher.app"
fi
