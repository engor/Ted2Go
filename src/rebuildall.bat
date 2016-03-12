
echo off
cls

echo.
echo ***** Rebuilding mx2cc with old mx2cc *****
echo.

..\devtools\mx2v001\bin\mx2cc_windows makeapp -clean -config=release mx2new\mx2cc.monkey2

echo.
echo ***** Rebuilding modules with new mx2cc *****
echo.

mx2new\mx2cc.buildv001\desktop_release_windows\mx2cc makemods -clean -verbose -config=release monkey libc miniz stb std hoedown
mx2new\mx2cc.buildv001\desktop_release_windows\mx2cc makemods -clean -verbose -config=debug monkey libc miniz stb std hoedown

echo.
echo ***** Rebuilding mx2cc with new mx2cc *****
echo.

mx2new\mx2cc.buildv001\desktop_release_windows\mx2cc makeapp -clean -verbose -config=release mx2new/mx2cc.monkey2
copy mx2new\mx2cc.buildv002\desktop_release_windows\mx2cc.exe ..\bin\mx2cc_windows.exe

echo.
echo ***** Finished! *****
echo.

