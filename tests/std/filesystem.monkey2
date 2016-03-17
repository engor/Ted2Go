
#Import "<std.monkey2>"

Using std.filesystemex

Function Main()

	Local cd:=CurrentDir()
	Local parent:=GetParentDir( cd )
	
	Print cd
	Print parent
	
	ChangeDir( parent )
	Print CurrentDir()
	
	ChangeDir( cd )
	Print CurrentDir()
	
	Print GetRealPath( "test/one" )				'test/one
	Print GetRealPath( "test//one" )			'test/one
	Print GetRealPath( "test//one/" )			'test/one/
	Print GetRealPath( "test//one///" )			'test/one/
	Print GetRealPath( "test/one/two/../" )		'test/one/
	
	CreateDir( "one/two/three" )
	Print Int( GetFileType( "one/two/three" ) )	'2
	
	DeleteDir( "one/two/three" )
	Print Int( GetFileType( "one/two/three" ) )	'0

	DeleteDir( "one" )
	Print Int( GetFileType( "one" ) )			'2

	DeleteDir( "one",True )
	Print Int( GetFileType( "one" ) )			'0

End
