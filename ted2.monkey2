
#If __TARGET__="desktop" and __HOSTOS__="windows"
#Import "bin/wget.exe"
#End

#Import "<std>"
#Import "<mojo>"
#Import "<mojox>"

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

#import "textviewkeyeventfilter"

#import "code2go/keywords"
'#import "views2go/codetextview"



Namespace ted2

Using std..
Using mojo..
Using mojox..
Using code2go
Using views2go


Function Main()

#if __TARGET__="desktop"
		
	ChangeDir( AppDir() )
	
	While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory

		If IsRootDir( CurrentDir() )
			Print "Error initializing Ted2 - can't find working dir!"
			libc.exit_( 1 )
		Endif
		
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend
	
#endif
	
	KeywordsManager.Init()
	
	Local jobj:=JsonObject.Load( "bin/ted2.state.json" )
	If Not jobj jobj=New JsonObject
	
	Local rect:=New Recti( 64,64,64+960,64+800 )
	If jobj.Contains( "windowRect" ) rect=ToRecti( jobj["windowRect"] )
	
	New AppInstance
	
	New MainWindowInstance( "Ted2",rect,WindowFlags.Resizable,jobj )
	
	App.Run()
End
