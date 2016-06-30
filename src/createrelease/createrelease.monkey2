
#Import "<libc>"
#Import "<std>"

Using libc..
Using std..

Const MX2CC_VERSION:="1.0.0"

Global desktop:String
Global output:String

Function Copy( file:String )

	Print file
	
	CopyFile( file,output+file )
End

Function CopyFiles( dir:String )

	Print dir

	CreateDir( output+dir )
	
	For Local file:=Eachin LoadDir( dir )

		If file.Contains( "_macos" ) Continue
		If file.Contains( "_linux" ) Continue
			
		Local src:=dir+"/"+file
		
		Select GetFileType( src )
		Case FileType.Directory
		
			If file.Contains( ".buildv" )
				If Not dir.StartsWith( "modules/" ) Continue
				If Not file.EndsWith( ".buildv"+MX2CC_VERSION ) Continue
			Endif
			
			If file="build_cache" Continue
			
			CopyFiles( src )
		
		Case FileType.File
		
			If file="ted2.state.json" Continue
		
			Local dst:=output+dir+"/"+file
			
			CopyFile( src,dst )
		End
	Next
End

Function Main()

	Print "Hello World!"

	ChangeDir( AppDir() )
		
	While GetFileType( "bin/mx2cc_windows.exe" )<>FileType.File

		If IsRootDir( CurrentDir() )
			Print "Error initializing Ted2 - can't find working dir!"
			libc.exit_( -1 )
		Endif
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend

	desktop=(String.FromCString( getenv( "HOMEDRIVE" ) )+String.FromCString( getenv( "HOMEPATH" ) )+"\Desktop").Replace( "\","/" )+"/"
	
	Print "current="+CurrentDir()
	Print "desktop="+desktop
	
	output=desktop+"monkey2v1.0/"

	DeleteDir( output,True )
	CreateDir( output )
	CopyFiles( "bin" )
	CopyFiles( "docs" )
	CopyFiles( "modules" )
	CopyFiles( "bananas" )
	CopyFiles( "src" )
	
	Copy( "hello-world.monkey2" )
	Copy( "Monkey2 (Windows).exe" )
	Copy( "LICENSE.TXT" )
	Copy( "README.TXT" )
	Copy( "TODO.TXT" )
	
End
