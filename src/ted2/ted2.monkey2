
#Import "mojox/mojox"

#Import "mainwindow"
#Import "projectview"
#Import "debugview"
#Import "helpview"
#Import "finddialog"

#Import "ted2document"
#Import "txtdocument"
#Import "mx2document"
#Import "mx2highlighter"
#Import "imgdocument"

Namespace ted2

Using std..
Using mojo..
Using mojox..

Function Main()

'	Print "Hello World from Ted2"

	ChangeDir( AppDir() )
		
	While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory

'		Print "CurrentDir="+CurrentDir()
			
		If IsRootDir( CurrentDir() )
			Print "Error initializing Ted2 - can't find working dir!"
			libc.exit_( -1 )
		Endif
		
		ChangeDir( ExtractDir( CurrentDir() ) )
		
	Wend
	
	New AppInstance
	
	Theme.Load()
	
	New MainWindowInstance( "Ted2",New Recti( 16,16,960,800 ),WindowFlags.Resizable|WindowFlags.Center )
	
	App.Run()
End
