
source common.sh

echo ""
echo "***** Rebuilding ted2 *****"
echo ""

$mx2cc makeapp -apptype=gui -clean -build -config=release -target=desktop ../src/ted2/ted2.monkey2

$mx2cc makeapp -apptype=gui -clean -build -config=release -target=desktop ../src/launcher/launcher.monkey2

if [ "$OSTYPE" = "linux-gnu" ]
then

	rm -r -f "$ted2"
	cp -R "$ted2_new" "$ted2"
	rm -r -f "$launcher"
	cp -R "$launcher_new" "$launcher"

else

	rm -r -f "$ted2"
	cp -R "$ted2_new" "$ted2"
	rm -r -f "$launcher"
	cp -R "$launcher_new" "$launcher"
	
fi
