
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
	Field cscope:ClassScope
	
	Field block:Block
	Field ftype:FuncType
	
	Field overrides:FuncValue
	
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
		Self.cscope=Cast<ClassScope>( scope )
		
		If IsLambda captures=New Stack<VarValue>
	End
	
	Property GenArgsName:String()
		If Not types Return ""
		Local tys:=""
		For Local ty:=Eachin types
			tys+=","+ty.Name
		Next
		Return "<"+tys.Slice( 1 )+">"
	End
	
	Property Name:String()
	
'		Local name:=scope.Name+"."+fdecl.ident,ps:=""

		Local tys:=""
		For Local ty:=Eachin types
			tys+=","+ty.Name
		Next
		If tys tys="<"+tys.Slice( 1 )+">"

		Local name:=fdecl.ident,ps:=""
		For Local p:=Eachin params
			ps+=","+p.Name
		Next
		
		Return name+tys
'		Return name+":"+ftype.retType.Name+"("+ps.Slice( 1 )+")"
	End
	
	Property ParamNames:String()
		Local ps:=""
		For Local p:=Eachin params
			ps+=","+p.Name
		Next
		Return ps.Slice( 1 )
	End
	
	Property IsGeneric:Bool()
		If Not ftype SemantError( "FuncValue.IsGeneric()" )
		
		Return ftype.IsGeneric Or (types And Not instanceOf)	
	End
	
	Property IsCtor:Bool()
		Return fdecl.ident="new"
	End
	
	Property IsMethod:Bool()
		Return fdecl.kind="method" And fdecl.ident<>"new"
	End
	
	Property IsFunction:Bool()
		Return fdecl.kind="function"
	End
	
	Property IsExtension:Bool()
		Return (fdecl.kind="method" And types) Or fdecl.IsExtension
	End
	
	Property IsLambda:Bool()
		Return fdecl.kind="lambda"
	End
	
	Method ToString:String() Override
	
		Local args:=Join( types )
		If args args="<"+args+">"
		
		Return fdecl.ident+args+":"+ftype.retType.ToString()+"("+Join( ftype.argTypes )+")"
	End
	
	Method OnSemant:SNode() Override
	
		'Create top level func block
		'
		block=New FuncBlock( Self )
		
		'Checks for generic funcs
		'
		If types
			If fdecl.IsAbstract Or fdecl.IsVirtual Or fdecl.IsOverride Throw New SemantEx( "Generic methods cannot be virtual" )
			If IsCtor Throw New SemantEx( "Constructors cannot be generic" )	'TODO
		Endif

		'Semant func type
		'
		type=fdecl.type.Semant( block )
		ftype=TCast<FuncType>( type )
		
		'That's it for generic funcs
		'
		If block.IsGeneric 
			Return Self
		Endif
		
		'Sanity checks!
		'
		If IsCtor
		
			If cscope.ctype.cdecl.kind="struct"
			
				If ftype.argTypes.Length And ftype.argTypes[0].Equals( cscope.ctype )
					Local ok:=False
					For Local i:=1 Until ftype.argTypes.Length
						If pdecls[i].init Continue
						ok=True
						Exit
					Next
					If Not ok Throw New SemantEx( "Illegal struct constructor - 'copy constructors' are automatically generated and cannot be redefined" )
				Endif
			
			Endif
		
		Else If IsMethod
		
			Local ctype:=cscope.ctype
			
			If fdecl.IsOperator
				Local op:=fdecl.ident
				Select op
				Case "=","<>","<",">","<=",">="
					If ftype.retType<>Type.BoolType Throw New SemantEx( "Comparison operator '"+op+"' must return Bool" )
					If ftype.argTypes.Length<>1 Throw New SemantEx( "Comparison operator '"+op+"' must have 1 parameter" )
'					If Not ftype.argTypes[0].Equals( ctype ) Throw New SemantEx( "Comparison operator '"+op+"' parameter must be of type '"+ctype.ToString()+"'" )
				Case "<=>"
					Local ptype:=TCast<PrimType>( ftype.retType )
					If Not ptype Or Not ptype.IsNumeric Throw New SemantEx( "Comparison operator '<=>' must return a numeric type" )
					If ftype.argTypes.Length<>1 Throw New SemantEx( "Comparison operator '"+op+"' must have 1 parameter" )
'					If Not ftype.argTypes[0].Equals( ctype ) Throw New SemantEx( "Comparison operator '"+op+"' parameter must be of type '"+ctype.ToString()+"'" )
				End
			Endif
			
			If ctype.IsVirtual And (fdecl.IsVirtual Or fdecl.IsOverride)
				Throw New SemantEx( "Virtual class methods cannot be declared 'Virtual' or 'Override'" )
			Endif
			
			Local func2:=ctype.FindSuperFunc( fdecl.ident,ftype.argTypes )
			
			If func2
			
				If Not ctype.IsVirtual And Not fdecl.IsOverride
					Throw New SemantEx( "Method '"+ToString()+"' overrides a superclass method but is not declared 'Override'" )
				Endif

				If func2.fdecl.IsFinal
					Throw New SemantEx( "Method '"+ToString()+"' overrides a final method" )
				Endif
				
				If Not ctype.IsVirtual And Not func2.fdecl.IsVirtual And Not func2.fdecl.IsOverride And Not func2.fdecl.IsAbstract
					 Throw New SemantEx( "Method '"+ToString()+"' overrides a non-virtual superclass method" )
				Endif
					
				If Not ftype.retType.ExtendsType( func2.ftype.retType ) 
					Throw New SemantEx( "Method '"+ToString()+"' overrides a method with incompatible return type" )
				Endif
				
				overrides=func2

			Else
			
				If fdecl.IsOverride
					Throw New SemantEx( "Method '"+ToString()+"' is declared 'Override' but does not override any method" )
				Endif
				
			Endif
		Endif
		
		'Check 'where' if present
		'		
		If fdecl.whereExpr
			Local t:=fdecl.whereExpr.SemantWhere( block )
'			Print "Semanted where for "+Name+" -> "+Int(t)
			If Not t Return Null
		Endif
		
		If IsLambda
			used=True
			semanted=Self
			SemantStmts()
		Else If fdecl.IsExtern
			used=True
		Else If Not types
			Used()
		Endif
		
		Return Self
	End
	
	Method Used()
	
		If used Return
		used=True

		Builder.instance.semantStmts.Push( Self )
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		Local value:Value=Self
		
		If IsCtor
		
			If instance Throw New SemantEx( "'New' cannot be directly invoked" )
			
		Else If IsMethod
		
			If Not instance Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed without an instance" )
			
			If Not instance.type.ExtendsType( cscope.ctype )
				Throw New SemantEx( "Method '"+ToString()+"' cannot be accessed from an instance of a different class" )
			Endif
			
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
		
		If IsCtor Or IsMethod
	
			If IsExtension
	
				selfValue=New VarValue( "capture","self",New LiteralValue( cscope.ctype,"" ),scope )
				
			Else
			
				selfValue=New SelfValue( cscope.ctype )
				
			Endif
			
		Else If IsLambda
		
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
	
		If block.IsGeneric SemantError( "FuncValue.SemantStmts(1)" )
	
		Try
		
			SemantParams()
			
		Catch ex:SemantEx
		
		End
		
		If Not fdecl.IsAbstract
			
			block.Semant( fdecl.stmts )
			
			If block.reachable And ftype.retType<>Type.VoidType Throw New SemantEx( "Missing return statement" )

			SemantInvokeNew()

		Endif
		
		If fdecl.kind="function" Or IsExtension
		
			transFile.functions.Push( Self )
			
			If fdecl.ident="Main" And TCast<VoidType>( ftype.retType ) And Not ftype.argTypes
				Local module:=scope.FindFile().fdecl.module
				If module.main Throw New SemantEx( "Duplicate declaration of 'Main'" )
				module.main=Self
			Endif
			
			If instanceOf
				Local builder:=Builder.instance
				Local module:=builder.semantingModule
				module.genInstances.Push( Self )
			Endif

		Else
		
			If IsCtor Or IsMethod
			
'				If fdecl.ident="new"
'					cscope.ctype.ctors.Push( Self )
'				Else
					cscope.ctype.methods.Push( Self )
'				Endif
			Endif
		
			scope.transMembers.Push( Self )

		Endif
	End
	
	Method TryGenInstance:FuncValue( types:Type[] )
	
'		If AnyTypeGeneric( types ) Print "TryGenInstance:"+fdecl.ident+"<"+Join( types )+">"

		If types.Length<>Self.types.Length Return Null
		
		If Not instances instances=New Stack<FuncValue>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return Cast<FuncValue>( inst.Semant() )
		Next
		
		Local inst:=New FuncValue( fdecl,scope,types,Self )
		instances.Push( inst )
		
		Return Cast<FuncValue>( inst.Semant() )
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

		Local args:=Join( flistType.types )
		If args args="<"+args+">"
		
		Return flistType.flist.ident+args+"(...)"
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
	
		Local ftype:=TCast<FuncType>( type )
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
	
	Property Name:String() Override
		Return "{FuncListType}"
	End
	
	Property TypeId:String() Override
		SemantError( "FuncListType.TypeId()" )
		Return ""
	End
	
	Method ToValue:Value( instance:Value ) Override
		SemantError( "FuncListType.ToValue()" )
		Return Null
	End
	
	Method DistanceToType:Int( type:Type ) Override

		Local ftype:=TCast<FuncType>( type )
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
	
		If AnyTypeGeneric( argTypes ) SemantError( "FuncList.FindFunc()" )
	
		For Local func:=Eachin funcs
			If func.block.IsGeneric Continue
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
				
				If Not func.block.IsGeneric
					Local func2:=FindFunc( func.ftype.argTypes )
					If func2 Throw New SemantEx( "Duplicate declaration '"+func.ToString()+"'",tfunc.pnode )
				Endif
				
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
