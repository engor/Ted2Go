
Namespace mx2

Class ClassDecl Extends Decl

	Field genArgs:String[]
	Field superType:TypeExpr
	Field ifaceTypes:TypeExpr[]
	
	Method ToString:String() Override
		Local str:=Super.ToString()
		If genArgs str+="<"+",".Join( genArgs )+">"
		If superType str+=" extends "+superType.ToString()
		If ifaceTypes str+=" implements "+Join( ifaceTypes )
		Return str
	End
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i],Null,Null )
		Next
		
		Return New ClassType( Self,scope,types,Null )
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
	
	Field isvoid:Bool	'Extends 'Void'?
	
	Field instances:Stack<ClassType>
	
	Field membersSemanted:Bool
	Field membersSemanting:Bool

	Field abstractMethods:FuncValue[]
	
	Field ctors:=New Stack<FuncValue>
	Field methods:=New Stack<FuncValue>
	Field fields:=New Stack<VarValue>
	
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
	
	Property IsAbstract:Bool()
		Return cdecl.IsAbstract Or abstractMethods
	End
	
	Property IsVirtual:Bool()
		Return cdecl.IsVirtual Or (superType And superType.IsVirtual)
	End
	
	Property IsVoid:Bool()
		Return isvoid Or (superType And superType.IsVoid)
	End
	
	Method ToString:String() Override
		Local str:=cdecl.ident
		If types str+="<"+Join( types )+">"
		Return str
	End
	
	Property Name:String() Override
		Return scope.Name
	End
	
	Property TypeId:String() Override
		Return scope.TypeId
	End
	
	Method OnSemant:SNode() Override
	
		If cdecl.superType
		
			Try
				Local type:=cdecl.superType.Semant( scope )
				If TCast<VoidType>( type )
				
					If Not cdecl.IsExtern Or cdecl.kind<>"class" Throw New SemantEx( "Only extern classes can extend 'Void'" )
					
					isvoid=True
					
				Else
				
					superType=TCast<ClassType>( type )
					
					If Not superType Or superType.cdecl.kind<>cdecl.kind Throw New SemantEx( "Type '"+type.ToString()+"' is not a valid super class type" )
					
					If superType.state=SNODE_SEMANTING Throw New SemantEx( "Cyclic inheritance error for '"+ToString()+"'",cdecl )
					
					If superType.cdecl.IsFinal Throw New SemantEx( "Superclass '"+superType.ToString()+"' is final" )
					
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
					Local type:=iface.Semant( scope )
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
		
		Local builder:=Builder.instance
		
		If scope.IsGeneric Or cdecl.IsExtern
		
			builder.semantMembers.AddLast( Self )
			
		Else
		
			If IsGenInstance
				SemantMembers()
				Local module:=builder.semantingModule 
				module.genInstances.Push( Self )
			Else
				builder.semantMembers.AddLast( Self )
			Endif
			
			transFile.classes.Push( Self )
			
		Endif
		
		Return Self
	End
	
	Method SemantMembers()
	
'		Print "Semanting members: "+ToString()
	
		If membersSemanted Or membersSemanting Return
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
			
				If func.fdecl.IsIfaceMember abstractMethods.Push( func )
				
			Next
			
		Next
		
		If (cdecl.kind="class" Or cdecl.kind="struct") And Not scope.IsGeneric
		
			'Enum unimplemented superclass abstract methods
			'
			If superType
			
				For Local func:=Eachin superType.abstractMethods
				
					Try
						Local flist:=Cast<FuncList>( scope.nodes[func.fdecl.ident] )
						If flist
							Local func2:=flist.FindFunc( func.ftype.argTypes )
							If func2
								If func2.ftype.retType.ExtendsType( func.ftype.retType ) Continue
								Throw New SemantEx( "Overriding method '"+func2.ToString()+"' has incompatible return type",func2.fdecl )
							Endif
						Endif
						
						abstractMethods.Push( func )
						
					Catch ex:SemantEx
					End
					
				Next

			Endif
			
			'Enum unimplemented interface methods
			'
			For Local iface:=Eachin allIfaces
				
				If superType And superType.ExtendsType( iface ) Continue
				
				For Local func:=Eachin iface.abstractMethods
				
'					Print "abstractMethod="+func.ToString()

					Try
						#rem
						Local flist:=Cast<FuncList>( scope.nodes[func.fdecl.ident] )
						If flist
							Local func2:=overload.FindOverload( flist.funcs,func.ftype.retType,func.ftype.argTypes )
							If func2
								If func2.IsGeneric Continue
								If TypesEqual( func2.ftype.argTypes,func.ftype.argTypes ) Continue
								Throw New SemantEx( "ERROR!",func2.fdecl )
							Endif
						Endif
						
						If func.fdecl.IsDefault
							scope.Insert( func.fdecl.ident,func )
							Continue
						Endif
						
						abstractMethods.Push( func )
						#end
						
						Local flist:=Cast<FuncList>( scope.nodes[func.fdecl.ident] )
						If flist
							Local func2:=flist.FindFunc( func.ftype.argTypes )
							If func2
								If func2.ftype.retType.ExtendsType( func.ftype.retType ) Continue
								Throw New SemantEx( "Overriding method '"+func2.ToString()+"' has incompatible return type",func2.fdecl )
							Endif
						Endif
						
						If func.fdecl.IsDefault
							scope.Insert( func.fdecl.ident,func )
							Continue
						Endif
						
						abstractMethods.Push( func )
					
					Catch ex:SemantEx
					End

				Next
			
			Next
			
			If superType
			
				For Local flist:=Eachin flists
					
					Local flist2:=Cast<FuncList>( superType.scope.GetNode( flist.ident ) )
					If Not flist2 Continue
						
					For Local func2:=Eachin flist2.funcs
						If Not flist.FindFunc( func2.ftype.argTypes ) flist.PushFunc( func2 )
					Next
	
				Next
			
			Endif
		
		Endif
		
		Self.abstractMethods=abstractMethods.ToArray()
		
		'Finished semanting funcs
		'
		membersSemanting=False
		membersSemanted=True

		'Semant vars - should probably do this in another phase?
		'		
		For Local it:=Eachin scope.nodes
		
			Try
				If Not Cast<FuncList>( it.Value ) it.Value.Semant()
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
	
	Method FindSuperFunc:FuncValue( ident:String,argTypes:Type[] )
	
		Local node:=Cast<FuncList>( FindSuperNode( ident ) )
		If node Return node.FindFunc( argTypes )
		
		Return Null
	End
	
	'***** Type overrides *****

	Method FindNode:SNode( ident:String ) Override
	
		If membersSemanting SemantError( "ClassType.FindNode() class='"+ToString()+"', ident='"+ident+"'" )
	
		Local node:=scope.GetNode( ident )
		If node Or ident="new" Return node
		
		If superType Return superType.FindNode( ident )
		
		Return Null
	End
		
	Method FindType:Type( ident:String ) Override
	
		Local type:=scope.GetType( ident )
		If type Return type
		
		If superType Return superType.FindType( ident )
		
		Return Null
	End
	
	Method Index:Value( args:Value[],value:Value ) Override
	
		Return New OpIndexValue( Self,args,value )
	End
	
	'Create an instance of a generic class.
	'
	'Ok for types[] to contain generic types, eg: in case of generating Y<T> in "Class X<T> Extends Y<T>"
	'
	Method GenInstance:Type( types:Type[] ) Override
			
		'FIXME! This is (minaly) so code can generate C<T2> inside class C<T>
		'
		If instanceOf Return instanceOf.GenInstance( types )

		If Not IsGeneric

			Throw New SemantEx( "Class '"+ToString()+"' is not generic" )

		Endif

		If types.Length<>Self.types.Length Throw New SemantEx( "Wrong number of generic type parameters" )

		If Not instances instances=New Stack<ClassType>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New ClassType( cdecl,scope.outer,types,self )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End
	
	Method ExtendsType:Bool( type:Type ) Override
	
		Local t:=DistanceToType( type )
		
		Return t>=0 And t<MAX_DISTANCE
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		'cast anything to bool
		If type=BoolType Return MAX_DISTANCE

		#rem
		'cast native classes to void ptr		
		Local ptype:=TCast<PointerType>( type )
		If ptype 
			If IsVoid And ptype.elemType=Type.VoidType Return MAX_DISTANCE
			Return -1
		Endif
		#end
		
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
	
	#rem
	Method UpCast:Value( type:Type ) Override
	
		Return ToRValue().UpCast( type )
	End
	#end
	
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
	
	Field genTypes:=New StringMap<Type>
	
	Method New( ctype:ClassType,outer:Scope )
		Super.New( outer )

		Self.ctype=ctype
		
		'so code can access 'List' instead of 'List<T>'
		genTypes[ctype.cdecl.ident]=ctype

		'so code can access gen args
		Local genArgs:=ctype.cdecl.genArgs
		For Local i:=0 Until genArgs.Length
			genTypes[genArgs[i]]=ctype.types[i]
		Next
	End
	
	Property Name:String() Override

		Local args:=""
		For Local arg:=Eachin ctype.types
			args+=","+arg.Name
		Next
		If args args="<"+args.Slice( 1 )+">"
		
		If ctype.cdecl.ident.StartsWith( "@" ) Return ctype.cdecl.ident.Slice( 1  ).Capitalize()+args
		
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
	
		Local type:=genTypes[ident]
		If type Return type
	
		type=ctype.FindType( ident )
		If type Return type
		
		If outer Return outer.FindType( ident )
		
		Return Null
	End
	
	Method FindClass:ClassType() Override

		Return ctype
	End
	
End
