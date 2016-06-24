
echo off

call common.bat

echo.
echo ***** Rebuilding ted2 *****
echo.

%mx2cc% makeapp -clean -apptype=gui -build -config=release -target=desktop ../src/ted2/ted2.monkey2
xcopy %ted2_new% %ted2% /I /S /Y

%mx2cc% makeapp -clean -apptype=gui -build -config=release -target=desktop ../src/launcher/launcher.monkey2
copy %launcher_new% %launcher%
