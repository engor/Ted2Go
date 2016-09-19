
Namespace mx2

Class Type Extends SNode

	Const TYPE_GENERIC:=1
	Const MAX_DISTANCE:=10000

	Global BadType:=New BadType
	Global NullType:=New NullType
	Global VoidType:=New VoidType
	
	Global BoolType:PrimType
	Global ByteType:PrimType
	Global UByteType:PrimType
	Global ShortType:PrimType
	Global UShortType:PrimType
	Global IntType:PrimType
	Global UIntType:PrimType
	Global LongType:PrimType
	Global ULongType:PrimType
	Global FloatType:PrimType
	Global DoubleType:PrimType
	Global StringType:PrimType
	
	Global ArrayClass:ClassType
	Global ObjectClass:ClassType
	Global ThrowableClass:ClassType
	
	Global CStringClass:ClassType
	Global WStringClass:ClassType
	Global Utf8StringClass:ClassType
	
	Global ExceptionClass:ClassType
	
	Field _alias:Type
	
	Field flags:Int
	
	Method New()
		_alias=Self
	End
	
	Property Dealias:Type()
		Return _alias
	End
	
	Property IsGeneric:Bool()
		Return flags & TYPE_GENERIC
	End
	
	'Not nice - should fix comparison ops
	Operator=:Bool( type:Type )
		If Not Self Return Object(type)=Null
		If Not type Return Object(_alias)=Null
		Return Object(type._alias)=_alias
	End
	
	Operator<>:Bool( type:Type )
		If Not Self Return Object(type)<>Null
		If Not type Return Object(_alias)<>Null
		Return Object(type._alias)<>_alias
	End
	
	Operator<=>:Int( type:Type )
		SemantError( "Type.Operator<=>()" )
		Return 0
	End
	
	Method ToType:Type() Override Final
		Return Self
	End

	Method ToValue:Value( instance:Value ) Override
		Return New TypeValue( Self )
	End
	
	Property Name:String() Abstract
	
	Property TypeId:String() Abstract
	
	Method FindNode:SNode( ident:String ) Virtual
		Return Null
	End
	
	Method FindType:Type( ident:String ) Virtual
		Throw New SemantEx( "Type '"+ToString()+"' has no scope" )
		Return Null
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Virtual
		If Equals( type ) Return type
		Return Null
	End
	
	Method Equals:Bool( type:Type ) Virtual
		Return type=Self
	End
	
	Method ExtendsType:Bool( type:Type ) Virtual
		Return Equals( type )
	End
	
	Method DistanceToType:Int( type:Type ) Virtual
		Return Equals( type ) ? 0 Else -1
	End
	
	Method CanCastToType:Bool( type:Type ) Virtual
		Return Equals( type )
	End

	Method UpCast:Value( rvalue:Value,type:Type ) Virtual
		Local d:=DistanceToType( type )
		If d<0 Throw New UpCastEx( rvalue,type )
		If d>0 Return New UpCastValue( type,rvalue )
		Return rvalue
	End

	Method Invoke:Value( args:Value[],value:Value ) Virtual
		Throw New SemantEx( "Type '"+ToString()+"' cannot be invoked" )
		Return Null
	End
	
	Method Index:Value( args:Value[],value:Value ) Virtual
		Throw New SemantEx( "Type '"+ToString()+"' cannot be indexed" )
		Return Null
	End
	
	Method GenInstance:Type( types:Type[] ) Virtual
		Throw New SemantEx( "Type '"+ToString()+"' is not generic" )
		Return Null
	End
	
End

Class ProxyType Extends Type

	Property Name:String() Override
		Return _alias.Name
	End
	
	Property TypeId:String() Override
		Return _alias.TypeId
	End
	
	Method ToString:String() Override
		Return _alias.ToString()
	End
	
	Method ToValue:Value( instance:Value ) Override
		Return _alias.ToValue( instance )
	End
	
	Method FindNode:SNode( ident:String ) Override
		Return _alias.FindNode( ident )
	End
	
	Method FindType:Type( ident:String ) Override
		Return _alias.FindType( ident )
	End
	
	Method UpCast:Value( rvalue:Value,type:Type ) Override
		Return _alias.UpCast( rvalue,type )
	End
	
	Method Invoke:Value( args:Value[],value:Value ) Override
		Return _alias.Invoke( args,value )
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
		Return _alias.Index( args,value )
	End
	
	Method GenInstance:Type( types:Type[] ) Override
		Return _alias.GenInstance( types )
	End
	
	Method Equals:Bool( type:Type ) Override
		Return _alias.Equals( type )
	End
	
	Method DistanceToType:Int( type:Type ) Override
		Return _alias.DistanceToType( type )
	End
	
	Method ExtendsType:Bool( type:Type ) Override
		Return _alias.ExtendsType( type )
	End
	
	Method InferType:Type( type:Type,args:Type[] ) Override
		Return _alias.InferType( type,args )
	End
	
	Method CanCastToType:Bool( type:Type ) Override
		Return _alias.CanCastToType( type )
	End
	
End

Function TCast<T>:T( type:Type )
	If type Return Cast<T>( type._alias )
	Return Null
End

Function TCast<T>:T( node:SNode )
	Local type:=Cast<Type>( node )
	If type Return Cast<T>( type._alias )
	Return Null
End

Class PrimType Extends Type

	Field ctype:ClassType
	
	Method New( ctype:ClassType )
		If Not ctype Print "No class for primtype!"
		Self.ctype=ctype
	End
	
	Method ToString:String() Override
		Return ctype.cdecl.ident.Slice( 1 )	'slice off '@' prefix
	End
	
	Property Name:String() Override
		Return ctype.Name
	End
	
	Property TypeId:String() Override
		Select Self
		Case IntType Return "i"
		Case FloatType Return "f"
		Case StringType Return "s"
		End
		Return "?"
	End
	
	Method FindNode:SNode( ident:String ) Override
		Return ctype.FindNode( ident )
	End
	
	Method FindType:Type( ident:String ) Override
		Return ctype.FindType( ident )
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		If Self<>StringType Return Super.Index( args,value )

		If args.Length<>1 Throw New SemantEx( "Wrong number of indices" )
		
		Return New StringIndexValue( value,args[0].UpCast( IntType ) )
	End
	
	Method Equals:Bool( type:Type ) Override

		Return type=Self 
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		Select type
		Case StringType

			If IsNumeric Return MAX_DISTANCE

		Case CStringClass,WStringClass,Utf8StringClass
		
			If Self=StringType Or IsNumeric Return MAX_DISTANCE
			
		Default
		
			If TCast<PrimType>( type ) Return MAX_DISTANCE
		
		End
		
		Return -1
	End
	
	Method ExtendsType:Bool( type:Type ) Override
	
		Return type=Self Or ctype.DistanceToType( type )>=0
	End
	
	Method CanCastToType:Bool( type:Type ) Override
	
		If DistanceToType( type )>=0 Return True
		
		'integral->enum
		If IsIntegral And TCast<EnumType>( type ) Return True
		
		'integral->pointer
		If IsIntegral And TCast<PointerType>( type ) Return True
		
		Return False
	End
	
	Property IsNumeric:Bool()
		Select Self
		Case FloatType,DoubleType Return True
		Case ByteType,ShortType,IntType,LongType Return True
		Case UByteType,UShortType,UIntType,ULongType Return True
		End
		Return False
	End
	
	Property IsReal:Bool()
		Select Self
		Case FloatType,DoubleType Return True
		End
		Return False
	End
	
	Property IsIntegral:Bool()
		Select Self
		Case ByteType,ShortType,IntType,LongType Return True
		Case UByteType,UShortType,UIntType,ULongType Return True
		End
		Return False
	End
	
	Property IsSignedIntegral:Bool()
		Select Self
		Case ByteType,ShortType,IntType,LongType Return True
		End
		Return False
	End
	
	Property IsUnsignedIntegral:Bool()
		Select Self
		Case UByteType,UShortType,UIntType,ULongType Return True
		End
		Return False
	End

End

Class ArrayType Extends Type

	Field elemType:Type
	Field rank:Int
	Field ctype:ClassType
	
	Method New( elemType:Type,rank:Int )
		Self.elemType=elemType
		Self.rank=rank
		Self.ctype=ArrayClass
		
		If elemType.IsGeneric flags|=TYPE_GENERIC

		If Not IsGeneric
			Local types:=New Type[1]
			types[0]=elemType
			ctype=TCast<ClassType>( ctype.GenInstance( types ) )
		Endif
		
		If Not ctype SemantError( "ArrayType.New()" )
	End
	
	Method ToString:String() Override

		Return elemType.ToString()+"[,,,,,,,,,,".Slice( 0,rank )+"]"
	End
	
	Property Name:String() Override
		Return elemType.Name+"[,,,,,,,,,,".Slice( 0,rank )+"]"
	End
	
	Property TypeId:String() Override
		If rank>1 Return "A"+rank+elemType.TypeId
		Return "A"+elemType.TypeId
	End

	Method FindNode:SNode( ident:String ) Override
	
		Return ctype.FindNode( ident )
	End
	
	Method FindType:Type( ident:String ) Override
	
		Return ctype.FindType( ident )
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		If args.Length<>rank Throw New SemantEx( "Wrong number of indices" )
		
		args=args.Slice( 0 )
		For Local i:=0 Until args.Length
			If Not args[i] Throw New SemantEx( "Missing array index" )
			args[i]=args[i].UpCast( Type.IntType )
		Next
		
		Return New ArrayIndexValue( Self,value,args )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Or type=ctype Return True
	
		Local atype:=TCast<ArrayType>( type )
		Return atype And rank=atype.rank And elemType.Equals( atype.elemType )
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If Equals( type ) Return 0
		
		If TCast<PrimType>( type )=BoolType Return MAX_DISTANCE
		
		Return -1
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
		
		Local atype:=TCast<ArrayType>( type )
		If Not atype Or rank<>atype.rank Return Null
		
		Local elemType:=Self.elemType.InferType( atype.elemType,infered )
		If Not elemType Return Null
		
		Return New ArrayType( elemType,rank )
	End
	
End

Class PointerType Extends Type

	Field elemType:Type
	
	Method New( elemType:Type )
		Self.elemType=elemType
		
		If elemType.IsGeneric flags|=TYPE_GENERIC
	End
	
	Method ToString:String() Override
	
		Return elemType.ToString()+" Ptr"
	End
	
	Property Name:String() Override
		Return elemType.Name+" Ptr"
	End
	
	Property TypeId:String() Override
		Return "P"+elemType.TypeId
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		If args.Length<>1 Throw New SemantEx( "Wrong number of indices" )
		
		Return New PointerIndexValue( elemType,value,args[0].UpCast( IntType ) )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Return True
	
		Local ptype:=TCast<PointerType>( type )
		Return ptype And elemType.Equals( ptype.elemType )
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		If type.Dealias=BoolType Return MAX_DISTANCE
		
		Local ptype:=TCast<PointerType>( type )
		If Not ptype Return -1
		
		If elemType.Equals( ptype.elemType ) Return 0
		
		'can cast any pointer to void ptr
		If ptype.elemType=VoidType Return MAX_DISTANCE
		
		Return -1
	End
	
	Method CanCastToType:Bool( type:Type ) Override
	
		If TCast<PointerType>( type ) Return True
		
		Local ptype:=TCast<PrimType>( type )
		If ptype And ptype.IsIntegral Return True
		
		Return False
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
	
		Local ptype:=TCast<PointerType>( type )
		If Not ptype Return Null
		
		Local elemType:=Self.elemType.InferType( ptype.elemType,infered )
		If Not elemType Return Null
		
		Return New PointerType( elemType )
	End

End

Class FuncType Extends Type

	Field retType:Type
	Field argTypes:Type[]
	
	Method New( retType:Type,argTypes:Type[] )
		Self.retType=retType
		Self.argTypes=argTypes
		
		If retType.IsGeneric Or AnyTypeGeneric( argTypes ) flags|=TYPE_GENERIC
	End
	
	Method ToString:String() Override
	
		Return retType.ToString()+"("+Join( argTypes )+")"
	End
	
	Property Name:String() Override

		Local args:=""
		For Local arg:=Eachin argTypes
			args+=","+arg.Name
		Next
		
		Return retType.Name+"("+args.Slice( 1 )+")"
	End
	
	Property TypeId:String() Override
		Local args:=""
		For Local arg:=Eachin argTypes
			args+=arg.TypeId
		Next
		Return "F"+retType.TypeId+args+"E"
	End
	
	Method Invoke:Value( args:Value[],value:Value ) Override
	
		If args.Length<>argTypes.Length Throw New SemantEx( "Wrong number of arguments - expecting "+argTypes.Length+" not "+args.Length )
		
		args=args.Slice( 0 )
		
		For Local i:=0 Until args.Length
			args[i]=args[i].UpCast( argTypes[i] )
		Next
		
		Return New InvokeValue( value,args )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Return True
	
		Local ftype:=TCast<FuncType>( type )
		If Not ftype Or argTypes.Length<>ftype.argTypes.Length Return False
		
		Return retType.Equals( ftype.retType ) And TypesEqual( argTypes,ftype.argTypes )
	End
	
	Method DistanceToType:Int( type:Type ) Override

		If Equals( type ) Return 0
		
'		If type.Dealias Return MAX_DISTANCE
		
		Return -1
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
		
		Local ftype:=TCast<FuncType>( type )
		If Not ftype Or argTypes.Length<>ftype.argTypes.Length Return Null
		
		Local retType:=Self.retType.InferType( ftype.retType,infered )
		If Not retType Return Null
		
		Local argTypes:=Self.argTypes.Slice( 0 )

		For Local i:=0 Until argTypes.Length
			argTypes[i]=argTypes[i].InferType( ftype.argTypes[i],infered )
			If Not argTypes[i] Return Null
		Next
		
		Return New FuncType( retType,argTypes )
	End
	
End

Class GenArgType Extends Type

	Field index:int
	Field ident:String
	Field types:Type[]
	Field instanceOf:GenArgType
	
	Method New( index:Int,ident:String,types:Type[],instanceOf:GenArgType )
		Self.index=index
		Self.ident=ident
		Self.types=types
		Self.instanceOf=instanceOf
		
		flags|=TYPE_GENERIC
	End
	
	Method ToString:String() Override

		Local str:=ident+"?"
		If types str+="<"+Join( types )+">"
		Return str
	End
	
	Property Name:String() Override
	
		Local args:=""
		For Local arg:=Eachin types
			args+=","+arg.Name
		Next
		If args args="<"+args.Slice( 1 )+">"
		
		Return ident+"?"+args
	End
	
	Property TypeId:String() Override
		SemantError( "GenArgType.TypeId()" )
		Return ""
	End
	
	Method GenInstance:Type( types:Type[] ) Override
	
		If Self.types SemantError( "GenArgType.GenInstance()" )
	
		Return New GenArgType( index,ident,types,Self )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Return True
		
		Local gtype:=TCast<GenArgType>( type )
	
		If Not gtype Or ident<>gtype.ident Return False
		
		If types.Length<>gtype.types.Length Return False

		If instanceOf And gtype.instanceOf And Not instanceOf.Equals( gtype.instanceOf ) Return False
		
		If instanceOf Or gtype.instanceOf Return False
		
		Return TypesEqual( types,gtype.types )
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If types
		
			Local ctype:=TCast<ClassType>( type )
			Local gtype:=TCast<GenArgType>( type )
			
			Local gtypes:Type[]
			
			If ctype
				gtypes=ctype.types
				type=ctype.instanceOf
			Else If gtype
				gtypes=gtype.types
				type=gtype.instanceOf
			Else
				Return Null
			Endif
			
			If types.Length<>gtypes.Length Return Null
			
			For Local i:=0 Until types.Length
				If Not types[i].InferType( gtypes[i],infered ) Return Null
			Next
			
		Endif
	
		If Not infered[index]
			infered[index]=type
			Return type
		Endif
		
		If infered[index].Equals( type ) Return type
		
		infered[index]=Type.BadType
		
		Return Null
	End
	
End

Class VoidType Extends Type

	Method ToString:String() Override
		Return "Void"
	End
	
	Property Name:String() Override
		Return "Void"
	End
	
	Property TypeId:String() Override
		Return "v"
	End
	
End

Class BadType Extends Type

	Method ToString:String() Override
		Return "<BadType>"
	End
	
	Property Name:String() Override
		Return "{BadType}"
	End
	
	Property TypeId:String() Override
		SemantError( "BadType.TypeId()" )
		Return ""
	End
	
	Method Equals:Bool( type:Type ) Override
		Return False
	End
	
End

Class NullType Extends Type

	Method ToString:String() Override
		Return "<NullType>"
	End

	Property Name:String() Override
		Return "{NullType}"
	End

	Property TypeId:String() Override
		SemantError( "NullType.TypeId()" )
		Return ""
	End
	
	Method Equals:Bool( type:Type ) Override
		Return False
	End
	
	Method DistanceToType:Int( type:Type ) Override
		Return MAX_DISTANCE
	End
	
End

