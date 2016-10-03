
#If __TARGET__="windows"
#Import "bin/wget.exe"
#End

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"
#Import "<tinyxml2>"

#Import "mainwindow"
#Import "documentmanager"
#import "fileactions"
#import "editactions"
#import "findactions"
#import "finddialog"
#import "buildactions"
#import "helpactions"
#import "debugview"
#import "projectview"
#import "helptree"
#Import "modulemanager"
#import "ted2textview"
#Import "gutterview"

#import "plugin"
#Import "ted2document"
#Import "monkey2document"
#Import "plaintextdocument"
#Import "imagedocument"
#import "audiodocument"
#import "jsondocument"
#import "xmldocument"

#import "textviewkeyeventfilter"

#Import "buildproduct"
#Import "editproductdialog"

#Import "mx2ccenv"

Namespace ted2

Using std..
Using mojo..
Using mojox..
Using tinyxml2..

Function Main()

#If __DESKTOP_TARGET__
		
	ChangeDir( AppDir() )
	
	While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory

		If IsRootDir( CurrentDir() )
			Print "Error initializing Ted2 - can't find working dir!"
			libc.exit_( 1 )
		Endif
		
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend
	
#Endif
	
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
	
	New MainWindowInstance( "Ted2",rect,flags,jobj )
	
	App.Run()
End
