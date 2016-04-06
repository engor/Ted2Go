
Namespace mx2

Class Expr Extends PNode

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method OnSemant:Value( scope:Scope ) Virtual
		Throw New SemantEx( "OnSemant TODO!" )
		Return Null
	End
	
	Method OnSemantType:Type( scope:Scope ) Virtual
		Throw New SemantEx( "Invalid type expression" )
		Return Null
	End
	
	Method OnSemantWhere:Bool( scope:Scope ) Virtual
		Throw New SemantEx( "Invalid 'Where' expression" )
		Return False
	End
	
	Method Semant:Value( scope:Scope )
	
		Try
			semanting.Push( Self )
			
			Local value:=OnSemant( scope )
			
			value.CheckAccess( scope )
			
			semanting.Pop()
			Return value
			
		Catch ex:SemantEx
		
			semanting.Pop()
			Throw ex
		End
		
		Return Null
	End
	
	Method SemantRValue:Value( scope:Scope,type:Type=Null )

		Try
			semanting.Push( Self )
			
			Local value:=OnSemant( scope )
			
			Local rvalue:Value
			If type rvalue=value.UpCast( type ) Else rvalue=value.ToRValue()
			
			rvalue.CheckAccess( scope )
			
			semanting.Pop()
			Return rvalue
			
		Catch ex:SemantEx
		
			semanting.Pop()
			Throw ex
		End
		
		Return Null
	End
	
	Method TrySemantRValue:Value( scope:Scope,type:Type=Null )
	
		Try
		
			Return SemantRValue( scope,type )

		Catch ex:SemantEx
		End
		
		Return Null
	End
	
	Method SemantType:Type( scope:Scope )

		Try
			semanting.Push( Self )

			Local type:=OnSemantType( scope )
			
			semanting.Pop()
			Return type
		
		Catch ex:SemantEx
		
			semanting.Pop()
			Throw ex
		End
		
		Return Null
	End

	Method SemantWhere:Bool( scope:Scope )

		Try
			semanting.Push( Self )
			
			Local twhere:=OnSemantWhere( scope )
			
			semanting.Pop()
			Return twhere
		
		Catch ex:SemantEx
		
			semanting.Pop()
			Throw ex
		End
		
		Return False
	End

End

Class ValueExpr Extends Expr

	Field value:Value
	
	Method New( value:Value,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	
		Self.value=value
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Return value
	End
End

Class IdentExpr Extends Expr

	Field ident:String
	
	Method New( ident:String,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.ident=ident
	End
	
	Method ToString:String() Override
		Return ident
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local value:=scope.FindValue( ident )
		If Not value Throw New SemantEx( "Identifier '"+ident+"' not found" )
		
		Return value
	End
	
	Method OnSemantType:Type( scope:Scope ) Override
	
		Local type:=scope.FindType( ident )
		If Not type Throw New SemantEx( "Type '"+ident+"' not found" )
		
		Return type
	End

End

Class MemberExpr Extends Expr

	Field expr:Expr
	Field ident:String
	
	Method New( expr:Expr,ident:String,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.ident=ident
	End
	
	Method ToString:String() Override
		Return expr.ToString()+"."+ident
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
'		Local value:=expr.Semant( scope )
		Local value:=expr.SemantRValue( scope )
		
		Local tvalue:=value.FindValue( ident )
		If Not tvalue Throw New SemantEx( "Value of type '"+value.type.Name+"' has no member named '"+ident+"'" )
'		If Not tvalue Throw New IdentEx( ident )
		
		Return tvalue
	End
	
	Method OnSemantType:Type( scope:Scope ) Override
	
		Local type:=expr.SemantType( scope )
		
		Local type2:=type.FindType( ident )
		If Not type2 Throw New SemantEx( "Type '"+type.Name+"' has no member type named '"+ident+"'" )
		
		Return type2
	End

End

Class InvokeExpr Extends Expr

	Field expr:Expr
	Field args:Expr[]

	Method New( expr:Expr,args:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.args=args
	End
	
	Method ToString:String() Override
		Return expr.ToString()+"("+Join( args )+")"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local args:=SemantArgs( Self.args,scope )
		
		Local value:=expr.Semant( scope )
		
		Local ivalue:=value.Invoke( args )
		
		Return ivalue
	End
	
End

Class GenericExpr Extends Expr

	Field expr:Expr
	Field types:TypeExpr[]
	
	Method New( expr:Expr,types:TypeExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.types=types
	End
	
	Method ToString:String() Override
		Return expr.ToString()+"<"+Join( types )+">"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local types:=SemantTypes( Self.types,scope )
		
		Local value:=expr.Semant( scope )
		
		'FIXME: need proper 'WhereExpr's!
		'
		Local tvalue:=Cast<TypeValue>( value )
		If tvalue Return New TypeValue( tvalue.ttype.GenInstance( types ) )
		
		Return value.GenInstance( types )
	End
	
	Method OnSemantType:Type( scope:Scope ) Override
	
		Local types:=SemantTypes( Self.types,scope )
		
		Local type:=Self.expr.SemantType( scope )
		
		Return type.GenInstance( types )
	End

End

Class NewObjectExpr Extends Expr

	Field type:TypeExpr
	Field args:Expr[]
	
	Method New( type:TypeExpr,args:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.type=type
		Self.args=args
	End
	
	Method ToString:String() Override
		Local str:="New "+type.ToString()
		If args str+="("+Join( args )+")"
		Return str
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope )
		
		Local ctype:=TCast<ClassType>( type )
		If Not ctype Throw New SemantEx( "Type '"+type.Name+"' is not a class" )
		
		'hmmm...
		'ctype.SemantMembers()
		
		If ctype.IsGeneric Throw New SemantEx( "Class '"+ctype.Name+"' is generic" )
		
		If ctype.IsAbstract
			Local t:=""
			For Local func:=Eachin ctype.abstractMethods
				If t t+=","
				t+=func.ToString()
			Next
			If t Throw New SemantEx( "Class '"+ctype.Name+"' is abstract due to unimplemented method(s) "+t )
			Throw New SemantEx( "Class '"+ctype.Name+"' is abstract" )
		Endif
		
		Local args:=SemantArgs( Self.args,scope )
		
		Local ctor:=ctype.FindNode( "new" )
		
		Local ctorFunc:FuncValue
		
		If ctor

			Local invoke:=Cast<InvokeValue>( ctor.ToValue( Null ).Invoke( args ) )
			
			If Not invoke Throw New SemantEx( "Can't invoke class '"+ctype.Name+"' constuctor with arguments '"+Join( args )+"'" )
			
			ctorFunc=Cast<FuncValue>( invoke.value )
			If Not ctorFunc SemantError( "NewObjectExpr.OnSemant()" )
			
			args=invoke.args

		Else If args
		
			Throw New SemantEx( "Class '"+type.Name+"' has no constructors" )
			
		Endif
		
		Return New NewObjectValue( ctype,ctorFunc,args )
	End
End

Class NewArrayExpr Extends Expr

	Field type:ArrayTypeExpr
	Field sizes:Expr[]
	Field inits:Expr[]
	
	Method New( type:ArrayTypeExpr,sizes:Expr[],inits:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.type=type
		Self.sizes=sizes
		Self.inits=inits
	End
	
	Method ToString:String() Override
		If sizes Return "New "+type.type.ToString()+"["+Join( sizes )+"]"
		Return "New "+type.ToString()+"("+Join( inits )+")"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local atype:=TCast<ArrayType>( type.Semant( scope ) )
		If Not atype SemantError( "NewArrayExpr.OnSemant()" )
		
		If atype.elemType.IsGeneric Throw New SemantEx( "Array element type '"+atype.elemType.Name+"' is generic" )
		
		Local sizes:Value[],inits:Value[]
		If Self.inits
		
			'TODO...
			If atype.rank<>1 Throw New SemantEx( "Array must be 1 dimensional" )
			
			inits=SemantArgs( Self.inits,scope )
			inits=UpCast( inits,atype.elemType )
		Else
			sizes=SemantArgs( Self.sizes,scope )
			sizes=UpCast( sizes,Type.IntType )
		Endif
		
		Return New NewArrayValue( atype,sizes,inits )
	End
		
End

Class IndexExpr Extends Expr

	Field expr:Expr
	Field args:Expr[]
	
	Method New( expr:Expr,args:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.args=args
	End
	
	Method ToString:String() Override
		Return expr.ToString()+"["+Join( args )+"]"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local value:=expr.Semant( scope )
		
		Local args:=SemantRValues( Self.args,scope )
		
		Return value.Index( args )
	End

End

Class ExtendsExpr Extends Expr

	Field op:String
	Field expr:Expr
	Field type:TypeExpr
	
	Method New( op:String,expr:Expr,type:TypeExpr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.op=op
		Self.expr=expr
		Self.type=type
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local ctype:=TCast<ClassType>( Self.type.Semant( scope ) )
		If Not ctype Or (ctype.cdecl.kind<>"class" And ctype.cdecl.kind<>"interface" And ctype.cdecl.kind<>"protocol" ) 
			Throw New SemantEx( "Type '"+type.ToString()+"' is not a class or interface type" )
		Endif
		
		Local value:=Self.expr.SemantRValue( scope )

		Local tvalue:=Cast<TypeValue>( value )
		If tvalue
			If tvalue.ttype.DistanceToType( ctype )>=0 Return LiteralValue.BoolValue( True )
			Local ptype:=TCast<PrimType>( tvalue.ttype )
			If ptype And ptype.ctype.DistanceToType( ctype )>=0 Return LiteralValue.BoolValue( True )
			Return LiteralValue.BoolValue( False )
		Endif
		
		If value.type.DistanceToType( ctype )>=0 Return LiteralValue.BoolValue( True )
		
		If Not value.type.CanCastToType( ctype ) Return LiteralValue.BoolValue( False )
		
		Local cvalue:=New ExplicitCastValue( ctype,value )
		
		Return cvalue.UpCast( Type.BoolType )
	End
	
	Method OnSemantWhere:Bool( scope:Scope ) Override
	
		Local ctype:=TCast<ClassType>( Self.type.Semant( scope ) )
		
		If Not ctype Or (ctype.cdecl.kind<>"class" And ctype.cdecl.kind<>"interface" And ctype.cdecl.kind<>"protocol" ) 
			Throw New SemantEx( "Type '"+type.ToString()+"' is not a class or interface type" )
		endif
		
		Local type:=Self.expr.SemantType( scope )

		Return type.ExtendsType( ctype )
	End

End

Class CastExpr Extends Expr

	Field type:TypeExpr
	Field expr:Expr
	
	Method New( type:TypeExpr,expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.type=type
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return "cast<"+type.ToString()+">("+expr.ToString()+")"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope )
		
		Local value:=Self.expr.Semant( scope )
		
		Local castOp:=value.FindValue( "cast" )
		If castOp value=castOp.Invoke( Null )

		'simple upcast?		
		If value.type.DistanceToType( type )>=0 Return value.UpCast( type )

		'nope...		
		value=value.ToRValue()
		
		If Not value.type.CanCastToType( type ) 
			Throw New SemantEx( "Value of type '"+value.type.Name+"' cannot be cast to type '"+type.Name+"'" )
		Endif
		
		Return New ExplicitCastValue( type,value )
	End
		
End

Class SelfExpr Extends Expr

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method ToString:String() Override
		Return "self"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
		
		Local block:=Cast<Block>( scope )
		If block And block.func.selfValue Return block.func.selfValue
		
		Throw New SemantEx( "'Self' can only be used in properties and methods" )
		Return Null
	End
	
End

Class SuperExpr Extends Expr

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method ToString:String() Override
		Return "super"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local block:=Cast<Block>( scope )
		If block And block.func.selfValue
		
			Local ctype:=TCast<ClassType>( block.func.selfValue.type )
			If ctype

				Local superType:=ctype.superType
				If superType Return New SuperValue( superType )

				Throw New SemantEx( "Class '"+ctype.Name+"' has no super class" )

			Endif
		Endif
		
		Throw New SemantEx( "'Super' can only be used in properties and methods" )
		Return Null
	End
	
End

Class NullExpr Extends Expr

	Method New( srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
	End
	
	Method ToString:String() Override
		Return "null"
	End
	
	Method OnSemant:Value( scope:Scope ) Override
		Return New NullValue
	End
	
End

Class UnaryopExpr Extends Expr

	Field op:String
	Field expr:Expr
	
	Method New( op:String,expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.op=op
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return op+expr.ToString()
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local value:=expr.SemantRValue( scope )
		
		Local type:=value.type
		
		Local node:=value.FindValue( op )
		If node Return node.Invoke( Null )
		
		Local ptype:=TCast<PrimType>( type )
		
		Select op
		Case "+","-"
			If Not ptype Or Not ptype.IsNumeric 
				Throw New SemantEx( "Type must be numeric" )
			Endif
			If ptype.IsUnsignedIntegral
				Throw New SemantEx( "Type cannot be unsigned" )
			Endif
		Case "~"
			Local etype:=TCast<EnumType>( type )
			If etype
				type=etype
			Else If Not ptype Or Not ptype.IsIntegral
				Throw New SemantEx( "Type must be integral" )
			Endif 
		Case "not"
			type=Type.BoolType
		Default
			Throw New SemantEx( "Illegal type for unary operator '"+op+"'" )
		End
		
		Return EvalUnaryop( type,op,value.UpCast( type ) )
	End
	
End

Class BinaryopExpr Extends Expr

	Field op:String
	Field lhs:Expr
	Field rhs:Expr
	
	Method New( op:String,lhs:Expr,rhs:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.op=op
		Self.lhs=lhs
		Self.rhs=rhs
	End
	
	Method ToString:String() Override
		Return "("+lhs.ToString()+op+rhs.ToString()+")"
	End
	
	Function BalanceIntegralTypes:Type( lhs:PrimType,rhs:PrimType )
	
		If Not lhs Or Not rhs Or Not lhs.IsIntegral Or Not rhs.IsIntegral
			Throw New SemantEx( "Types must be integral" )
		Endif

		'Think about this more...!
		'
		If lhs=Type.ULongType Or rhs=Type.ULongType Return Type.ULongType
		
		If lhs=Type.LongType Or rhs=Type.LongType Return Type.LongType
		
		If lhs.IsUnsignedIntegral Or rhs.IsUnsignedIntegral Return Type.UIntType
		
		Return Type.IntType
	End
	
	function BalanceNumericTypes:Type( lhs:PrimType,rhs:PrimType )

		If Not lhs Or Not rhs Or Not lhs.IsNumeric Or Not rhs.IsNumeric
			Throw New SemantEx( "Types must be numeric" )
		Endif
	
		If lhs=Type.DoubleType Or rhs=Type.DoubleType Return Type.DoubleType

		If lhs=Type.FloatType Or rhs=Type.FloatType Return Type.FloatType
		
		Return BalanceIntegralTypes( lhs,rhs )
	End
	
	function BalancePrimTypes:Type( lhs:PrimType,rhs:PrimType )
	
		If Not lhs Or Not rhs
			Throw New SemantEx( "Types must be primitive" )
		Endif
	
		If lhs=Type.StringType Or rhs=Type.StringType Return Type.StringType
		
		Return BalanceNumericTypes( lhs,rhs )
	End
	
	Function BalanceTypes:Type( lhs:Type,rhs:Type )
	
		Local plhs:=TCast<PrimType>( lhs )
		Local prhs:=TCast<PrimType>( rhs )
		
		If plhs And prhs Return BalancePrimTypes( plhs,prhs )
		
		If lhs.DistanceToType( rhs )>=0 Return rhs		'And rhs.DistanceToType( lhs )<=0 Return rhs
		If rhs.DistanceToType( lhs )>=0 Return lhs		'And lhs.DistanceToType( rhs )<=0 Return lhs
		
		Throw New SemantEx( "Types '"+lhs.Name+"' and '"+rhs.Name+"' are incompatible" )
		
		Return Null
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local lhs:=Self.lhs.Semant( scope )
		Local rhs:=Self.rhs.Semant( scope )
		
		If lhs.type=Type.NullType
			rhs=rhs.ToRValue()
			lhs=lhs.UpCast( rhs.type )
		Else If rhs.type=Type.NullType
			lhs=lhs.ToRValue()
			rhs=rhs.UpCast( lhs.type )
		Else
			lhs=lhs.ToRValue()
			rhs=rhs.ToRValue()
		Endif
		
		'check for overloaded operator
		'
		Local node:=lhs.FindValue( op )
		If node 
			Local args:=New Value[1]
			args[0]=rhs
			Return node.Invoke( args )
		Endif

		'handle pointer arithmetic
		'
		Local lptype:=TCast<PointerType>( lhs.type )
		Local rptype:=TCast<PointerType>( rhs.type )
		If lptype Or rptype
			If lptype And (op="+" Or op="-")	
				'pointer=pointer +/- int
				Return New BinaryopValue( lptype,op,lhs,rhs.UpCast( Type.IntType ) )
			Else If rptype And op="+"
				'pointer=int + pointer
				Return New BinaryopValue( rptype,op,rhs,lhs.UpCast( Type.IntType ) )
			Endif
			Throw New SemantEx( "Pointer arithmetic error" )
		Endif
		
		Local plhs:=TCast<PrimType>( lhs.type )
		Local prhs:=TCast<PrimType>( rhs.type )
		
		Local type:Type,lhsType:Type,rhsType:Type
		
		Select op
		Case "+"
		
			type=BalancePrimTypes( plhs,prhs )
			
		Case "*","/","mod","-"
		
			type=BalanceNumericTypes( plhs,prhs )
			
		Case "&","|","~"
		
			Local elhs:=TCast<EnumType>( lhs.type )
			Local erhs:=TCast<EnumType>( rhs.type )
			If elhs Or erhs
				If elhs.Equals( erhs ) type=elhs
			Else
				type=BalanceIntegralTypes( plhs,prhs )
			Endif
			
		Case "shl","shr"

			type=BalanceIntegralTypes( plhs,plhs )
			rhsType=Type.IntType
			
		Case "=","<>","<",">","<=",">="

			Local node:=lhs.FindValue( "<=>" )
			If node
			
				Local args:=New Value[1]
				args[0]=rhs
				lhs=node.Invoke( args )

				lhsType=lhs.type
				rhsType=lhsType
				
				Local ptype:=TCast<PrimType>( lhsType )
				Assert( ptype And ptype.IsNumeric )
				
				rhs=New LiteralValue( rhsType,"" )
				type=Type.BoolType
				
			Else If plhs=Type.BoolType Or prhs=Type.BoolType
			
				If op<>"=" And op<>"<>" Throw New SemantEx( "Bool values can only be compared for equality" )
				
				type=Type.BoolType
			
			Else
			
				type=BalanceTypes( lhs.type,rhs.type )
				If type
					lhsType=type
					rhsType=type
					type=Type.BoolType
				Endif
				
			
			Endif
			
		Case "<=>"
		
			type=BalanceTypes( lhs.type,rhs.type )
			If type
				lhsType=type
				rhsType=type
				type=Type.IntType
			Endif
			
		Case "and","or"

			type=Type.BoolType
		End
		
		If Not type Throw New SemantEx( "Parameter types for binary operator '"+op+"' cannot be determined" )
		
		If Not lhsType lhsType=type
		If Not rhsType rhsType=type
		
		Return EvalBinaryop( type,op,lhs.UpCast( lhsType ),rhs.UpCast( rhsType ) )
	End
	
	Method OnSemantWhere:Bool( scope:Scope ) Override
	
		If op<>"=" And op<>"<>" Throw New SemantEx( "Types can only be compared for equality" )
		
		Local lhs:=Self.lhs.SemantType( scope )
		Local rhs:=Self.rhs.SemantType( scope )
		
		If op="=" Return lhs.Equals( rhs )
		
		Return Not lhs.Equals( rhs )
	End
	
End

Class IfThenElseExpr Extends Expr

	Field expr:Expr
	Field thenExpr:Expr
	Field elseExpr:Expr
	
	Method New( expr:Expr,thenExpr:Expr,elseExpr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
		Self.thenExpr=thenExpr
		Self.elseExpr=elseExpr
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local value:=expr.SemantRValue( scope,Type.BoolType )
		Local thenValue:=thenExpr.SemantRValue( scope )
		Local elseValue:=elseExpr.SemantRValue( scope )
		
		Local type:=BinaryopExpr.BalanceTypes( thenValue.type,elseValue.type )
		thenValue=thenValue.UpCast( type )
		elseValue=elseValue.UpCast( type )
		
		Return New IfThenElseValue( type,value,thenValue,elseValue )
	End
End

Class VarptrExpr Extends Expr

	Field expr:Expr
	
	Method New( expr:Expr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.expr=expr
	End
	
	Method ToString:String() Override
		Return "Varptr "+expr.ToString()
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local value:=expr.Semant( scope )
		
		If Not value.IsLValue Throw New SemantEx( "Value '"+value.ToString()+"' is not a valid variable reference" )
		
		Return New PointerValue( value )
	End
End

Class LiteralExpr Extends Expr

	Field toke:String
	Field tokeType:Int
	Field typeExpr:TypeExpr
	
	Method New( toke:String,tokeType:Int,typeExpr:TypeExpr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.toke=toke
		Self.tokeType=tokeType
		Self.typeExpr=typeExpr
	End
	
	Method ToString:String() Override
		Return toke
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local type:Type
		
		If typeExpr
		 
			type=typeExpr.Semant( scope )

			Local ptype:=TCast<PrimType>( type )
			If Not ptype Throw New SemantEx( "Literal type must be a primitive type" )
			
			Select tokeType
			Case TOKE_INTLIT
				If Not ptype.IsIntegral Throw New SemantEx( "Literal type must be an integral type" )
			Case TOKE_FLOATLIT
				If Not ptype.IsReal Throw New SemantEx( "Literal type must be 'Float' or 'Double'" )
			Case TOKE_STRINGLIT
				If ptype<>Type.StringType Throw New SemantEx( "Literal type must be 'String'" )
			Case TOKE_KEYWORD
				If ptype<>Type.BoolType Throw New SemantEx( "Literal type must be 'Bool'" )
			End
			
		Else
		
			Select tokeType
			Case TOKE_INTLIT 
				type=Type.IntType
			Case TOKE_FLOATLIT 
				type=Type.FloatType
			Case TOKE_STRINGLIT 
				type=Type.StringType
			Case TOKE_KEYWORD
				type=Type.BoolType
			End
			
		Endif
		
		If Not type SemantError( "LiteralExpr.OnSemant()" )
		
		Local t:=toke
		
		Local ptype:=TCast<PrimType>( type )
		
		If ptype And ptype.IsIntegral And t And t[0]=CHAR_DOLLAR
		
			Local n:ULong
			For Local i:=1 Until toke.Length
				Local c:=toke[i]
				If c>=97
					c-=87
				Else If c>=65
					c-=55
				Else
					c-=48
				Endif
				n=n Shl 4 | c
			Next
			t=String( n )
			
		Else If ptype=Type.StringType
		
			t=DequoteMx2String( t )
		Endif
		
		Return New LiteralValue( type,t )
	End
End

Class ArrayLiteralExpr Extends Expr

	Field exprs:Expr[]

	Method New( exprs:Expr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.exprs=exprs
	End

	Method ToString:String() Override
		Return "["+Join( exprs )+"]"
	End

End

Class LambdaExpr Extends Expr

	Field decl:FuncDecl

	Method New( decl:FuncDecl,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.decl=decl
	End
	
	Method ToString:String() Override
		Return decl.ToString()
	End
	
	Method OnSemant:Value( scope:Scope ) Override
	
		Local func:=New FuncValue( decl,scope,Null,Null )
		
		func.Semant()
		
		Return func
	End
	
End
