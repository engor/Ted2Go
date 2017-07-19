
Namespace ted2go


Function Json_LoadValue:JsonValue( filePath:String,key:String )
	
	If GetFileType(filePath) <> FileType.File Return Null
	
	Local json:=JsonObject.Load( filePath )
	
	Return Json_FindValue( json.Data,key )
End

Function Json_FindValue:JsonValue( data:StringMap<JsonValue>,key:String )
	
	key=key.Replace( "\","/" )
	Local keys:=key.Split( "/" )
	
	Local jval:JsonValue
	For Local k:=0 Until keys.Length
		jval=data[ keys[k] ]
		If Not jval Return Null
		If k=keys.Length-1 Exit
		If Not jval.IsObject Return Null
		data=jval.ToObject()
	Next
	
	Return jval
End

Function Json_GetBool:Bool( json:Map<String,JsonValue>,key:String,def:Bool )
	
	Return json[key] ? json[key].ToBool() Else def
End

Function Json_GetString:String( json:Map<String,JsonValue>,key:String,def:String )
	
	Return json[key] ? json[key].ToString() Else def
End

Function Json_GetInt:Int( json:Map<String,JsonValue>,key:String,def:Int )
	
	Return json[key] ? Int(json[key].ToNumber()) Else def
End
