
Namespace ted2go


Enum CodeItemKind
	Undefined,
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
	PrivateInClass,
	ProtectedInClass,
	PublicInClass,
	PublicInFile,
	PrivateInFile
End


Interface ICodeItem
	
	Property Ident:String()
	Setter(value:String)
	
	Property Indent:Int()
	Setter(value:Int)
	
	Property Type:String()
	Setter(value:String)
	
	Property Params:String[]()
	Setter(value:String[])
	
	Property Kind:CodeItemKind()
	Setter(value:CodeItemKind)
	
	Property KindStr:String()
	Setter(value:String)
	
	Property Access:AccessMode()
	Setter(value:AccessMode)
	
	Property Text:String()
	Setter(value:String)
	
	Property Parent:ICodeItem()
	Setter(value:ICodeItem)
	
	Property Children:List<ICodeItem>()
	Setter(value:List<ICodeItem>)
	
	Property Namespac:String()
	Setter(value:String)
	
	Property FilePath:String()
	Setter(value:String)
	
	Property Scope:String()
	
	Method AddChild(item:ICodeItem)
	
End


Class CodeItem Implements ICodeItem
	
	Method New(ident:String)
		_ident = ident
	End
	
	Property Ident:String()
		Return _ident
	Setter(value:String)
		_ident = value
	End
	
	Property Indent:Int()
		Return _indent
	Setter(value:Int)
		_indent = value
	End
	
	Property Type:String()
		Return _type
	Setter(value:String)
		_type = value
	End
	
	Property Params:String[]()
		Return _params
	Setter(value:String[])
		_params = value
	End
	
	Property Kind:CodeItemKind()
		Return _kind
	Setter(value:CodeItemKind)
		_kind = value
	End
	
	Property KindStr:String()
		Return _kindStr
	Setter(value:String)
		_kindStr = value
	End
	
	Property Access:AccessMode()
		Return _access
	Setter(value:AccessMode)
		_access = value
	End
	
	Property Text:String()
		Return _text
	Setter(value:String)
		_text = value
	End
	
	Property Parent:ICodeItem()
		Return _parent
	Setter(value:ICodeItem)
		SetParent(value)
	End
	
	Property Children:List<ICodeItem>()
		Return _children
	Setter(value:List<ICodeItem>)
		_children = value
	End
	
	Property Namespac:String()
		Return _namespace
	Setter(value:String)
		_namespace = value
	End
	
	Property FilePath:String()
		Return _filePath
	Setter(value:String)
		_filePath = value
	End
	
	Property Scope:String()
		Local s := Ident
		Local i := Parent
		While i <> Null
			s = i.Ident+"."+s
			i = i.Parent
		Wend
		Return s
	End
	
	Method SetParent(parent:ICodeItem)
		If Parent <> Null Then Parent.Children.Remove(Self)
		_parent = parent
		If _parent.Children = Null Then _parent.Children = New List<ICodeItem>
		_parent.Children.AddLast(Self)
	End
	
	Method AddChild(item:ICodeItem)
		item.Parent = Self
	End
	
	
	Protected
	
	Field _ident:String
	Field _indent:Int
	Field _type:String
	Field _params:String[]
	Field _kind:CodeItemKind
	Field _kindStr:String
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

	Method Parse(text:String, filePath:String)
	Method IsPosInsideOfQuotes:Bool(text:String, pos:Int)
	Property Items:List<ICodeItem>()
	
End


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:List<ICodeItem>()
		Return _items
	End
	
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
	
	
	Private
	
	Field _items := New List<ICodeItem>
	
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
	Method IsPosInsideOfQuotes:Bool(text:String, pos:Int)
		Return False
	End	
	
	Private
	
	Field _items := New List<ICodeItem>
	
End
