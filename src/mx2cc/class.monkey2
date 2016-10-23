
Namespace mx2

Class ClassDecl Extends Decl

	Field genArgs:String[]
	Field superType:Expr
	Field ifaceTypes:Expr[]
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i],Null,Null )
		Next
		
		Return New ClassType( Self,scope,types,Null )
	End
	
	Method ToString:String() Override
		Local str:=Super.ToString()
		If genArgs str+="<"+",".Join( genArgs )+">"
		If superType str+=" Extends "+superType.ToString()
		If ifaceTypes 
			If kind="interface" str+=" Extends "+Join( ifaceTypes ) Else str+=" Implements "+Join( ifaceTypes )
		Endif
		Return str
	End
	
End

Class ClassType Extends Type

	Field cdecl:ClassDecl
	Field types:Type[]
	Field instanceOf:ClassType
	Field transFile:FileDecl
	Field scope:ClassScope
	
	Field superType:ClassType
	Field ifaceTypes:ClassType[]
	Field allIfaces:ClassType[]
	
	Field instances:Stack<ClassType>
	
	Field membersSemanted:Bool
	Field membersSemanting:Bool

	Field abstractMethods:FuncValue[]
	
	Field ctors:=New Stack<FuncValue>
	Field methods:=New Stack<FuncValue>
	Field fields:=New Stack<VarValue>

	Field extendsVoid:Bool
	Field hasDefaultCtor:Bool
	
	Method New( cdecl:ClassDecl,outer:Scope,types:Type[],instanceOf:ClassType )
	
		Self.pnode=cdecl
		Self.cdecl=cdecl
		Self.types=types
		Self.instanceOf=instanceOf
		Self.transFile=outer.FindFile().fdecl
		
		If AnyTypeGeneric( types ) flags|=TYPE_GENERIC
		
		scope=New ClassScope( Self,outer )
		
		For Local member:=Eachin cdecl.members
			Local node:=member.ToNode( scope )
			scope.Insert( member.ident,node )
			Select member.kind
			Case "field" fields.Push( Cast<VarValue>( node ) )
'			Case "method" methods.Push( node )
			End
		Next
		
	End
	
	Property IsGenInstance:Bool()
	
		If instanceOf Return True

		Local ctype:=scope.outer.FindClass()
		If ctype Return ctype.IsGenInstance
		
		Return False
	End
	
	Property IsClass:Bool()
		Return cdecl.kind="class"
	End
	
	Property IsInterface:Bool()
		Return cdecl.kind="interface"
	End
	
	Property IsStruct:Bool()
		Return cdecl.kind="struct"
	End
	
	Property IsVirtual:Bool()
		Return cdecl.IsVirtual Or (superType And superType.IsVirtual)
	End
	
	Property ExtendsVoid:Bool()
		Return extendsVoid
	End

	Method ToString:String() Override
		Local str:=Name
		If cdecl.IsExtension str+=" Extension"
		Return str
	End
	
	Property Name:String() Override
		Return scope.Name
	End
	
	Property TypeId:String() Override
		Return scope.TypeId
	End
	
	Property IsAbstract:Bool()
		If Not membersSemanted
			If membersSemanting SemantError( "ClassType.IsAbstract()" )
			SemantMembers()
		Endif
		Return cdecl.IsAbstract Or abstractMethods
	End
	
	Method OnSemant:SNode() Override
	
		If cdecl.superType
		
			Try
				Local type:=cdecl.superType.SemantType( scope )

				If TCast<VoidType>( type )
				
					If Not cdecl.IsExtern Or cdecl.kind<>"class" Throw New SemantEx( "Only extern classes can extend 'Void'" )
					
					extendsVoid=True
					
				Else
				
					superType=TCast<ClassType>( type )
					
					If Not superType Or superType.cdecl.kind<>cdecl.kind Throw New SemantEx( "Type '"+type.ToString()+"' is not a valid super class type" )
					
					If superType.state=SNODE_SEMANTING Throw New SemantEx( "Cyclic inheritance error for '"+ToString()+"'",cdecl )
					
					If superType.cdecl.IsFinal Throw New SemantEx( "Superclass '"+superType.ToString()+"' is final" )
					
					extendsVoid=superType.extendsVoid
					
				Endif
				
			Catch ex:SemantEx
			
				superType=Null
			End
			
		Else If cdecl.kind="class" And Self<>ObjectClass

			superType=ObjectClass
			
		End
		
		If cdecl.ifaceTypes
		
			Local ifaces:=New Stack<ClassType>
			
			Local allifaces:=New Stack<ClassType>
				
			For Local iface:=Eachin cdecl.ifaceTypes
			
				Try
					Local type:=iface.SemantType( scope )

					Local ifaceType:=TCast<ClassType>( type )
					
					If Not ifaceType Or (ifaceType.cdecl.kind<>"interface" And ifaceType.cdecl.kind<>"protocol" ) Throw New SemantEx( "Type '"+type.ToString()+"' is not a valid interface type" )
					
					If cdecl.kind="interface" And ifaceType.cdecl.kind="protocol" Throw New SemantEx( "Interfaces cannot extends protocols" )
					
					If ifaceType.state=SNODE_SEMANTING Throw New SemantEx( "Cyclic inheritance error",cdecl )
					
					If ifaces.Contains( ifaceType ) Throw New SemantEx( "Duplicate interface '"+ifaceType.ToString()+"'" )
					
					ifaces.Push( ifaceType )
					
					allifaces.Push( ifaceType )
					
					For Local iface:=Eachin ifaceType.allIfaces
						
						If Not allifaces.Contains( iface ) allifaces.Push( iface )

					Next
					
				Catch ex:SemantEx
				End

			Next
			
			ifaceTypes=ifaces.ToArray()
			
			allIfaces=allifaces.ToArray()
		
		Endif
		
		If scope.IsGeneric Or cdecl.IsExtern
		
			Builder.semantMembers.AddLast( Self )
			
		Else
		
			If IsGenInstance
				SemantMembers()
				Local module:=Builder.semantingModule 
				module.genInstances.Push( Self )
			Else
				Builder.semantMembers.AddLast( Self )
			Endif
			
			transFile.classes.Push( Self )
			
		Endif
		
		Return Self
	End
	
	Method SemantMembers()
	
		If membersSemanted Return
	
		If membersSemanting SemantError( "ClassType.SemantMembers()" )
		
		membersSemanting=True
		
		'Semant funcs
		'
		Local flists:=New Stack<FuncList>

		Local abstractMethods:=New Stack<FuncValue>
		
		For Local it:=Eachin scope.nodes
		
			Local flist:=Cast<FuncList>( it.Value )
			If Not flist Continue
			
			flist.Semant()
			
			If flist.ident="new" Continue

			flists.Push( flist )
			
			For Local func:=Eachin flist.funcs

				If func.fdecl.IsAbstract abstractMethods.Push( func )
							
			Next

		Next
		
		'default ctor check
		'
		Local flist:=Cast<FuncList>( scope.GetNode( "new" ) )
		If flist
			hasDefaultCtor=False
			For Local func:=Eachin flist.funcs
				If func.ftype.argTypes Continue
				hasDefaultCtor=True
			Next
		Else
			If superType And Not superType.hasDefaultCtor
				Try
					Throw New SemantEx( "Super class '"+superType.Name+"' has no default constructor" )
				Catch ex:SemantEx
				End
			Endif
			
			hasDefaultCtor=True
		Endif
		
		If (cdecl.kind="class" Or cdecl.kind="struct") And Not scope.IsGeneric
		
			'Enum unimplemented superclass abstract methods
			'
			If superType
			
				For Local func:=Eachin superType.abstractMethods
				
					Local flist:=Cast<FuncList>( scope.nodes[func.fdecl.ident] )
					If flist And flist.FindFunc( func.ftype ) Continue
					
					abstractMethods.Push( func )
				Next

			Endif
			
			'Enum unimplemented interface methods
			'
			For Local iface:=Eachin allIfaces
				
				If superType And superType.ExtendsType( iface ) Continue
				
				For Local func:=Eachin iface.abstractMethods

					Local flist:=Cast<FuncList>( scope.nodes[func.fdecl.ident] )
					If flist And flist.FindFunc( func.ftype ) Continue
					
					abstractMethods.Push( func )
				Next
			
			Next
			
			'Add super class overloads to our scope.
			'
			If superType
			
				For Local flist:=Eachin flists
					
					Local flist2:=Cast<FuncList>( superType.scope.GetNode( flist.ident ) )
					If Not flist2 Continue
						
					For Local func2:=Eachin flist2.funcs
						If Not flist.FindFunc( func2.ftype )
							flist.PushFunc( func2 )
						Endif
					Next
	
				Next
			
			Endif
		
		Endif
		
		Self.abstractMethods=abstractMethods.ToArray()
		
		'Finished semanting funcs
		'
		membersSemanting=False
		membersSemanted=True
		
		'Semant non-func members
		'
		For Local node:=Eachin scope.nodes.Values
			If Cast<FuncList>( node ) Continue
			Try
				node.Semant()
			Catch ex:SemantEx
			End
		Next
	
	End
	
	Method FindSuperNode:SNode( ident:String )
	
		Local ctype:=superType
		While ctype
			Local node:=ctype.scope.GetNode( ident )
			If node Return node
			ctype=ctype.superType
		Wend
		
		Return Null
	End

	Method FindSuperFunc:FuncValue( ident:String,ftype:FuncType )
	
		Local node:=Cast<FuncList>( FindSuperNode( ident ) )
		If node Return node.FindFunc( ftype )
		
		Return Null
	End

	Method FindNode2:SNode( ident:String )
		If membersSemanting SemantError( "ClassType.FindNode() class='"+ToString()+"', ident='"+ident+"'" )
	
		Local node:=scope.GetNode( ident )
		If node Or ident="new" Return node
		
		If superType Return superType.FindNode2( ident )
		Return Null
	End

	Method FindType2:Type( ident:String )
	
		Local type:=scope.GetType( ident )
		If type Return type
		
		If superType Return superType.FindType2( ident )
		Return Null
	End

	'***** Type overrides *****
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=FindNode2( ident )
		If ident="new" Return node
		
		node=FileScope.FindExtensions( ident,Self,node )
		
		Return node
	End
		
	Method FindType:Type( ident:String ) Override
	
		Local type:=FindType2( ident )
		
		Return type
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		Return New OpIndexValue( Self,args,value )
	End
	
	'Create an instance of a generic class.
	'
	'Ok for types[] to contain generic types, eg: in case of generating Y<T> in "Class X<T> Extends Y<T>"
	'
	Method GenInstance:Type( types:Type[] ) Override
			
		'FIXME! This is (mainly) so code can generate C<T2> inside class C<T>
		'
		If instanceOf Return instanceOf.GenInstance( types )

		If Not IsGeneric Throw New SemantEx( "Class '"+ToString()+"' is not generic" )

		If types.Length<>Self.types.Length Throw New SemantEx( "Wrong number of generic type parameters" )

'		If AnyTypeGeneric( types ) Return Self

		If Not instances instances=New Stack<ClassType>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New ClassType( cdecl,scope.outer,types,Self )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End
	
	Method FindToFunc:FuncValue( type:Type )
	
		Local flist:=Cast<FuncList>( FindNode( "to" ) )
		If Not flist Return Null
		
		Return overload.FindOverload( flist.funcs,type,Null )
	End
	
	Method DistanceToBase:Int( type:Type )
	
		Local ctype:=TCast<ClassType>( type )
		If Not ctype Return -1

		Local dist:=0
		Local stype:=Self
		
		While stype
		
			If stype.Equals( ctype ) Return dist
			
			If ctype.cdecl.kind="interface" Or ctype.cdecl.kind="protocol"
				For Local iface:=Eachin stype.allIfaces
					If iface.Equals( ctype ) Return dist
				Next
			Endif
			
			stype=stype.superType
			dist+=1
		Wend
		
		Return -1
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		'no struct->bool as yet.
		If type=BoolType Return (IsClass Or IsInterface) ? MAX_DISTANCE Else -1
		
		If type=VariantType Return MAX_DISTANCE

		'Cast to super class
		Local dist:=DistanceToBase( type )
		If dist>=0 Return dist
		
		'Operator To:
		Local func:=FindToFunc( type )
		If func Return MAX_DISTANCE
		
		Return -1

		#rem
		'cast native classes to void ptr		
		Local ptype:=TCast<PointerType>( type )
		If ptype 
			If IsVoid And ptype.elemType=Type.VoidType Return MAX_DISTANCE
			Return -1
		Endif
		#end
	End
	
	Method UpCast:Value( rvalue:Value,type:Type ) Override
	
		If type.Equals( rvalue.type ) Return rvalue

		'Cast to superclass
		Local dist:=DistanceToBase( type )
		If dist>=0 Return New UpCastValue( type,rvalue )
		
		'instance->variant
		If type=VariantType Return New UpCastValue( type,rvalue )
	
		'instance->bool
		If type=BoolType
			If IsClass Or IsInterface Return New UpCastValue( type,rvalue )
		Else
			'Operator To:
			Local func:=FindToFunc( type )
			If func Return func.ToValue( rvalue ).Invoke( Null )
		Endif

		Throw New SemantEx( "Unable to convert value from type '"+rvalue.type.ToString()+"' to type '"+type.ToString()+"'" )
		
		Return Null
	End

	Method ExtendsType:Bool( type:Type ) Override
	
		Return DistanceToBase( type )>=0
	End
	
	Method CanCastToType:Bool( type:Type ) Override
	
		Local ctype:=TCast<ClassType>( type )
		If Not ctype Return False
		
		Select cdecl.kind
		Case "class"
			If ctype.cdecl.kind="class" Return ctype.ExtendsType( Self )
			If ctype.cdecl.kind="interface" Return True
		Case "interface"
			If ctype.cdecl.kind="class" Return True
			If ctype.cdecl.kind="interface" Return True
		End
		
		Return False
	End
	
	Method InferType:Type( type:Type,infered:Type[] ) Override
	
		If Not IsGeneric Return Super.InferType( type,infered )
		
		Local ctype:=TCast<ClassType>( type )
		If Not ctype Return Null
		
		If types.Length<>ctype.types.Length Return Null

		Local types:=Self.types.Slice( 0 )

		For Local i:=0 Until types.Length
			types[i]=types[i].InferType( ctype.types[i],infered )
			If Not types[i] Return Null
		Next
		
		Return GenInstance( types )
	End
	
End

Class OpIndexValue Extends Value

	Field ctype:ClassType
	Field args:Value[]
	Field instance:Value

	Field getters:FuncList
	Field setters:FuncList
	Field invokeGet:Value

	Method New( ctype:ClassType,args:Value[],instance:Value )
		Self.type=Type.VoidType
		Self.args=args
		Self.instance=instance	
	
		getters=Cast<FuncList>( ctype.FindNode( "[]" ) )
		setters=Cast<FuncList>( ctype.FindNode( "[]=" ) )
		
		If Not getters And Not setters Throw New SemantEx( "Type '"+ToString()+"' cannot be indexed" )

		If getters
			invokeGet=getters.ToValue( instance ).Invoke( args )	'TODO: really just want to find overload here...
			type=invokeGet.type
		Endif
		
		If setters flags|=VALUE_ASSIGNABLE
	End
	
	Method ToString:String() Override
		Return instance.ToString()+"["+Join( args )+"]"
	End
	
	Method ToRValue:Value() Override
	
		If Not invokeGet Throw New SemantEx( "Value cannot be indexed" )
		
		Return invokeGet
	End
	
	Method Assign:Stmt( pnode:PNode,op:String,rvalue:Value,block:Block ) Override
		
		If Not setters Throw New SemantEx( "Value cannot be index assigned" )
		
		Local args:=Self.args
		
		Local inst:=instance
		
		If op<>"="
		
			If Not getters Throw New SemantEx( "Value cannot be indexed" )
			
			inst=inst.RemoveSideEffects( block )
			
			args=args.Slice( 0 )
			For Local i:=0 Until args.Length
				If args[i] args[i]=args[i].RemoveSideEffects( block )
			Next
			
			Local value:=getters.ToValue( inst ).Invoke( args )
			
			Local op2:=op.Slice( 0,-1 )
			Local node:=value.FindValue( op2 )
			If node
				Local args:=New Value[1]
				args[0]=rvalue
				rvalue=node.Invoke( args )
			Else

				Local rtype:=BalanceAssignTypes( op,value.type,rvalue.type )
				rvalue=New BinaryopValue( value.type,op2,value,rvalue.UpCast( rtype ) )
				
'				ValidateAssignOp( op,value.type )
'				Local rtype:=value.type
'				If op2="shl" Or op2="shr" rtype=Type.IntType
'				rvalue=New BinaryopValue( value.type,op2,value,rvalue.UpCast( rtype ) )

			Endif
		
		Endif
		
		Local args2:=New Value[Self.args.Length+1]
	
		For Local i:=0 Until args.Length
			args2[i]=args[i]
		Next
		args2[args.Length]=rvalue
		
		Return New EvalStmt( pnode,setters.ToValue( inst ).Invoke( args2 ) )
	End
	
	'should never be called
	'
	Property HasSideEffects:Bool() Override
		SemantError( "OpIndexValue.HasSideEffects()" )
		Return False
	End
	
End

Class ClassScope Extends Scope

	Field ctype:ClassType
	
	Field itype:Type
	
	Method New( ctype:ClassType,outer:Scope )
		Super.New( outer )

		Self.ctype=ctype
		
	End
	
	Property Name:String() Override

		Local args:=""
		For Local arg:=Eachin ctype.types
			args+=","+arg.Name
		Next
		If args args="<"+args.Slice( 1 )+">"
		
		If ctype.cdecl.ident.StartsWith( "@" ) Return ctype.cdecl.ident.Slice( 1 ).Capitalize()+args
		
		Return outer.Name+"."+ctype.cdecl.ident+args
	End
	
	Property TypeId:String() Override
	
		Local args:=""
		For Local arg:=Eachin ctype.types
			args+=arg.TypeId
		Next
		If args args="_1"+args+"E"
		
		Return "T"+outer.TypeId+"_"+ctype.cdecl.ident.Replace( "_","_0" )+args+"_2"
	End
	
	Property IsInstanceOf:Bool() Override
	
		If ctype.instanceOf Return True
		
		Return Super.IsInstanceOf
	End
	
	Property IsGeneric:Bool() Override

		If ctype.IsGeneric Return True
		
		Return Super.IsGeneric
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=ctype.FindNode( ident )
		If node Return node

		If outer Return outer.FindNode( ident )
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Override
	
		If ident=ctype.cdecl.ident And Not ctype.cdecl.IsExtension
			If Not itype
				If ctype.types And Not ctype.instanceOf
					itype=ctype.GenInstance( ctype.types )
				Else 
					itype=ctype
				Endif
			Endif
			Return itype
		Endif
		
		For Local i:=0 Until ctype.cdecl.genArgs.Length
			If ident=ctype.cdecl.genArgs[i] Return ctype.types[i]
		Next
		
		Local type:=ctype.FindType( ident )
		If type Return type
		
		If outer Return outer.FindType( ident )
		
		Return Null
	End
	
	Method FindClass:ClassType() Override

		Return ctype
	End
	
End
