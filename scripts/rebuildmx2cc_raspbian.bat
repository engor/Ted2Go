echo off

call common.bat

echo.
echo ***** Rebuilding mx2cc *****
echo.

%mx2cc% makemods -clean -config=release -target=raspbian monkey libc miniz stb-image stb-image-write stb-vorbis std
%mx2cc% makeapp -build -clean -apptype=console -config=release -target=raspbian ../src/mx2cc/mx2cc.monkey2

copy %mx2cc_raspbian_new% ..\bin\mx2cc_raspbian
