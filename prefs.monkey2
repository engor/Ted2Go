Namespace ted2go


Class Prefs
	
	' AutoCompletion
	Global AcEnabled:=True
	Global AcKeywordsOnly:=False
	Global AcShowAfter:=2
	Global AcUseTab:=True
	Global AcUseEnter:=False
	Global AcUseSpace:=True
	Global AcUseDot:=False
	Global AcNewLineByEnter:=True
	'
	Global MainToolBarVisible:=True
	Global MainProjectTabsRight:=True
	'
	Global EditorToolBarVisible:=False
	Global EditorGutterVisible:=True
	Global EditorShowWhiteSpaces:=False
	Global EditorFontPath:String
	Global EditorFontSize:=16
	'
	Global SourceSortByType:=True
	Global SourceShowInherited:=False
	
	
	Function LoadState( json:JsonObject )
		
		If json.Contains( "main" )
			
			Local j2:=json["main"].ToObject()
			If j2.Contains( "toolBarVisible" ) Then MainToolBarVisible=j2["toolBarVisible"].ToBool()
			If j2.Contains( "tabsRight" ) Then MainProjectTabsRight=j2["tabsRight"].ToBool()
		
		Endif
		
		If json.Contains( "completion" )
		
			Local j2:=json["completion"].ToObject()
			AcEnabled=j2["enabled"].ToBool()
			AcKeywordsOnly=j2["keywordsOnly"].ToBool()
			AcShowAfter=j2["showAfter"].ToNumber()
			AcUseTab=j2["useTab"].ToBool()
			AcUseEnter=j2["useEnter"].ToBool()
			AcUseSpace=GetJsonBool( j2,"useSpace",AcUseSpace )
			AcUseDot=GetJsonBool( j2,"useDot",AcUseDot )
			AcNewLineByEnter=j2["newLineByEnter"].ToBool()
			
		Endif
		
		If json.Contains( "editor" )
		
			Local j2:=json["editor"].ToObject()
			EditorToolBarVisible=j2["toolBarVisible"].ToBool()
			EditorGutterVisible=j2["gutterVisible"].ToBool()
			EditorShowWhiteSpaces=GetJsonBool( j2,"showWhiteSpaces",EditorShowWhiteSpaces )
			If j2.Contains("fontPath") Then EditorFontPath=j2["fontPath"].ToString()
			If j2.Contains("fontSize") Then EditorFontSize=Int( j2["fontSize"].ToNumber() )
			
		Endif
		
		If json.Contains( "source" )
		
			Local j2:=json["source"].ToObject()
			SourceSortByType=j2["sortByType"].ToBool()
			SourceShowInherited=j2["showInherited"].ToBool()
			
		Endif
	End
	
	Function SaveState( json:JsonObject )
		
		Local j:=New JsonObject
		j["toolBarVisible"]=New JsonBool( MainToolBarVisible )
		j["tabsRight"]=New JsonBool( MainProjectTabsRight )
		json["main"]=j
		 
		j=New JsonObject
		j["enabled"]=New JsonBool( AcEnabled )
		j["keywordsOnly"]=New JsonBool( AcKeywordsOnly )
		j["showAfter"]=New JsonNumber( AcShowAfter )
		j["useTab"]=New JsonBool( AcUseTab )
		j["useEnter"]=New JsonBool( AcUseEnter )
		j["useSpace"]=New JsonBool( AcUseSpace )
		j["useDot"]=New JsonBool( AcUseDot )
		j["newLineByEnter"]=New JsonBool( AcNewLineByEnter )
		json["completion"]=j
		
		j=New JsonObject
		j["toolBarVisible"]=New JsonBool( EditorToolBarVisible )
		j["gutterVisible"]=New JsonBool( EditorGutterVisible )
		j["showWhiteSpaces"]=New JsonBool( EditorShowWhiteSpaces )
		j["fontPath"]=New JsonString( EditorFontPath )
		j["fontSize"]=New JsonNumber( EditorFontSize )
		json["editor"]=j
		
		j=New JsonObject
		j["sortByType"]=New JsonBool( SourceSortByType )
		j["showInherited"]=New JsonBool( SourceShowInherited )
		json["source"]=j
	End
	
	Function GetCustomFontPath:String()
		
		If Not EditorFontPath Return ""
		If Not EditorFontPath.Contains( ".ttf" ) Return ""
		
		Local path:=EditorFontPath
		If Not path.Contains( ":" ) 'relative asset path
			path=AssetsDir()+path
		Endif
		
		Return path
	End
	
	Function GetCustomFontSize:Int()
	
		Return Max( EditorFontSize,6 ) '6 is a minumal
	End
End


Function GetJsonBool:Bool( json:Map<String,JsonValue>,key:String,def:Bool )
	
	Return json[key] ? json[key].ToBool() Else def
End
