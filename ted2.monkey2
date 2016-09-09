
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
#Import "eventfilters/monkey2keyeventfilter"

#Import "syntax/keywords"
#Import "syntax/monkey2keywords"
#Import "syntax/highlighter"
#Import "syntax/monkey2highlighter"
#Import "syntax/cpphighlighter"
#Import "syntax/cppkeywords"
#Import "syntax/codeformatter"
#Import "syntax/monkey2formatter"

#Import "views/textviewext"
#Import "views/codetextview"
#Import "views/consoleext"
#Import "views/listview"
#Import "views/dialogext"
#Import "views/autocompleteview"

#Import "parsers/parser"
#Import "parsers/monkey2parser"

#Import "utils/jsonutils"
#Import "utils/utils"


Namespace ted2go

Using std..
Using mojo..
Using mojox..


Function Main()

#if __TARGET__="windows"
		
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
	
	Local rect:=New Recti( 64,64,64+960,64+800 )
	If jobj.Contains( "windowRect" ) rect=ToRecti( jobj["windowRect"] )
	
	New AppInstance
	
	New MainWindowInstance( "Ted2Go",rect,WindowFlags.Resizable,jobj )
	
	App.Run()
End
