
Namespace mx2

'***** FuncDecl *****

Class FuncDecl Extends Decl

	Field genArgs:String[]
	Field type:FuncTypeExpr
	Field whereExpr:Expr
	
	Field stmts:StmtExpr[]
	
	Method ToString:String() Override
		Local str:=Super.ToString()
		If genArgs str+="<"+",".Join( genArgs )+">"
		Return str+":"+type.ToString()
	End
	
	Method Emit( buf:StringStack,spc:String ) Override
		buf.Push( spc+ToString() )
		EmitStmts( stmts,buf,spc )
		buf.Push( spc+"End" )
	End
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i],Null,Null )
		Next
		
		Return New FuncValue( Self,scope,types,Null )
	End

End

'***** FuncValue *****

Class FuncValue Extends Value

	Field fdecl:FuncDecl
	Field scope:Scope
	Field types:Type[]
	Field instanceOf:FuncValue
	Field pdecls:VarDecl[]
	Field transFile:FileDecl
	
	Field block:Block
	Field ftype:FuncType
	
	Field params:VarValue[]
	Field selfValue:Value
	
	Field instances:Stack<FuncValue>
	
	Field captures:Stack<VarValue>
	
	Field nextLocalId:Int

	Field invokeNew:InvokeNewValue	'call to Super.New or Self.new
	
	Field used:Bool
	
	Method New( fdecl:FuncDecl,scope:Scope,types:Type[],instanceOf:FuncValue )
	
		Self.pnode=fdecl
		Self.fdecl=fdecl
		Self.scope=scope
		Self.types=types
		Self.instanceOf=instanceOf
		Self.pdecls=fdecl.type.params
		Self.transFile=scope.FindFile().fdecl
		
		If fdecl.kind="lambda" captures=New Stack<VarValue>
	End
	
	Property IsGeneric:Bool()
	
		If Not ftype SemantError( "FuncValue.IsGeneric()" )
		
		Return ftype.IsGeneric
	End
	
	Property IsGenInstance:Bool()
	
		Return instanceOf
	End
	
	Property IsCtor:Bool()
		Return fdecl.ident="new"
	End
	
	Property IsMethod:Bool()
		Return fdecl.kind="method" And fdecl.ident<>"new"
	End
	
	Property IsExtension:Bool()
		Return (fdecl.kind="method" And types) Or fdecl.IsExtension
	End
	
	Property IsExtMethod:Bool()
	
		Return fdecl.kind="method" And types
	End
	
	Method ToString:String() Override
'		Return fdecl.ident
		Local str:=fdecl.ident
		If types str+="<"+Join( types )+">"
		Return str+":"+ftype.retType.ToString()+"("+Join( ftype.argTypes )+")"
	End
	
	Method OnSemant:SNode() Override

		'create top func block
		block=New Block( Self )
		
		'insert type args
		For Local i:=0 Until fdecl.genArgs.Length
			block.Insert( fdecl.genArgs[i],types[i] )
		Next
	
		'TODO: Generic ctors
		If IsCtor And types Throw New SemantEx( "Constructors cannot be generic" )

		'semant func type
		type=fdecl.type.Semant( block )
		ftype=Cast<FuncType>( type )
		
		If fdecl.kind="lambda"
			semanted=Self
			SemantStmts()
		Else If Not types And Not fdecl.IsExtern
			Local builder:=Builder.instance
			builder.semantStmts.Push( Self )
		Endif
		
		Return Self
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		Local value:Value=Self
	
		If fdecl.ident="new"
		
			If instance Throw New SemantEx( "'New' cannot be directly invoked" )
			
		Else If fdecl.kind="method"
		
			If Not instance Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed without an instance" )
			
			If instance.type.DistanceToType( Cast<ClassScope>( scope ).ctype )<0 Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed from instance of a different class" )
			
			value=New MemberFuncValue( instance,Self )
		Endif
		
		Used()
		
		Return value
	End
	
	Method GenInstance:Value( types:Type[] ) Override
	
		If AnyTypeGeneric( types ) SemantError( "FuncValue.GenInstance()" )
		
		If Not IsGeneric Return Super.GenInstance( types )
		
		Local value:=TryGenInstance( types )
		
		If Not value Throw New SemantEx( "Failed to create generic instance of '"+ToString()+"' with types '<"+Join( types )+">'" )
		
		Return value
	End
	
	Method Invoke:Value( args:Value[] ) Override
	
		Return Super.Invoke( FixArgs( args ) )
	End
	
	Method CheckAccess( tscope:Scope ) Override
		CheckAccess( fdecl,scope,tscope )
	End
	
	Method SemantParams()

		params=New VarValue[pdecls.Length]

		For Local i:=0 Until pdecls.Length
		
			Local param:=New VarValue( pdecls[i],block )
			
			Try
			
				param.Semant()
				
				block.Insert( pdecls[i].ident,param )
				
				params[i]=param
				
			Catch ex:SemantEx
			End
		Next
	
		If IsExtMethod

			selfValue=New VarValue( "capture","self",New LiteralValue( Cast<ClassScope>( scope ).ctype,"" ),scope )
			
		Else If fdecl.kind="method"
		
			selfValue=New SelfValue( Cast<ClassScope>( scope ).ctype )
			
		Else If fdecl.kind="lambda"
		
			selfValue=Cast<Block>( scope ).func.selfValue
			If selfValue
				selfValue=New VarValue( "capture","self",selfValue,block )
				captures.Push( Cast<VarValue>( selfValue ) )
			Endif
		
		Endif
	End
	
	Method SemantInvokeNew()
	
		If fdecl.ident<>"new" Or invokeNew Return

		Local superType:=scope.FindClass().superType
		If Not superType Return

		Local flist:=Cast<FuncList>( superType.FindNode( "new" ) )
		If Not flist Return
		
		Local func:=flist.FindFunc( Null )
		If func Return

		Throw New SemantEx( "Class '"+superType.ToString()+"' has no default constructor",pnode )
	End
	
	Method SemantStmts()
	
		If block.IsGeneric Return
	
		Try
		
			SemantParams()
			
		Catch ex:SemantEx
		
		End
		
		If Not fdecl.IsAbstract And Not fdecl.IsIfaceMember
			
			Local reachable:=block.Semant( fdecl.stmts )
			
			If reachable And ftype.retType<>Type.VoidType Throw New SemantEx( "Missing return statement" )

			SemantInvokeNew()
			
		Endif
		
		If fdecl.kind="function" Or IsExtMethod
		
			transFile.functions.Push( Self )
			
			If fdecl.ident="Main" And ftype.retType=Type.VoidType And Not ftype.argTypes
				Local module:=scope.FindFile().fdecl.module
				If module.main Throw New SemantEx( "Duplicate declaration of 'Main'" )
				module.main=Self
			Endif
			
			If IsGenInstance
				Local builder:=Builder.instance
				Local module:=builder.semantingModule
				module.genInstances.Push( Self )
			Endif

		Else
			scope.transMembers.Push( Self )
		Endif
	End
	
	Method TryGenInstance:FuncValue( types:Type[] )
	
'		If AnyTypeGeneric( types ) Print "TryGenInstance:"+fdecl.ident+"<"+Join( types )+">"
	
		If Not IsGeneric Return Null
		
		If types.Length<>Self.types.Length Return Null
		
		If Not instances instances=New Stack<FuncValue>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New FuncValue( fdecl,scope,types,Self )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End
	
	Method FixArgs:Value[]( args:Value[] )
	
		Local args2:=New Value[pdecls.Length]
		
		For Local i:=0 Until args2.Length
			If i<args.Length And args[i]
				args2[i]=args[i]
			Else
				If pdecls[i] args2[i]=pdecls[i].init.Semant( scope )
			Endif
		Next
		
		Return args2
	End

	Method Used()
	
		If used Return
		used=True
		
		If fdecl.kind<>"lambda" And types And Not fdecl.IsExtern
			Local builder:=Builder.instance
			builder.semantStmts.Push( Self )
		Endif
		
	End
	
End

'***** MemberFuncValue *****

Class MemberFuncValue Extends Value

	Field instance:Value
	Field member:FuncValue
	
	Method New( instance:Value,member:FuncValue )
		Self.type=member.type
		Self.instance=instance
		Self.member=member
	End
	
	Method ToString:String() Override
		Return instance.ToString()+"."+member.ToString()
	End
	
	Property HasSideEffects:Bool() Override
		Return instance.HasSideEffects
	End
	
	Method CheckAccess( tscope:Scope ) Override
		member.CheckAccess( tscope )
	End

End

'***** FuncListValue *****

Class FuncListValue Extends Value

	Field flistType:FuncListType
	Field instance:Value
	
	Method New( flistType:FuncListType,instance:Value )
		Self.type=flistType
		Self.flistType=flistType
		Self.instance=instance
	End
	
	Method ToString:String() Override
		Return flistType.flist.ident
	End
	
	Method GenInstance:Value( types:Type[] ) Override
	
		Local flistType:=Self.flistType.flist.GenFuncListType( types )
		
		Return New FuncListValue( flistType,instance )
	End
	
	Method Invoke:Value( args:Value[] ) Override
	
		Local func:=flistType.FindOverload( Null,Types( args ) )
		If Not func Throw New OverloadEx( Self,Types( args ) )
		
		Local value:=func.ToValue( instance )
		
		value=value.Invoke( func.FixArgs( args ) )
		
		Return value
	End
	
	Method ToRValue:Value() Override
	
		If flistType.funcs.Length>1 Throw New SemantEx( "Value '"+ToString()+"' is overloaded" )
		
		Local func:=flistType.funcs[0]
		If func.IsGeneric Throw New SemantEx( "Value '"+ToString()+"' is generic" )
		
		Return func.ToValue( instance )
	End
	
	Method UpCast:Value( type:Type ) Override
	
		Local ftype:=Cast<FuncType>( type )
		If Not ftype Throw New UpCastEx( Self,type )
		
		Local func:=flistType.FindOverload( ftype.retType,ftype.argTypes )
		If Not func Throw New OverloadEx( Self,ftype.argTypes )
		If Not func.ftype.Equals( ftype ) Throw New UpCastEx( Self,type )
		
		Return func.ToValue( instance )
	End
	
End

'***** FuncListType *****

Class FuncListType Extends Type

	Field flist:FuncList
	Field funcs:Stack<FuncValue>
	Field types:Type[]
	
	Method New( flist:FuncList )
	
		Self.flist=flist
		Self.funcs=flist.funcs
	End
	
	Method New( flist:FuncList,types:Type[] )

		Self.flist=flist
		Self.funcs=New Stack<FuncValue>
		Self.types=types
		
		For Local func:=Eachin flist.funcs
			Local func2:=func.TryGenInstance( types )
			If func2 funcs.Push( func2 )
		Next
	End
	
	Method ToString:String() Override
		Local str:=""
		If types str="<"+Join( types )+">"
		Return flist.ident+str+"(...)"
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		SemantError( "FuncListValue.ToValue()" )
		
		Return Null
	End
	
	Method DistanceToType:Int( type:Type ) Override

		Local ftype:=Cast<FuncType>( type )
		If Not ftype Return -1
		
		Local func:=FindOverload( ftype.retType,ftype.argTypes )
		If func Return func.ftype.DistanceToType( ftype )
		
		Return -1
	End
	
	Method FindOverload:FuncValue( ret:Type,args:Type[] )
	
		Return overload.FindOverload( funcs,ret,args )
	End
	
End

'***** FuncList *****

Class FuncList Extends SNode

	Field ident:String
	Field scope:Scope
	Field funcs:=New Stack<FuncValue>
	Field instances:=New Stack<FuncListType>
	Field instance0:FuncListType
	
	Method New( ident:String,scope:Scope )
		Self.ident=ident
		Self.scope=scope
	End
	
	Method PushFunc( func:FuncValue )
	
		If instances.Length SemantError( "FuncList.PushFunc()" )
		
		funcs.Push( func )
	End
	
	Method FindFunc:FuncValue( argTypes:Type[] )
	
		For Local func:=Eachin funcs
			If TypesEqual( func.ftype.argTypes,argTypes ) Return func
		Next
		
		Return Null
	End
	
	Method OnSemant:SNode() Override
	
		If Not funcs.Length Return Self
	
		Local tfuncs:=funcs
		funcs=New Stack<FuncValue>
		
		For Local tfunc:=Eachin tfuncs
		
			Try
		
				Local func:=Cast<FuncValue>( tfunc.Semant() )
				If Not func Continue
			
				Local func2:=FindFunc( func.ftype.argTypes )
				If func2 Throw New SemantEx( "Duplicate declaration '"+func.ToString()+"'",tfunc.pnode )
				
				funcs.Push( func )

			Catch ex:SemantEx
			End
		Next
		
		Return Self
	End
	
	Method ToString:String() Override
	
		Return "{"+ident+"}"

		Return "{"+funcs[0].fdecl.ident+"}"
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		If Not instance0 instance0=New FuncListType( Self )
		
'		If funcs.Length=1 And Not funcs[0].IsGeneric Return funcs[0].ToValue( instance )
		
		Return New FuncListValue( instance0,instance )
	End
	
	Method GenFuncListType:FuncListType( types:Type[] )
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New FuncListType( Self,types )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End
	
End
