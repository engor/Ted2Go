
#Import "<std.monkey2>"

Using std.filesystemex

Function Main()

	Local cd:=GetCurrentDirectory()
	Local parent:=GetParentDirectory( cd )
	
	Print cd
	Print parent
	
	SetCurrentDirectory( parent )
	Print GetCurrentDirectory()
	
	SetCurrentDirectory( cd )
	Print GetCurrentDirectory()
	
	Print GetRealPath( "test/one" )				'test/one
	Print GetRealPath( "test//one" )			'test/one
	Print GetRealPath( "test//one/" )			'test/one/
	Print GetRealPath( "test//one///" )			'test/one/
	Print GetRealPath( "test/one/two/../" )		'test/one/
	
	CreateDirectory( "one/two/three" )
	Print Int( GetFileType( "one/two/three" ) )	'2
	
	DeleteDirectory( "one/two/three" )
	Print Int( GetFileType( "one/two/three" ) )	'0

	DeleteDirectory( "one" )
	Print Int( GetFileType( "one" ) )			'2

	DeleteDirectory( "one",True )
	Print Int( GetFileType( "one" ) )			'0

End
