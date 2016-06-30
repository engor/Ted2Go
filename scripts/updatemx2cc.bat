
echo off

call common.bat

echo.
echo ***** Updating mx2cc *****
echo.

%mx2cc% makeapp -apptype=console -config=release ../src/mx2cc/mx2cc.monkey2
copy %mx2cc_new% %mx2cc%
