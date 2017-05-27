
Namespace ted2go


Class JsonUtils

	Function LoadValue:JsonValue( filePath:String,key:String )
		
		If GetFileType(filePath) <> FileType.File Return Null
		
		Local json:=JsonObject.Load( filePath )
		
		Return FindValue( json.Data,key )
	End
	
	Function FindValue:JsonValue( data:StringMap<JsonValue>,key:String )
	
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
	
	Private 
	
	Method New()
	End
	
End
