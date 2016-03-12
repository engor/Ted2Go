
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
	
	Global CStringClass:ClassType
	Global WStringClass:ClassType
	Global Utf8StringClass:ClassType
	
	Field flags:Int
	
	Property IsGeneric:Bool()
		Return flags & TYPE_GENERIC
	End
	
	Method ToType:Type() Override
		Return Self
	End

	Method ToValue:Value( instance:Value ) Override
		Return New TypeValue( Self )
	End
	
	Method FindNode:SNode( ident:String ) Virtual
		Return Null
	End
	
	Method FindType:Type( ident:String ) Virtual
		Throw New SemantEx( "Type '"+ToString()+"' has no scope" )
		Return Null
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
	
	Method Equals:Bool( type:Type ) Virtual
		Return type=Self
	End
	
	Method DistanceToType:Int( type:Type ) Virtual
		If Equals( type ) Return 0
		Return -1
	End
	
	Method InferType:Type( type:Type,args:Type[] ) Virtual
		If Equals( type ) Return type	
		Return Null
	End
	
	Method CanCastToType:Bool( type:Type ) Virtual
		Return DistanceToType( type )>=0 Or type.CanCastToType( Self )
	End
	
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

		Return type=Self Or type=ctype
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Or type=ctype Return 0

		Local ptype:=Cast<PrimType>( type )
		If ptype
			If ptype=BoolType Return MAX_DISTANCE
			If IsNumeric And (ptype=StringType Or ptype.IsNumeric) Return MAX_DISTANCE
			If Self=BoolType And ptype.IsNumeric Return MAX_DISTANCE
		Endif
		
		Select type
		Case CStringClass,WStringClass,Utf8StringClass
			Return MAX_DISTANCE
		End
		
'		Return ctype.DistanceToType( type )+1
		
		Return -1
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
			ctype=Cast<ClassType>( ctype.GenInstance( types ) )
		Endif
		
		If Not ctype SemantError( "ArrayType.New()" )
	End

	Method ToString:String() Override

		Return elemType.ToString()+"[,,,,,,,,,,".Slice( 0,rank )+"]"
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
	
		Local atype:=Cast<ArrayType>( type )
		Return atype And rank=atype.rank And elemType.Equals( atype.elemType )
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If Equals( type ) Return 0
		
		If type=BoolType Return MAX_DISTANCE
		
		Return -1
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
		
		Local atype:=Cast<ArrayType>( type )
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
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		If args.Length<>1 Throw New SemantEx( "Wrong number of indices" )
		
		Return New PointerIndexValue( elemType,value,args[0].UpCast( IntType ) )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Return True
	
		Local ptype:=Cast<PointerType>( type )
		Return ptype And elemType.Equals( ptype.elemType )
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		If type=Type.BoolType Return MAX_DISTANCE
		
		Local ptype:=Cast<PointerType>( type )
		If Not ptype Return -1
		
		If elemType.Equals( ptype.elemType ) Return 0
		
		'can cast any pointer to void ptr
		If ptype.elemType=VoidType Return MAX_DISTANCE
		
		Return -1
	End
	
	Method CanCastToType:Bool( type:Type ) Override
	
		If Cast<PointerType>( type ) Return True
		
		Local ptype:=Cast<PrimType>( type )
		If ptype And ptype.IsNumeric Return True
		
		Return False
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
	
		Local ptype:=Cast<PointerType>( type )
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
	
		Local ftype:=Cast<FuncType>( type )
		If Not ftype Or argTypes.Length<>ftype.argTypes.Length Return False
		
		Return retType.Equals( ftype.retType ) And TypesEqual( argTypes,ftype.argTypes )
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If Equals( type ) Return 0
		
		If type=BoolType Return MAX_DISTANCE
		
		Return -1
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
		
		Local ftype:=Cast<FuncType>( type )
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

		Local str:=ident
		If types str+="<"+Join( types )+">"
		Return str+"?"
	End
	
	Method GenInstance:Type( types:Type[] ) Override
	
		If Self.types SemantError( "GenArgType.GenInstance()" )
	
		Return New GenArgType( index,ident,types,Self )
	End
	
	Method Equals:Bool( type:Type ) Override
	
		If type=Self Return True
		
		Local gtype:=Cast<GenArgType>( type )
	
		If Not gtype Or ident<>gtype.ident Return False
		
		If types.Length<>gtype.types.Length Return False

		If instanceOf And gtype.instanceOf And Not instanceOf.Equals( gtype.instanceOf ) Return False
		
		If instanceOf Or gtype.instanceOf Return False
		
		Return TypesEqual( types,gtype.types )
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If types
		
			Local ctype:=Cast<ClassType>( type )
			Local gtype:=Cast<GenArgType>( type )
			
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
	
End

Class BadType Extends Type

	Method ToString:String() Override
		Return "<BadType>"
	End
	
	Method Equals:Bool( type:Type ) Override
		Return False
	End
	
End

Class NullType Extends Type

	Method ToString:String() Override
		Return "<NullType>"
	End

	Method Equals:Bool( type:Type ) Override
		Return False
	End
	
	Method DistanceToType:Int( type:Type ) Override
		Return MAX_DISTANCE
	End
	
End

