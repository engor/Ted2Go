
Namespace ted2go


Class CodeItem
	
	Method New( ident:String )
		_ident=ident
	End
	
	Property Ident:String()
		Return _ident
	Setter( value:String )
		_ident=value
	End
	
	Property Indent:Int()
		Return _indent
	Setter( value:Int )
		_indent=value
	End
	
	Property Type:CodeType()
		Return _type
	Setter( value:CodeType )
		_type=value
	End
		
	Property Kind:CodeItemKind()
		Return _kind
	Setter( value:CodeItemKind )
		_kind=value
	End
	
	Property KindStr:String()
		Return _kindStr
	Setter( value:String )
		_kindStr=value
		UpdateKind()
	End
	
	Property Access:AccessMode()
		Return _access
	Setter( value:AccessMode )
		_access=value
	End
	
	Property AccessStr:String()
		If _access = AccessMode.Public_
			Return "public"
		Elseif _access = AccessMode.Protected_
			Return "protected"
		Else
			Return "private"
		Endif
	End
	
	Property Text:String()
		If _text = Null
			Local s:=Ident
			Select _kind
				Case CodeItemKind.Function_,CodeItemKind.Method_,CodeItemKind.Lambda_,CodeItemKind.Operator_
					If Type<>Null And Type.ident<>"void"
						s+=" : "+Type.ident
					Endif
					s+=(HasParams ? " ("+ParamsStr+")" Else " ()")
				Case CodeItemKind.Class_,CodeItemKind.Interface_,CodeItemKind.Struct_,CodeItemKind.Enum_
					' nothing
				Case CodeItemKind.Inner_
					' nothing
				Case CodeItemKind.Property_
					s+=" : "+Type.ident
				Default
					' for enums
					If Parent = Null Or Parent.Kind <> CodeItemKind.Enum_
						s+=" : "+Type.ident
					Endif
			End
			_text=s
		Endif
		Return _text
	End
	
	Property Parent:CodeItem()
		Return _parent
	Setter( value:CodeItem )
		SetParent( value )
	End
	
	Property Root:CodeItem()
		
		Local par:CodeItem=Null
		Local i:=Parent
		While i <> Null
			par=i
			i=i.Parent
		Wend
		Return (par <> Null) ? par Else Self
		
	End
	
	Property Children:List<CodeItem>()
		Return _children
	Setter( value:List<CodeItem> )
		_children=value
	End
	
	Property Namespac:String()
		Return _namespace
	Setter( value:String )
		_namespace=value
	End
	
	Property FilePath:String()
		Return _filePath
	Setter( value:String )
		_filePath=value
	End
	
	Property Scope:String()
		Local s:=Ident
		Local i:=Parent
		While i <> Null
			s=i.Ident+"."+s
			i=i.Parent
		Wend
		Return s
	End
	
	Property ScopeStartPos:Vec2i()
		Return _scopeStartPos
	Setter( value:Vec2i )
		_scopeStartPos=value
	End
	
	Property ScopeEndPos:Vec2i()
		Return _scopeEndPos
	Setter( value:Vec2i )
		_scopeEndPos=value
	End
	
	Method SetParent( parent:CodeItem )
		If Parent <> Null Then Parent.Children.Remove( Self )
		_parent=parent
		If _parent.Children = Null Then _parent.Children = New List<CodeItem>
		_parent.Children.AddLast( Self )
	End
	
	Method AddChild( item:CodeItem )
		item.Parent=Self
	End
	
	Property SuperTypes:List<CodeType>()
		Return _superTypes
	Setter( value:List<CodeType> )
		_superTypes=value
	End
	
	Method AddSuperType( type:CodeType )
		If Not _superTypes Then _superTypes=New List<CodeType>
		_superTypes.AddLast( type )
	End
	
	Method FindParent:CodeItem( parentIdent:String )
		Local p:=Parent
		While p <> Null
			If p.Ident = parentIdent Return p
			p=p.Parent
		Wend
		Return Null
	End
	
	Method HasSuchSuperClass:Bool( ident:String )
		If Not _superTypes Return False
		For Local t:=Eachin _superTypes
			If t.ident = ident Return True
		Next
		Return False
	End
	
	Property NearestClassScope:CodeItem()
		Local p:=Self
		While p <> Null
			Select p.Kind
			Case CodeItemKind.Class_,CodeItemKind.Interface_,CodeItemKind.Struct_
				Return p
			End
			p=p.Parent
		Wend
		Return Null
	End
	
	Property HasParams:Bool()
		Return _params<>Null
	End
	
	Property Params:CodeType[]()
		Return _params
	Setter( value:CodeType[] )
		_params=value
	End
	
	Property ParamsStr:String()
		
		If Not _params Return Null
		If _paramsStr Return _paramsStr
		
		_paramsStr=""
		For Local p:=Eachin _params
			If _paramsStr<>"" Then _paramsStr+=","
			_paramsStr+=p.ident
		Next
		Return _paramsStr
	End
	
	
	Private
	
	Field _ident:String
	Field _indent:Int
	Field _type:CodeType
	Field _kind:CodeItemKind
	Field _kindStr:String
	Field _access:=AccessMode.Public_
	Field _text:String
	Field _parent:CodeItem
	Field _children:List<CodeItem>
	Field _namespace:String
	Field _filePath:String
	Field _scopeStartPos:Vec2i=New Vec2i,_scopeEndPos:Vec2i=New Vec2i
	Field _superTypes:List<CodeType>
	Field _params:CodeType[]
	Field _paramsStr:String
	
	
	Private
	
	Method UpdateKind()
		Select _kindStr
		Case "function"
			_kind=CodeItemKind.Function_
		Case "method"
			_kind=CodeItemKind.Method_
		Case "interface"
			_kind=CodeItemKind.Interface_
		Case "enum"
			_kind=CodeItemKind.Enum_
		Case "struct"
			_kind=CodeItemKind.Struct_
		Case "field"
			_kind=CodeItemKind.Field_
		Case "global"
			_kind=CodeItemKind.Global_
		Case "const"
			_kind=CodeItemKind.Const_
		Case "param"
			_kind=CodeItemKind.Param_
		Case "class"
			_kind=CodeItemKind.Class_
		Case "property"
			_kind=CodeItemKind.Property_
		Case "lambda"
			_kind=CodeItemKind.Lambda_
		Case "local"
			_kind=CodeItemKind.Local_
		Case "operator"
			_kind=CodeItemKind.Operator_
		Case "for","select","while"
			_kind=CodeItemKind.Inner_
		Case "alias"
			_kind=CodeItemKind.Alias_
		End
	End
		
End


Struct CodeType
	
	Field kind:String
	Field ident:String
	Field expr:String
	Field args:CodeType[]
	
'	Operator To:String()
'		Return ident
'	End
'	
'	Method ToString:String()
'		Return ident
'	End
	
'	Function GetEmptyType:CodeType()
'
'		Local t:=New CodeType
'		t.kind="ident"
'		t.ident="void"
'		Return t
'	End
	
End
