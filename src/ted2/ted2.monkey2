
#If __TARGET__="windows"
#Import "bin/wget.exe"
#End

#Import "<reflection>"

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
#Import "jsontreeview"
#Import "xmltreeview"
#Import "monkey2treeview"
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
	
	'load ted2 state
	'
	Local jobj:=JsonObject.Load( "bin/ted2.state.json" )
	If Not jobj jobj=New JsonObject

	'initial theme
	'	
	If Not jobj.Contains( "theme" ) jobj["theme"]=New JsonString( "theme-classic-dark" )
	If Not jobj.Contains( "themeScale" ) jobj["themeScale"]=New JsonNumber( 1 )
	
	Local config:=New StringMap<String>
	
	config["initialTheme"]=jobj.GetString( "theme" )
	config["initialThemeScale"]=jobj.GetNumber( "themeScale" )
	
	'initial window state
	'
	Local flags:=WindowFlags.Resizable|WindowFlags.HighDPI

	Local rect:Recti
	
	If jobj.Contains( "windowRect" ) 
		rect=ToRecti( jobj["windowRect"] )
	Else
		rect=New Recti( 0,0,1024,768 )
		flags|=WindowFlags.Center
	Endif

	'start the app!
	'	
	New AppInstance( config )
	
	New MainWindowInstance( "Ted2",rect,flags,jobj )
	
	App.Run()
End
