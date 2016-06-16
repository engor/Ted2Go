
echo off

echo.
echo ***** Rebuilding ted2 *****
echo.

..\bin\mx2cc_windows makeapp -apptype=gui -clean -build -config=release -target=desktop ../src/ted2/ted2.monkey2
xcopy ..\src\ted2\ted2.buildv010\desktop_release_windows ..\bin\ted2_windows /I /S /Y

..\bin\mx2cc_windows makeapp -apptype=gui -clean -build -config=release -target=desktop ../src/launcher/launcher.monkey2
copy ..\src\launcher\launcher.buildv010\desktop_release_windows\launcher.exe "..\Monkey2 (Windows).exe"
