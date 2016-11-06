
Namespace ted2go


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:List<CodeItem>()
		Return _items
	End
	
	Property ItemsMap:StringMap<List<CodeItem>>()
		Return _itemsMap
	End
	
	
	Protected
	
	Method New()
		AddPlugin( Self )
	End
	
	
	Private
	
	Field _items:=New List<CodeItem>
	Field _itemsMap:=New StringMap<List<CodeItem>>
	
End
