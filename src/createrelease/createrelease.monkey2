
#Import "<libc>"
#Import "<std>"

Using libc..
Using std..

Const MX2CC_VERSION:="1.0.8"

Const OUTPUT:="Monkey2-v"+MX2CC_VERSION

Global desktop:String
Global output:String

Function Copy( file:String )

	Print file
	
	CopyFile( file,output+"/"+file )
End

Function CopyFiles( dir:String )

	Print dir

	CreateDir( output+"/"+dir )
	
	For Local file:=Eachin LoadDir( dir )

#if __TARGET__="windows"
		If file.Contains( "_macos" ) Continue
		If file.Contains( "_linux" ) Continue
#elseif __TARGET__="macos"
		If file.Contains( "_windows" ) Continue
		If file.Contains( "_linux" ) Continue
#elseif __TARGET__="linux"
		If file.Contains( "_windows" ) Continue
		If file.Contains( "_macos" ) Continue
#endif
			
		Local src:=dir+"/"+file
		
		Select GetFileType( src )
		Case FileType.Directory
		
			If dir.StartsWith( "modules/" )
			
				If file.Contains( ".buildv" ) And Not file.EndsWith( ".buildv"+MX2CC_VERSION ) Continue
	
				If dir.Contains( ".buildv" )
					If file.StartsWith( "emscripten_" ) Continue
					If file.StartsWith( "android_" ) Continue
					If file.StartsWith( "ios_" ) Continue
					If file="build" Continue
					If file="src" Continue
				Endif
			
			Else If file.Contains( ".buildv" ) Or file.EndsWith( ".products" )
			
				Continue
			
			Endif
			
			CopyFiles( src )
		
		Case FileType.File
		
			If file="ted2.state.json" Continue
		
			Local dst:=output+"/"+dir+"/"+file
			
			CopyFile( src,dst )
		End
	Next
End

Function CopyRelease()

	DeleteDir( output,True )
	CreateDir( output )
	CopyFiles( "bin" )
	CopyFiles( "docs" )
	CopyFiles( "modules" )
	CopyFiles( "bananas" )
	CopyFiles( "products" )
	CopyFiles( "src" )
	CreateDir( output+"/devtools" )
	
	Copy( "hello-world.monkey2" )
	Copy( "LICENSE.TXT" )
	Copy( "README.TXT" )
	Copy( "TODO.TXT" )
	
#if __TARGET__="windows"
	Copy( "Monkey2 (Windows).exe" )
#else if __TARGET__="macos"
	CopyFiles( "Monkey2 (Macos).app" )
#else if __TARGET__="linux"
	Copy( "Monkey2 (Linux)" )
#endif

End

Function MakeInno()

	Local iss:=New StringStack
	iss.Push( "[Setup]" )
	iss.Push( "OutputDir="+desktop )
	iss.Push( "OutputBaseFilename="+OUTPUT )
	iss.Push( "AppName="+OUTPUT )
	iss.Push( "AppVerName="+OUTPUT )
	iss.Push( "DefaultGroupName="+OUTPUT )
	iss.Push( "DefaultDirName={sd}\"+OUTPUT )
	iss.Push( "UninstallFilesDir={app}\bin" )
	iss.Push( "[Icons]" )
	iss.Push( "Name: ~q{group}\"+OUTPUT+"~q; Filename: ~q{app}\Monkey2 (Windows).exe~q; WorkingDir: ~q{app}~q" )
	iss.Push( "Name: ~q{group}\Uninstall "+OUTPUT+"~q; Filename: ~q{uninstallexe}~q" )
	iss.Push( "[FILES]" )
	iss.Push( "Source: ~q"+output+"\*~q; DestDir: {app}; Flags: ignoreversion recursesubdirs" )
	iss.Push( "[RUN]" )
	iss.Push( "Filename: ~q{app}\Monkey2 (Windows).exe~q; Description: ~qLaunch "+OUTPUT+"~q; Flags: postinstall nowait skipifsilent" )
			
	Local isspath:=output+".iss"
	
	SaveString( iss.Join("~n"),isspath )
End

Function MakeMacosPkg()

	libc.system( "chmod -R 777 "+output )
	
	libc.system( "pkgbuild --install-location /Applications/"+OUTPUT+" --identifier "+OUTPUT+" --ownership preserve --root "+output+" "+output+".pkg" )
End

Function MakeLinuxTargz()

	libc.system( "chmod -R 777 "+output )
	
	libc.system( "tar czf "+output+".tgz -C "+desktop+" "+OUTPUT )
End

Function Main()

	Print "Hello World!"

	ChangeDir( AppDir() )
	
	While GetFileType( "bin" )<>FileType.Directory
		If IsRootDir( CurrentDir() )
			libc.exit_( -1 )
		Endif
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend

#if __TARGET__="windows"
	desktop=(String.FromCString( getenv( "HOMEDRIVE" ) )+String.FromCString( getenv( "HOMEPATH" ) )+"\Desktop").Replace( "\","/" )+"/"
#else
	desktop=String.FromCString( getenv( "HOME" ) )+"/Desktop/"
#endif
	
	Print "current="+CurrentDir()
	Print "desktop="+desktop
	
	output=desktop+OUTPUT

	CopyRelease()
	
#if __TARGET__="windows"	

	MakeInno()
	
#else if __TARGET__="macos"

	MakeMacosPkg()
	
#else if __TARGET__="linux"

	MakeLinuxTargz()

#endif

	Print "~nFinished!!!!!"

	
End
