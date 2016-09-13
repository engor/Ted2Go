
#If __TARGET__="windows"
#Import "bin/wget.exe"
#End

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"

#Import "mainwindow"
#Import "documentmanager"
#Import "fileactions"
#Import "editactions"
#Import "findactions"
#Import "finddialog"
#Import "buildactions"
#Import "helpactions"
#Import "debugview"
#Import "projectview"
#Import "helptree"
#Import "modulemanager"
#Import "ted2textview"
#Import "gutterview"

#Import "plugin"
#Import "ted2document"
#Import "codedocument"
#Import "plaintextdocument"
#Import "imagedocument"
#Import "audiodocument"
#Import "jsondocument"

#Import "eventfilters/textviewkeyeventfilter"

#Import "buildproduct"
#Import "editproductdialog"

#Import "mx2ccenv"

#Import "ted2go"


Namespace ted2go

Using std..
Using mojo..
Using mojox..


Global AppTitle:String = "Ted2Go"


Function Main()

#if __DESKTOP_TARGET__
		
	ChangeDir( AppDir() )
	
	While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory

		If IsRootDir( CurrentDir() )
			Print "Error initializing Ted2 - can't find working dir!"
			libc.exit_( 1 )
		Endif
		
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend
	
#endif
	
	Local jobj:=JsonObject.Load( "bin/ted2.state.json" )
	If Not jobj jobj=New JsonObject
	
	Local flags:=WindowFlags.Resizable
	
	Local rect:Recti
	
	If jobj.Contains( "windowRect" ) 
		rect=ToRecti( jobj["windowRect"] )
	Else
		rect=New Recti( 0,0,1024,768 )
		flags|=WindowFlags.Center
	Endif
	
	New AppInstance
	
	New MainWindowInstance( AppTitle,rect,flags,jobj )
	
	StartRedrawTimer()	
	
	App.Run()
	
	
End


Private

'redraw app to see flashing cursor
Function StartRedrawTimer()
	Local timer := New Timer(5, Lambda()
		App.RequestRender()
	End)
End
