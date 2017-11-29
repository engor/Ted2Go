
Namespace ted2go


Enum CodeItemKind
	Undefine_,
	Class_,
	Interface_,
	Enum_,
	EnumMember_,
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
	Inner_,
	Alias_,
	Inherited_
End


Enum AccessMode
	Private_,
	Protected_,
	Public_
End


Class CodeItem
	
	Field nspace:NSpace
	Field isAlias:=False
	
	Method New( ident:String )
		_ident=ident
	End
	
	Method OnRemoved()
		
		If nspace Then nspace.items.Remove( Self )
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
		_type.ident=FixTypeIdent( _type.ident )
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
			_text=GetText( True )
		Endif
		Return _text
	End
	
	Property TextForInsert:String()
		
		Return GetText( False )
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
	
	Property Children:Stack<CodeItem>()
		Return _children
	Setter( value:Stack<CodeItem> )
		_children=value
	End
	
	Property Namespac:String()
		
		If Not _namespace
			Local p:=_parent
			While p<>Null
				_namespace=p._namespace
				If _namespace Exit
				p=p._parent
			Wend
		Endif
		Return _namespace
	Setter( value:String )
		_namespace=value
	End
	
	Property IsModuleMember:Bool()
		
		If _isModuleMember=-1
			Local p:=_parent
			While p<>Null
				_isModuleMember=p._isModuleMember
				If _isModuleMember<>-1 Exit
				p=p._parent
			Wend
		Endif
		Return _isModuleMember=1 ? True Else False
	Setter( value:Bool )
		_isModuleMember=value ? 1 Else 0
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
		
		If Parent Then Parent.Children.Remove( Self )
		_parent=parent
		If Not _parent.Children Then _parent.Children = New Stack<CodeItem>
		_parent.Children.Add( Self )
	End
	
	Method AddChild( item:CodeItem )
		item.Parent=Self
	End
	
	Property SuperTypes:List<CodeType>()
		Return _superTypes
	Setter( value:List<CodeType> )
		_superTypes=value
	End
	
	Property SuperTypesStr:List<String>()
		Return _superTypesStr
	End
	
	Property IsLikeClass:Bool()
		Select _kind
		Case CodeItemKind.Class_,CodeItemKind.Interface_,CodeItemKind.Struct_,CodeItemKind.Enum_
			Return True
		End
		Return False
	End
	
	Property IsLikeFunc:Bool()
		Select _kind
		Case CodeItemKind.Method_,CodeItemKind.Function_
			Return True
		End
		Return False
	End
	
	Property IsExtension:Bool()
		Return _isExtension
	Setter( value:Bool )
		_isExtension=value
	End
	
	Method AddSuperType( type:CodeType )
		If Not _superTypes Then _superTypes=New List<CodeType>
		_superTypes.AddLast( type )
	End
	
	Method AddSuperTypeStr( type:String )
		If Not _superTypesStr Then _superTypesStr=New List<String>
		_superTypesStr.AddLast( type )
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
	
	Property Params:CodeParam[]()
		Return _params
	Setter( value:CodeParam[] )
		_params=value
	End
	
	Property ParamsStr:String()
		
		If Not _params Return Null
		If _paramsStr Return _paramsStr
		
		_paramsStr=""
		For Local p:=Eachin _params
			If _paramsStr<>"" Then _paramsStr+=","
			_paramsStr+=p.ToString()
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
	Field _children:Stack<CodeItem>
	Field _namespace:String
	Field _filePath:String
	Field _scopeStartPos:Vec2i=New Vec2i,_scopeEndPos:Vec2i=New Vec2i
	Field _superTypes:List<CodeType>,_superTypesStr:List<String>
	Field _params:CodeParam[]
	Field _paramsStr:String
	Field _isModuleMember:=-1
	Field _isExtension:Bool
	
	
	Private
	
	Method GetText:String( withSpaces:Bool )
		
		Local s:=Ident
		Select _kind
			Case CodeItemKind.Function_,CodeItemKind.Method_,CodeItemKind.Lambda_,CodeItemKind.Operator_
				If Type<>Null And Type.ident<>"Void"
					s+=withSpaces ? " : " Else ":"
					s+=Type.ToString()
				Endif
				If HasParams
					s+=withSpaces ? " ( " Else "( "
					s+=ParamsStr+" )"
				Else
					s+="()"
				Endif
		
			Case CodeItemKind.Class_,CodeItemKind.Interface_,CodeItemKind.Struct_,CodeItemKind.Enum_,CodeItemKind.Alias_
				
				If _isExtension
					s+=" (ext)"
				Endif
		
			Case CodeItemKind.Inner_,CodeItemKind.EnumMember_
				' nothing
		
			Case CodeItemKind.Property_
				s+=withSpaces ? " : " Else ":"
				s+=Type.ToString()
		
			Default
				If Type<>Null And Type.IsLikeFunc
					If Type.ident<>"Void"
						s+=withSpaces ? " : " Else ":"
						s+=Type.ToString()
					Endif
					If HasParams
						s+=withSpaces ? " ( " Else "( "
						s+=ParamsStr+" )"
					Else
						s+="()"
					Endif
				Else
					Local t:=Type.ToString()
					If t
						s+=withSpaces ? " : " Else ":"
						s+=t
					Endif
				Endif
		
		End
		Return s
	End
	
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
		Case "enumMember"
			_kind=CodeItemKind.EnumMember_
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
		Case "inherited"
			_kind=CodeItemKind.Inherited_
		End
	End
	
End


Struct CodeType
	
	Field kind:String
	Field expr:String
	Field args:CodeType[]
	Field isPointer:Bool
	
	Property ident:String()
		Return _ident
	Setter( value:String )
		_ident=FixTypeIdent( value )
	End
	
	Property IsLikeFunc:Bool()
		Return kind="functype"
	End
	
	Operator To:String()
		Return ToString()
	End
	
	Method ToString:String()
		
		If _str Return _str
		
		If args
			_str=expr+"<"
			For Local i:=0 Until args.Length
				If i > 0 Then _str+=","
				_str+=args[i].ToString()
			Next
			_str+=">"
		Else
			_str=ident
		Endif
		
		If isPointer Then _str+=" Ptr"
		
		Return _str
	End
	
	Private
	
	Field _str:String
	Field _ident:String
		
End


Struct CodeParam

	Property ident:String()
		Return _ident
	Setter( value:String )
		_ident = FixTypeIdent( value )
	End
	Field type:CodeType
	Field params:CodeParam[] 'for func as param
	
	Method ToString:String()
		
		If _str Return _str
		
		_str=ident+":"+type.ToString()
		
		If params
			_str+="("
			For Local i:=0 Until params.Length
				If i > 0 Then _str+=","
				_str+=params[i].ToString()
			Next
			_str+=")"
		Endif
		
		Return _str
	End
	
	Private
	
	Field _str:String
	Field _ident:String
	
End


Struct CodeItemsSorter Final
	
	
	Function SortByType( list:Stack<CodeItem>,inverse:Bool=False,checkIdent:Bool=False )
		
		_checkIdent=checkIdent
		
		If _sorterByType = Null
			_sorterByType=Lambda:Int( lhs:CodeItem,rhs:CodeItem )
				
				Local lp:=GetItemPriority( lhs,inverse )
				Local rp:=GetItemPriority( rhs,inverse )
				
				Local r:=(rp <=> lp)
				
				If r=0 And _checkIdent
					r = inverse ? rhs.Text<=>lhs.Text Else lhs.Text<=>rhs.Text
				Endif
				
				Return r
			End
		Endif
		
		list.Sort( _sorterByType )
	End
	
	Function SortByPosition( list:Stack<CodeItem> )
	
		If _sorterByPosition = Null
			_sorterByPosition=Lambda:Int( lhs:CodeItem,rhs:CodeItem )
	
				Local lp:=lhs.ScopeStartPos
				Local rp:=rhs.ScopeStartPos
	
				Local r:=0
				If lp.x<rp.x
					r=-1
				Else If lp.x>rp.y
					r=1
				Endif
				Return r
			End
		Endif
	
		list.Sort( _sorterByPosition )
	End
	
	Function SortByIdent( list:Stack<ListViewItem>,etalonIdent:String )
		
		_etalonIdent=etalonIdent
		
		If _sorterByIdent = Null
			_sorterByIdent=Lambda:Int( lhs:ListViewItem,rhs:ListViewItem )

				Local lp:=GetIdentPower( lhs.Text,_etalonIdent )
				Local rp:=GetIdentPower( rhs.Text,_etalonIdent )
				
				Local r:=(rp<=>lp)
				If r=0 Return GetIdentLength( lhs )<=>GetIdentLength( rhs ) 'brings up shorter idents
				
				Return r
			End
		Endif
		
		list.Sort( _sorterByIdent )
	End
	
	Function GetIdentPower:Int( ident:String,etalon:String )
		
		Local len:=etalon.Length
		Local power:=0
		Local ch:=etalon[0],index:=0
		Local eqFirstChar:=False
		
		For Local i:=0 Until ident.Length
			Local s:=ident.Slice( i,i+1 )
			Local eq1:=(s[0]=ch)
			Local eq2:=(s.ToLower()[0]=ch)
			If eq1 Or eq2
				Local pw:=(len-i)*30
				If eq1 Then pw*=2 'full equals is 'better' than lower-cased
				power+=pw
				index+=1
				ch = index>=len ? -1 Else etalon[index]
				If ch=-1 Exit
				If i=0 Then eqFirstChar=True
			Endif
		Next
		
		' strong first char
		If Prefs.AcStrongFirstChar
			Local lower1:=IsLowercacedFirstChar( ident )
			Local lower2:=IsLowercacedFirstChar( etalon )
			If lower1 <> lower2 ' if first chars cases aren't equals
				If Not eqFirstChar ' and letters are different
					power-=10000
				Else
					power-=100
				Endif
			Endif
		End
		
		Return power
	End
	
	Function GetIdentLength:Int( item:ListViewItem )
		
		Local ident:=item.Text
		Local p:=ident.Find( ":" )
		If p<>-1
			ident=ident.Slice( 0,p )
			p=ident.Find( "(" )
			If p<>-1 Then ident=ident.Slice( 0,p )
		Else
			p=ident.Find( "(" )
			If p<>-1 Then ident=ident.Slice( 0,p )
		Endif
		
		Return ident.Length
	End
	
	
	Private
	
	Method New()
	End
	
	Global _checkIdent:Bool
	Global _etalonIdent:String
	Global _sorterByType:Int( lhs:CodeItem,rhs:CodeItem )
	Global _sorterByIdent:Int( lhs:ListViewItem,rhs:ListViewItem )
	Global _sorterByPosition:Int( lhs:CodeItem,rhs:CodeItem )
	
	Function GetItemPriority:Int( item:CodeItem,inverse:Bool=False )
		
		Local retval:=0
		
		Select item.Kind
			
			Case CodeItemKind.Class_,CodeItemKind.Struct_,CodeItemKind.Interface_,CodeItemKind.Enum_
				retval=20
				
			Case CodeItemKind.Method_,CodeItemKind.Function_
				retval= (item.Ident.ToLower() = "new") ? 15 Else 10
			
			Case CodeItemKind.Property_
				retval=8
			
			Case CodeItemKind.Field_,CodeItemKind.Global_
				Local t:=item.Type
				If t<>Null And t.IsLikeFunc
					retval=16 'more than constructor
				Else
					retval=7
				Endif
				
			Case CodeItemKind.Const_
				retval=(inverse ? 9 Else 6)
			
			Case CodeItemKind.Param_
				retval=(inverse ? -10 Else 30)
				
			Case CodeItemKind.Operator_
				retval=(inverse ? 25 Else -1) 'always put it on the bottom
		End
		
		If inverse Then retval=20-retval
		
		Return retval
	End
	
End
