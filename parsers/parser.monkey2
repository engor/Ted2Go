
Namespace ted2go


Enum CodeItemKind
	Undefine_,
	Class_,
	Interface_,
	Enum_,
	Struct_,
	Field_,
	Global_,
	Const_,
	Method_,
	Function_,
	Property_,
	Param_,
	Lambda_,
	Local_,
	Operator_,
	Inner_
End

Enum AccessMode
	Private_,
	Protected_,
	Public_
End


Interface ICodeItem
	
	Property Ident:String()
	Setter(value:String)
	
	Property Indent:Int()
	Setter(value:Int)
	
	Property Type:String()
	Setter(value:String)
	
	Property RawType:String()
	Setter(value:String)
	
	Property Params:String[]()
	Setter(value:String[])
	
	Property ParamsStr:String()
	Setter(value:String)
	
	Property Kind:CodeItemKind()
	Setter(value:CodeItemKind)
	
	Property KindStr:String()
	Setter(value:String)
	
	Property Access:AccessMode()
	Setter(value:AccessMode)
	
	Property Text:String()
	'Setter(value:String)
	
	Property Parent:ICodeItem()
	Setter(value:ICodeItem)
	
	Property Root:ICodeItem()
	
	Property Children:List<ICodeItem>()
	Setter(value:List<ICodeItem>)
	
	Property Namespac:String()
	Setter(value:String)
	
	Property FilePath:String()
	Setter(value:String)
	
	Property Scope:String()
	
	Property ScopeStartLine:Int()
	Setter(value:Int)
	
	Property ScopeEndLine:Int()
	Setter(value:Int)
	
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
	
	Property RawType:String()
		Return _rawType
	Setter(value:String)
		_rawType = value
		_text = Null 'reset
	End
	
	Property Params:String[]()
		Return _params
	Setter(value:String[])
		_params = value
	End
	
	Property ParamsStr:String()
		Return _paramsStr
	Setter(value:String)
		_paramsStr = value
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
		UpdateKind()
	End
	
	Property Access:AccessMode()
		Return _access
	Setter(value:AccessMode)
		_access = value
	End
	
	Property Text:String()
		If _text = Null
			Local s := Ident
			Select _kind
				Case CodeItemKind.Function_, CodeItemKind.Method_, CodeItemKind.Lambda_, CodeItemKind.Operator_
					If Type <> Null And Type <> "" And Type <> "Void"
						s += " : "+Type
					Endif
					s += (ParamsStr = Null) ? " ()" Else " ("+ParamsStr+")"
				Case CodeItemKind.Class_, CodeItemKind.Interface_, CodeItemKind.Struct_, CodeItemKind.Enum_, CodeItemKind.Property_, CodeItemKind.Inner_
					'do nothing
				Default
					' for enums
					If Parent = Null Or Parent.Kind <> CodeItemKind.Enum_
						s += " : "+Type
					Endif
			End
			_text = s
		Endif
		Return _text
	'Setter(value:String)
	'	_text = value
	End
	
	Property Parent:ICodeItem()
		Return _parent
	Setter(value:ICodeItem)
		SetParent(value)
	End
	
	Property Root:ICodeItem()
		
		Local par:ICodeItem = Null
		Local i := Parent
		While i <> Null
			par = i
			i = i.Parent
		Wend
		Return (par <> Null) ? par Else Self
		
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
	
	Property ScopeStartLine:Int()
		Return _scopeStartLine
	Setter(value:Int)
		_scopeStartLine = value
	End
	
	Property ScopeEndLine:Int()
		Return (_scopeEndLine <> -1) ? _scopeEndLine Else _scopeStartLine
	Setter(value:Int)
		_scopeEndLine = value
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
	Field _type:String, _rawType:String
	Field _params:String[]
	Field _paramsStr:String
	Field _kind:CodeItemKind
	Field _kindStr:String
	Field _access:AccessMode
	Field _text:String
	Field _parent:ICodeItem
	Field _children:List<ICodeItem>
	Field _namespace:String
	Field _filePath:String
	Field _scopeStartLine:Int, _scopeEndLine:Int=-1
	
	
	Private
	
	Method UpdateKind()
		Select _kindStr
		Case "function"
			_kind = CodeItemKind.Function_
		Case "method"
			_kind = CodeItemKind.Method_
		Case "interface"
			_kind = CodeItemKind.Interface_
		Case "enum"
			_kind = CodeItemKind.Enum_
		Case "struct"
			_kind = CodeItemKind.Struct_
		Case "field"
			_kind = CodeItemKind.Field_
		Case "global"
			_kind = CodeItemKind.Global_
		Case "const"
			_kind = CodeItemKind.Const_
		Case "param"
			_kind = CodeItemKind.Param_
		Case "class"
			_kind = CodeItemKind.Class_
		Case "property"
			_kind = CodeItemKind.Property_
		Case "lambda"
			_kind = CodeItemKind.Lambda_
		Case "local"
			_kind = CodeItemKind.Local_
		Case "operator"
			_kind = CodeItemKind.Operator_
		Case "for","select","while"
			_kind = CodeItemKind.Inner_
		End
	End
	
End



Interface ICodeParser

	Method RefineRawType(item:ICodeItem)
	Method Parse(text:String, filePath:String)
	Method IsPosInsideOfQuotes:Bool(text:String, pos:Int)
	Method CanShowAutocomplete:Bool(line:String, posInLine:Int)
	Method GetScope:ICodeItem(docPath:String, docLine:Int)
	Method ItemAtScope:ICodeItem(scope:ICodeItem, idents:String[])
	Property Items:List<ICodeItem>()
	Property ItemsMap:StringMap<List<ICodeItem>>()
	
End


Class CodeParserPlugin Extends PluginDependsOnFileType Implements ICodeParser

	Property Name:String() Override
		Return "CodeParserPlugin"
	End
	
	Property Items:List<ICodeItem>()
		Return _items
	End
	
	Property ItemsMap:StringMap<List<ICodeItem>>()
		Return _itemsMap
	End
	
	
	Protected
	
	Method New()
		AddPlugin(Self)
	End
	
	
	Private
	
	Field _items := New List<ICodeItem>
	Field _itemsMap := New StringMap<List<ICodeItem>>
	
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
	
	Property ItemsMap:StringMap<List<ICodeItem>>()
		Return _itemsMap
	End
	
	Method Parse(text:String, filePath:String)
		'do nothing
	End
	Method IsPosInsideOfQuotes:Bool(text:String, pos:Int)
		Return False
	End
	Method CanShowAutocomplete:Bool(line:String, posInLine:Int)
		Return False
	End
	Method GetScope:ICodeItem(docPath:String, docLine:Int)
		Return Null
	End
	Method ItemAtScope:ICodeItem(scope:ICodeItem, idents:String[])
		Return Null
	End
	Method RefineRawType(item:ICodeItem)
	End
	
	
	Private
	
	Field _items := New List<ICodeItem>
	Field _itemsMap := New StringMap<List<ICodeItem>>
	
End
