
Namespace ted2go


Class View Extension
	
	Method GetStyle:Style( styleName:String,parentStyleName:String )
		
		Local st:=Self.GetStyle( styleName )
		If Not st Then st=Self.GetStyle( parentStyleName )
		
		Return st
	End
	
End
