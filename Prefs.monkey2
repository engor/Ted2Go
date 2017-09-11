Namespace ted2go


Const Prefs:=New PrefsInstance

Class PrefsInstance
	
	' AutoCompletion
	Field AcEnabled:=True
	Field AcKeywordsOnly:=False
	Field AcShowAfter:=2
	Field AcUseTab:=True
	Field AcUseEnter:=False
	Field AcUseSpace:=False
	Field AcUseDot:=False
	Field AcNewLineByEnter:=True
	Field AcStrongFirstChar:=True
	Field AcUseLiveTemplates:=True
	'
	Field MainToolBarVisible:=True
	Field MainProjectTabsRight:=True
	Field MainProjectIcons:=True
	'
	Field IrcNickname:String
	Field IrcServer:="irc.freenode.net"
	Field IrcPort:=6667
	Field IrcRooms:="#monkey2" '#mojox#mojo2d
	Field IrcConnect:Bool=False
	'
	Field EditorToolBarVisible:=False
	Field EditorGutterVisible:=True
	Field EditorShowWhiteSpaces:=False
	Field EditorFontPath:String
	Field EditorFontSize:=16
	Field EditorShowEvery10LineNumber:=True
	Field EditorCodeMapVisible:=True
	Field EditorAutoIndent:=True
	'
	Field SourceSortByType:=True
	Field SourceShowInherited:=False
	'
	Field MonkeyRootPath:String
	Field IdeHomeDir:String
	'	
	Field SiblyMode:Bool
	
	Property FindFilesFilter:String()
		Return _findFilter
	Setter( value:String )
		
		_findFilter=value
		SaveLocalState()
	End
	
	Method LoadState( json:JsonObject )
		
		If json.Contains( "irc" )
			
			Local j2:=json["irc"].ToObject()
			IrcNickname=Json_GetString( j2,"nickname",IrcNickname )
			IrcServer=Json_GetString( j2,"server",IrcServer )
			IrcPort=Json_GetInt( j2,"port",IrcPort )
			IrcRooms=Json_GetString( j2,"rooms",IrcRooms )
			IrcConnect=Json_GetBool( j2,"connect",IrcConnect )
			
		Endif
		
		If json.Contains( "main" )
			
			Local j2:=json["main"].ToObject()
			MainToolBarVisible=Json_GetBool( j2,"toolBarVisible",MainToolBarVisible )
			MainProjectTabsRight=Json_GetBool( j2,"tabsRight",MainProjectTabsRight )
			MainProjectIcons=Json_GetBool( j2,"projectIcons",MainProjectIcons )
      
		Endif
		
		If json.Contains( "completion" )
		
			Local j2:=json["completion"].ToObject()
			AcEnabled=j2["enabled"].ToBool()
			AcKeywordsOnly=j2["keywordsOnly"].ToBool()
			AcShowAfter=j2["showAfter"].ToNumber()
			AcUseTab=j2["useTab"].ToBool()
			AcUseEnter=j2["useEnter"].ToBool()
			AcUseSpace=Json_GetBool( j2,"useSpace",AcUseSpace )
			AcUseDot=Json_GetBool( j2,"useDot",AcUseDot )
			AcNewLineByEnter=Json_GetBool( j2,"newLineByEnter",AcNewLineByEnter )
			AcUseLiveTemplates=Json_GetBool( j2,"useLiveTemplates",AcUseLiveTemplates )
			
		Endif
		
		If json.Contains( "editor" )
		
			Local j2:=json["editor"].ToObject()
			EditorToolBarVisible=j2["toolBarVisible"].ToBool()
			EditorGutterVisible=j2["gutterVisible"].ToBool()
			EditorShowWhiteSpaces=Json_GetBool( j2,"showWhiteSpaces",EditorShowWhiteSpaces )
			EditorFontPath=Json_GetString( j2,"fontPath", EditorFontPath )
			EditorFontSize=Json_GetInt( j2,"fontSize",EditorFontSize )
			EditorShowEvery10LineNumber=Json_GetBool( j2,"showEvery10",EditorShowEvery10LineNumber )
			EditorCodeMapVisible=Json_GetBool( j2,"codeMapVisible",EditorCodeMapVisible )
			EditorAutoIndent=Json_GetBool( j2,"autoIndent",EditorAutoIndent )
			
		Endif
		
		If json.Contains( "source" )
		
			Local j2:=json["source"].ToObject()
			SourceSortByType=j2["sortByType"].ToBool()
			SourceShowInherited=j2["showInherited"].ToBool()
			
		Endif
		
		If json.Contains( "siblyMode" )
		
			SiblyMode=json["siblyMode"].ToBool()
		End
	
	End
	
	Method SaveState( json:JsonObject )
		
		Local j:=New JsonObject
		json["main"]=j
		j["toolBarVisible"]=New JsonBool( MainToolBarVisible )
		j["tabsRight"]=New JsonBool( MainProjectTabsRight )
		j["projectIcons"]=New JsonBool( MainProjectIcons )
		
		j=New JsonObject
		json["irc"]=j
		j["nickname"]=New JsonString( IrcNickname )
		j["server"]=New JsonString( IrcServer )
		j["port"]=New JsonNumber( IrcPort )
		j["rooms"]=New JsonString( IrcRooms )
		j["connect"]=New JsonBool( IrcConnect )
		
		j=New JsonObject
		json["completion"]=j
		j["enabled"]=New JsonBool( AcEnabled )
		j["keywordsOnly"]=New JsonBool( AcKeywordsOnly )
		j["showAfter"]=New JsonNumber( AcShowAfter )
		j["useTab"]=New JsonBool( AcUseTab )
		j["useEnter"]=New JsonBool( AcUseEnter )
		j["useSpace"]=New JsonBool( AcUseSpace )
		j["useDot"]=New JsonBool( AcUseDot )
		j["newLineByEnter"]=New JsonBool( AcNewLineByEnter )
		j["useLiveTemplates"]=New JsonBool( AcUseLiveTemplates )
		
		j=New JsonObject
		json["editor"]=j
		j["toolBarVisible"]=New JsonBool( EditorToolBarVisible )
		j["gutterVisible"]=New JsonBool( EditorGutterVisible )
		j["showWhiteSpaces"]=New JsonBool( EditorShowWhiteSpaces )
		j["fontPath"]=New JsonString( EditorFontPath )
		j["fontSize"]=New JsonNumber( EditorFontSize )
		j["showEvery10"]=New JsonBool( EditorShowEvery10LineNumber )
		j["codeMapVisible"]=New JsonBool( EditorCodeMapVisible )
		j["autoIndent"]=New JsonBool( EditorAutoIndent )
		
		j=New JsonObject
		json["source"]=j
		j["sortByType"]=New JsonBool( SourceSortByType )
		j["showInherited"]=New JsonBool( SourceShowInherited )
		
		If SiblyMode json["siblyMode"]=JsonBool.TrueValue
		
	End
	
	Method LoadLocalState()
		
		IdeHomeDir=HomeDir()+"Ted2Go/"
		CreateDir( IdeHomeDir )
		
		Local json:=JsonObject.Load( AppDir()+"state.json" )
		If Not json Return
		
		MonkeyRootPath=Json_GetString( json.Data,"rootPath","" )
		If Not MonkeyRootPath.EndsWith( "/" ) Then MonkeyRootPath+="/"
		
		FindFilesFilter=Json_GetString( json.Data,"findFilesFilter","monkey2,txt" )
	End
	
	Method SaveLocalState()
		
		If Not MonkeyRootPath.EndsWith( "/" ) Then MonkeyRootPath+="/"
		
		Local json:=New JsonObject
		json["rootPath"]=New JsonString( MonkeyRootPath )
		json["findFilesFilter"]=New JsonString( FindFilesFilter )
		json.Save( AppDir()+"state.json" )
		
	End
	
	Method GetCustomFontPath:String()
		
		If Not EditorFontPath Return ""
		If Not EditorFontPath.Contains( ".ttf" ) Return ""
		
		Local path:=EditorFontPath
		If Not path.Contains( ":" ) 'relative asset path
			path=AssetsDir()+path
		Endif
		
		Return path
	End
	
	Method GetCustomFontSize:Int()
	
		Return Max( EditorFontSize,6 ) '6 is a minimum
	End
	
	Private 
	
	Field _findFilter:String
	
End
