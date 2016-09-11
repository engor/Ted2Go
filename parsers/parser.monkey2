
Namespace ted2go


Enum CodeItemKind
	Classs,
	Interfacee,
	Enumm,
	Structt,
	Fieldd,
	Globall,
	Constt,
	Methodd,
	Functionn,
	Param
End

Enum AccessMode
	Privatee,
	Protectedd,
	Publicc
End


Interface ICodeItem
	
	Property Ident:String()
	Property Indent:Int()
	Property Type:String()
	Property Params:String[]()
	Property Kind:CodeItemKind()
	Property Access:AccessMode()
	Property Text:String()
	Property Parent:ICodeItem()
	Property Children:List<ICodeItem>()
	Setter(value:List<ICodeItem>)
	Property Namespac:String()
	Property FilePath:String()
	
End


Class CodeItem Implements ICodeItem
	
	Method New(ident:String)
		_ident = ident
	End
	
	Property Ident:String()
		Return _ident
	End
	Property Indent:Int()
		Return _indent
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
	Property Access:AccessMode()
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
	Setter(value:List<ICodeItem>)
		_children = value
	End
	Property Namespac:String()
		Return _namespace
	End
	Property FilePath:String()
		Return _filePath
	End
	
	Method SetParent(parent:ICodeItem)
		If Parent <> Null Then Parent.Children.Remove(Self)
		_parent = parent
		If _parent.Children = Null Then _parent.Children = New List<ICodeItem>
		_parent.Children.AddLast(Self)
	End
	
	'Protected
	
	Field _ident:String
	Field _indent:Int
	Field _type:String
	Field _params:String[]
	Field _kind:CodeItemKind
	Field _access:AccessMode
	Field _text:String
	Field _parent:ICodeItem
	Field _children:List<ICodeItem>
	Field _namespace:String
	Field _filePath:String
	
End


Class ClassCodeItem

	'Method New(ident:String, type:String, params:String[], kind:CodeItemKind, access:AccessMode,
	
End


Interface ICodeParser

	'Method Reset(filePath:String)
	Method Parse(text:String, filePath:String)
	Property Items:List<ICodeItem>()
	
End


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:List<ICodeItem>()
		Return _items
	End
	
	Method Reset(filePath:String) Virtual
	
	End
	
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
	
	
	Protected
	
	Field _items := New List<ICodeItem>
	
	
	Private
	
End


Class ParsersManager
	
	Function Get:ICodeParser(fileType:String)
		Local plugins := Plugin.PluginsOfType<CodeParserPlugin>()
		For Local p := Eachin plugins
			If p.CheckFileTypeSuitability(fileType) Then Return p
		Next
		Return _empty
	End

	
	Private
	
	Global _empty := New EmptyParser
	
End


Private

Class EmptyParser Implements ICodeParser

	Property Items:List<ICodeItem>()
		Return _items
	End
	
	Method Parse(text:String, filePath:String)
		'do nothing
	End
		
	
	Private
	
	Field _items := New List<ICodeItem>
	
End
