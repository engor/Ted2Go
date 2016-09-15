
#Import "<libc>"
#Import "<std>"

#If __HOSTOS__="windows"

'to build resource.o when icon changes...
'
'windres resource.rc resource.o

#Import "resource.o"

#Endif

Function Main()
#If __HOSTOS__="windows"

	libc.system( "bin\ted2_windows\ted2.exe" )
	
#Else If __HOSTOS__="macos"

	libc.system( "open ~q"+std.filesystem.AppDir()+"../../../bin/ted2_macos.app~q" )

#Else If __HOSTOS__="linux"

	libc.system( "bin/ted2_linux/ted2 >/dev/null 2>/dev/null &" )

#Else If __HOSTOS__="raspbian"

	libc.system( "bin/ted2_raspbian/ted2 >/dev/null 2>/dev/null &" )

#Endif

End
