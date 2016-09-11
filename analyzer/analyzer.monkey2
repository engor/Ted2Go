
Namespace ted2go


Interface ICodeAnalyzer

	Method GetScope:ICodeItem(filePath:String,doc:TextDocument)
	'Property GetScope:ICodeItem(filePath:String,doc.TextDocument)
	
End


Class CodeAnalyzer Implements ICodeAnalyzer

	Method GetScope:ICodeItem(filePath:String,doc:TextDocument)
		Local item := New CodeItem("")
		
		Return item
	End
	
	
	Private
	
	
End
