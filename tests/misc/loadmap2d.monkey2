
#Import "<std>"

#Import "map2d.json"

Using std.json

Function LoadMap2d:Int[,]( path:String )

	Local json:=JsonValue.Load( path )
	
	Local w:=json["width"].ToInt()
	Local h:=json["height"].ToInt()
	
	Local map:=New Int[w,h]
	
	For Local y:=0 Until h
		For Local x:=0 Until w
			map[x,y]=json["data"][y][x].ToInt()
		Next
	Next
	
	Return map
End

Function Main()

	Local map:=LoadMap2d( "asset::map2d.json" )
	
	Local w:=map.Size( 0 )
	Local h:=map.Size( 1 )
	
	Print "w="+w
	Print "h="+h

	For Local y:=0 Until h
		Local str:=""
		For Local x:=0 Until w
			str+=","+map[x,y]
		Next
		Print str.Slice( 1 )
	Next

End
