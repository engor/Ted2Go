Namespace ted2go


Class Prefs
	
	' AutoCompletion
	Global AcEnabled:=True
	Global AcKeywordsOnly:=False
	Global AcShowAfter:=2
	Global AcUseTab:=True
	Global AcUseEnter:=False
	Global AcUseSpace:=True
	Global AcNewLineByEnter:=True
	'
	Global MainToolBarVisible:=True
	Global EditorToolBarVisible:=True
	Global EditorGutterVisible:=True
	Global EditorShowWhiteSpaces:=False
	Global EditorFontName:String
	Global EditorFontSize:String
	'
	Global SourceSortByType:=True
	Global SourceShowInherited:=False
	
	
	Function LoadState( json:JsonObject )
		
		If json.Contains( "completion" )
		
			Local j2:=json["completion"].ToObject()
			AcEnabled=j2["enabled"].ToBool()
			AcKeywordsOnly=j2["keywordsOnly"].ToBool()
			AcShowAfter=j2["showAfter"].ToNumber()
			AcUseTab=j2["useTab"].ToBool()
			AcUseEnter=j2["useEnter"].ToBool()
			AcUseSpace=GetJsonBool( j2,"useSpace",AcUseSpace )
			AcNewLineByEnter=j2["newLineByEnter"].ToBool()
			
		Endif
		
		If json.Contains( "mainToolBarVisible" )
		
			MainToolBarVisible=json["mainToolBarVisible"].ToBool()
		
		Endif
		
		If json.Contains( "editor" )
		
			Local j2:=json["editor"].ToObject()
			EditorToolBarVisible=j2["toolBarVisible"].ToBool()
			EditorGutterVisible=j2["gutterVisible"].ToBool()
			EditorShowWhiteSpaces=GetJsonBool( j2,"showWhiteSpaces",EditorShowWhiteSpaces )
			If j2.Contains("fontName") Then EditorFontName=j2["fontName"].ToString()
			If j2.Contains("fontSize") Then EditorFontSize=j2["fontSize"].ToString()
			
		Endif
		
		If json.Contains( "source" )
		
			Local j2:=json["source"].ToObject()
			SourceSortByType=j2["sortByType"].ToBool()
			SourceShowInherited=j2["showInherited"].ToBool()
			
		Endif
	End
	
	Function SaveState( json:JsonObject )
		
		Local j:=New JsonObject
		j["enabled"]=New JsonBool( AcEnabled )
		j["keywordsOnly"]=New JsonBool( AcKeywordsOnly )
		j["showAfter"]=New JsonNumber( AcShowAfter )
		j["useTab"]=New JsonBool( AcUseTab )
		j["useEnter"]=New JsonBool( AcUseEnter )
		j["useSpace"]=New JsonBool( AcUseSpace )
		j["newLineByEnter"]=New JsonBool( AcNewLineByEnter )
		json["completion"]=j
		
		json["mainToolBarVisible"]=New JsonBool( MainToolBarVisible )
		
		j=New JsonObject
		j["toolBarVisible"]=New JsonBool( EditorToolBarVisible )
		j["gutterVisible"]=New JsonBool( EditorGutterVisible )
		j["showWhiteSpaces"]=New JsonBool( EditorShowWhiteSpaces )
		j["fontName"]=New JsonString( EditorFontName )
		j["fontSize"]=New JsonString( EditorFontSize )
		json["editor"]=j
		
		j=New JsonObject
		j["sortByType"]=New JsonBool( SourceSortByType )
		j["showInherited"]=New JsonBool( SourceShowInherited )
		json["source"]=j
	End
	
End


Function GetJsonBool:Bool( json:Map<String,JsonValue>,key:String,def:Bool )
	
	Return json[key] ? json[key].ToBool() Else def
End
