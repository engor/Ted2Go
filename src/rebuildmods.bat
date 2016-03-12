
echo.
echo ***** Rebuildingg modules *****
echo.

..\bin\mx2cc_windows makemods -clean -config=release -target=desktop
..\bin\mx2cc_windows makemods -clean -config=debug -target=desktop
