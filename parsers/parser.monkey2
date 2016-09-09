
Namespace ted2go


Enum CodeItemKind
	Fieldd,
	Globall,
	Constt,
	Methodd,
	Functionn,
	Param
End

Enum AccessKind
	Privatee,
	Protectedd,
	Publicc
End


Interface ICodeItem
	
	Property Ident:String()
	Property Type:String()
	Property Params:String[]()
	Property Kind:CodeItemKind()
	Property Access:AccessKind()
	Property Text:String()
	Property Parent:ICodeItem()
	Property Children:List<ICodeItem>()
	
End


Class CodeItem Implements ICodeItem
	
	Property Ident:String()
		Return _ident
	End
	Property Type:String()
		Return _type
	End
	Property Params:String[]()
		Return _params
	End
	Property Kind:CodeItemKind()
		Return _kind
	End
	Property Access:AccessKind()
		Return _access
	End
	Property Text:String()
		Return _text
	End
	Property Parent:ICodeItem()
		Return _parent
	End
	Property Children:List<ICodeItem>()
		Return _children
	End
	
	Private
	
	Field _ident:String
	Field _type:String
	Field _params:String[]
	Field _kind:CodeItemKind
	Field _access:AccessKind
	Field _text:String
	Field _parent:ICodeItem
	Field _children:List<ICodeItem>
	
End



Interface ICodeParser

	Method Parse(doc:TextDocument)
	
End


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:List<ICodeItem>()
		Return _items
	End
	
	Method Parse(doc:TextDocument) Virtual
	
	End
	
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
	
	
	Protected
	
	Field _items := New List<ICodeItem>
	
	
	Private
	
End
