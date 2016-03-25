
#Import "<std>"

Using std.json

Function Main()

	Local arr:=New JsonArray
	For Local i:=0 Until 10
		arr.Data.Push( New JsonNumber( i ) )
	Next

	Local json:JsonValue=New JsonObject
	
	json["bool_value"]=JsonBool.TrueValue
	json["number_value"]=New JsonNumber( 10 )
	json["string_value"]=New JsonString( "Hello!" )
	json["array_value"]=arr
	
	Print json["bool_value"] ? "true" Else "false"	'true
	Print json["number_value"].ToInt()				'10
	Print json["string_value"].ToString()			'"Hello!"
	Print json["array_value"][5].ToInt()			'5
	
	Local str:=json.ToJson()
	
	Print "JSON="+str								'JSON={"array_value":[0,1,2,3,4,5,6,7,8,9],"bool_value":true,"number_value":10,"string_value":"Hello!"}
	
	Local parser:=New JsonParser( str )
	
	json=parser.ParseJson()
	
	str=json.ToJson()
	
	Print "JSON="+str								'JSON={"array_value":[0,1,2,3,4,5,6,7,8,9],"bool_value":true,"number_value":10,"string_value":"Hello!"}
	
End
