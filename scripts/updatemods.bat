
echo off

echo.
echo ***** Updating modules *****
echo.

..\bin\mx2cc_windows makemods -config=release -target=desktop
..\bin\mx2cc_windows makemods -config=debug -target=desktop
