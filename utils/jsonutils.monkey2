
Namespace ted2go


Class JsonUtils

	Function LoadValue:JsonValue( filePath:String,valueName:String )
		
		If GetFileType(filePath) <> FileType.File Then Return Null
		
		Local json:=JsonObject.Load( filePath )
		
		Return json[valueName]
	End
	
	
	Private 
	
	Method New()
	End
	
End
