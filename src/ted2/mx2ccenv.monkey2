
Namespace ted2

Function GetEnv:String( name:String )

	Local p:=libc.getenv( name )
	If p Return String.FromCString( p )
	
	Return ""
End

Function SetEnv( name:String,value:String )

	libc.setenv( name,value,1 )
End

Private

#If __TARGET__="windows"
Const HostOS:="windows"
#Else If __TARGET__="macos"
Const HostOS:="macos"
#Else If __TARGET__="linux"
Const HostOS:="linux"
#Else IF __TARGET__="raspbian"
Const HostOS:="raspbian"
#Else
Const HostOS:=""
#Endif

Function ReplaceEnv:String( str:String,lineid:Int )

	Local i0:=0

	Repeat
		Local i1:=str.Find( "${",i0 )
		If i1=-1 Exit
		
		Local i2:=str.Find( "}",i1+2 )
		If i2=-1 Exit
		
		Local name:=str.Slice( i1+2,i2 ).Trim()
		Local value:=GetEnv( name )
		
		str=str.Slice( 0,i1 )+value+str.Slice( i2+1 )
		i0=i1+value.Length
		
	Forever
	
	Return str
End

Function LoadEnv()

	Local path:="bin/env_"+HostOS+".txt"

	SetEnv( "MX2_HOME",CurrentDir() )
	SetEnv( "MX2_MODULES",CurrentDir()+"modules" )

	Local lineid:=0
	
	For Local line:=Eachin stringio.LoadString( path ).Split( "~n" )
		lineid+=1
	
		Local i:=line.Find( "'" )
		If i<>-1 line=line.Slice( 0,i )
		
		line=line.Trim()
		If Not line Continue
		
		i=line.Find( "=" )
		If i=-1 Continue
		
		Local name:=line.Slice( 0,i ).Trim()
		Local value:=line.Slice( i+1 ).Trim()
		
		value=ReplaceEnv( value,lineid )
		
		SetEnv( name,value )
	Next
End

Public

Function EnumValidTargets:StringStack( console:Console )

	LoadEnv()
	
	Local targets:=New StringStack
	
	targets.Push( "desktop" )
	targets.Push( "emscripten" )
	targets.Push( "android" )
#If __TARGET__="macos"
	targets.Push( "ios" )
#Endif

	Return targets
	
	'FIXME - too slow at startup, esp. on Mac!
	
	console.Write( "~n***** Checking for valid targets *****~n~n" )
	
	CreateDir( "tmp" )
	
	If Not libc.system( "g++ --version >tmp/tmp.txt" )
		Local tmp:=LoadString( "tmp/tmp.txt" )
		console.Write( "Desktop target OK.~n" )
		targets.Push( "desktop" )
	Else
		console.Write( "Desktop target unavailable - can't find desktop 'g++' tool.~n" )
	Endif
	
	If Not libc.system( "em++ --version >tmp/tmp.txt" )
		Local tmp:=LoadString( "tmp/tmp.txt" )
		console.Write( "Emscripten target OK.~n" )
		targets.Push( "emscripten" )
	Else
		console.Write( "Emscripten target unavailable - can't find 'em++' tool.~n" )
	Endif
	
	If Not libc.system( "ndk-build --version >tmp/tmp.txt" )
		Local tmp:=LoadString( "tmp/tmp.txt" )
		console.Write( "Android target OK.~n" )
		targets.Push( "android" )
	Else
		console.Write( "Android target unavailable - Can't find 'ndk-build' tool.~n" )
	Endif
	
#if __TARGET__="macos"
	If targets.Contains( "Desktop" )
		console.Write( "iOS target OK.~n" )
		targets.Push( "ios" )
	Else
		console.Write( "iOS target unavailable - Can't find 'g++' tool.~n" )
	Endif
#else
		console.Write( "iOS target unavailable (iOS only supported on MacOS).~n" )
#endif

	Return targets

End
