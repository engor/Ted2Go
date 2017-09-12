
Namespace ted2go


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:Stack<CodeItem>()
		Return _items
	End
	
	Property ItemsMap:StringMap<Stack<CodeItem>>()
		Return _itemsMap
	End
	
	Property UsingsMap:StringMap<UsingInfo>()
		Return _usingsMap
	End
	
	Method CheckStartsWith:Bool( ident1:String,ident2:String ) Virtual
	
		ident1=ident1.ToLower()
		ident2=ident2.ToLower()
		
		Return ident1.StartsWith( ident2 )
	End
	
	
	Protected
	
	Method New()
		AddPlugin( Self )
	End
	
	
	Private
	
	Field _items:=New Stack<CodeItem>
	Field _itemsMap:=New StringMap<Stack<CodeItem>>
	Field _usingsMap:=New StringMap<UsingInfo>
	
End
