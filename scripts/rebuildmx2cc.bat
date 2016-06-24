
echo off

call common.bat

echo.
echo ***** Rebuilding mx2cc *****
echo.

%mx2cc% makeapp -clean -apptype=console -config=release ../src/mx2new/mx2cc.monkey2
copy %mx2cc_new% %mx2cc%
