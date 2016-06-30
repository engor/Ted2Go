
Namespace mx2

Function EvalUnaryop:LiteralValue( type:Type,op:String,arg:LiteralValue )

	Return Null
End

Function EvalUnaryop:Value( type:Type,op:String,arg:Value )

	Local t:=Cast<LiteralValue>( arg )
	If t
		Local value:=EvalUnaryop( type,op,t )
		If value Return value
	Endif
	
	Return New UnaryopValue( type,op,arg )
End

Function EvalBinaryop:LiteralValue( type:Type,op:String,lhs:LiteralValue,rhs:LiteralValue )

	Select type
	Case Type.IntType
		Local r:Int,x:=Int( lhs.value ),y:=Int( rhs.value )
		Select op
		Case "*" r=x * y
		Case "/" r=x / y
		Case "+" r=x + y
		Case "-" r=x - y
		Case "&" r=x & y
		Case "|" r=x | y
		Case "~" r=x ~ y
		Case "mod" r=x Mod y
		Case "shl" r=x Shl y
		Case "shr" r=x Shr y
		Default Return Null
		End
		Return New LiteralValue( Type.IntType,String( r ) )
	End
	
	Local etype:=TCast<EnumType>( type )
	If etype And Not etype.edecl.IsExtern
		Local r:Int,x:=Int( lhs.value ),y:=Int( rhs.value )
		Select op
		Case "&" r=x & y
		Case "|" r=x | y
		Case "~" r=x ~ y
		Default Return Null
		End
		Return New LiteralValue( type,String( r ) )
	Endif
	
	Return Null
	
End

Function EvalBinaryop:Value( type:Type,op:String,lhs:Value,rhs:Value )

	Local x:=Cast<LiteralValue>( lhs )
	If x
		Local y:=Cast<LiteralValue>( rhs )
		If y
			Local value:=EvalBinaryop( type,op,x,y )
			If value Return value
		Endif
	Endif
	
	Return New BinaryopValue( type,op,lhs,rhs )
End
