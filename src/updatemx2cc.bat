
echo off

echo.
echo ***** Updating mx2cc *****
echo.

..\bin\mx2cc_windows makeapp -config=release mx2new/mx2cc.monkey2
copy mx2new\mx2cc.buildv003\desktop_release_windows\mx2cc.exe ..\bin\mx2cc_windows.exe
