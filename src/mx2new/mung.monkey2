
Namespace mx2

Private

Function OpSym:String( id:String )
	Select id
	Case "*" Return "_mul"
	Case "/" Return "_div"
	Case "+" Return "_add"
	Case "-" Return "_sub"
	Case "&" Return "_and"
	Case "|" Return "_or"
	Case "~~" Return "_xor"
	Case "[]" Return "_idx"
	Case "*=" Return "_muleq"
	Case "/=" Return "_diveq"
	Case "+=" Return "_addeq"
	Case "-=" Return "_subeq"
	Case "&=" Return "_andeq"
	Case "|=" Return "_oreq"
	Case "~~=" Return "_xoreq"
	Case "[]=" Return "_idxeq"
	Case "<" Return "_lt"
	Case "<=" Return "_le"
	Case ">" Return "_gt"
	Case ">=" Return "_ge"
	Case "=" Return "_eq"
	Case "<>" Return "_ne"
	Case "<=>" Return "_cmp"
	End
	Return "????? OpSym ?????"
End

Public

Function MungIdent:String( ident:String )

	If Not IsIdent( ident[0] ) Return OpSym( ident )

	Return ident.Replace( "_","_0" )
End

Function MungArg:String( type:Type )

	If type=Type.VoidType Return "v"
	
	If Cast<PrimType>( type )
		Select type
		Case Type.BoolType	Return "z"
		Case Type.ByteType	Return "b"
		Case Type.UByteType	Return "c"
		Case Type.ShortType	Return "h"
		Case Type.UShortType	Return "t"
		Case Type.IntType	Return "i"
		Case Type.UIntType	Return "j"
		Case Type.LongType	Return "l"
		Case Type.ULongType	Return "m"
		Case Type.FloatType	Return "f"
		Case Type.DoubleType	Return "d"
		Case Type.StringType	Return "s"
		End
		Return "????? MungArg ?????"
	End
	
	Local atype:=Cast<ArrayType>( type )
	If atype
		Local sym:="A"
		If atype.rank>1 sym+=String( atype.rank )
		Return sym+MungArg( atype.elemType )
	Endif
	
	Local ftype:=Cast<FuncType>( type )
	If ftype
		Local sym:="F"+MungArg( ftype.retType )
		For Local ty:=Eachin ftype.argTypes
			sym+=MungArg( ty )
		Next
		Return sym+"E"
	Endif
	
	Local ctype:=Cast<ClassType>( type )
	If ctype
		Return "T"+ClassName( ctype )+"_2"
	Endif

	Local ptype:=Cast<PointerType>( type )
	If ptype
		Return "P"+MungArg( ptype.elemType )
	Endif
	
	Return "????? MungArg "+String.FromCString( type.typeName() )+" ?????"
End

Function MungArgs:String( types:Type[] )

	Local sym:="_1"
	For Local ty:=Eachin types
		If Cast<GenArgType>( ty ) Continue
		sym+=MungArg( ty )
	Next
	Return sym

End

Function ScopeName:String( scope:Scope )

	If Not scope Return "????? ScopeName ?????"
	
	Local fscope:=Cast<FileScope>( scope )
	If fscope
		Return MungIdent( fscope.fdecl.nmspace ).Replace( ".","_" )
	Endif

	Local cscope:=Cast<ClassScope>( scope )
	If cscope 
		Local ctype:=cscope.ctype
		Local sym:=ScopeName( scope.outer )+"_"+MungIdent( ctype.cdecl.ident )
		If ctype.types sym+=MungArgs( ctype.types )
		Return sym
	End
	
	Return ScopeName( scope.outer )
End

Function ClassName:String( ctype:ClassType )

	Local cdecl:=ctype.cdecl

	If cdecl.symbol Return cdecl.symbol
	
	If cdecl.IsExtern Return cdecl.ident

	Return "t_"+ScopeName( ctype.scope )
End

Function FuncName:String( func:FuncValue )

	Local fdecl:=func.fdecl

	If fdecl.symbol Return fdecl.symbol
	
	If fdecl.IsExtern Return fdecl.ident
	
	If fdecl.kind="function" Or func.types

		Local sym:="g_"+ScopeName( func.scope )+"_"+MungIdent( fdecl.ident )

'		hopefully not necessary!		
		If func.types sym+=MungArgs( func.types )
		
		Return sym

	Else If fdecl.kind="method"
	
		If fdecl.ident="new" Return ClassName( Cast<ClassScope>( func.scope ).ctype )

		Local sym:="m_"+MungIdent( fdecl.ident )
		
'		hopefully not necessary!		
		If func.types sym+=MungArgs( func.types )

		Return sym
		
	Else If fdecl.kind="lambda"
	
		Return "invoke"
	
	End
	
	Return "????? FuncName ?????"
End

Function VarName:String( vvar:VarValue )

	If vvar.vdecl.symbol Return vvar.vdecl.symbol

	Local sym:=MungIdent( vvar.vdecl.ident )

	Select vvar.vdecl.kind
	
	Case "local","param","capture"
	
		Return "l_"+sym
	
	Case "field"
	
		Return "m_"+sym
		
	Case "global","const"
	
		Return "g_"+ScopeName( vvar.scope )+"_"+sym
	
	End
	
	Return "????? VarName ?????"
End
