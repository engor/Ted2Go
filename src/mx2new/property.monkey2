
Namespace mx2

Class PropertyDecl Extends Decl

	Field getFunc:FuncDecl
	Field setFunc:FuncDecl
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Return New PropertyList( Self,scope )
	End

End

Class PropertyList Extends FuncList
	
	Field pdecl:PropertyDecl
	Field scope:Scope
	
	Field getFunc:FuncValue
	Field setFunc:FuncValue
	
	Field type:Type
	
	Method New( pdecl:PropertyDecl,scope:Scope )
		Super.New( pdecl.ident,scope )
		Self.pnode=pdecl
		Self.pdecl=pdecl
		Self.scope=scope
	End
	
	Method ToString:String() Override
	
		Return pdecl.ident
	End
	
	Method OnSemant:SNode() Override
	
		type=Type.VoidType
		
		If pdecl.getFunc
			Try
				getFunc=New FuncValue( pdecl.getFunc,scope,Null,Null )
				getFunc.Semant()
				type=getFunc.ftype.retType
				PushFunc( getFunc )
			Catch ex:SemantEx
			End
		Endif

		If pdecl.setFunc
			Try
				setFunc=New FuncValue( pdecl.setFunc,scope,Null,null )
				setFunc.Semant()
				PushFunc( setFunc )
			Catch ex:SemantEx
			End
		Endif
		
		Return Self
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		If instance Return New PropertyValue( Self,instance )
		
		Return Null
	End
	
End

Class PropertyValue Extends Value

	Field plist:PropertyList
	Field instance:Value
	
	Method New( plist:PropertyList,instance:Value )
		Self.type=plist.type
		Self.plist=plist
		Self.instance=instance
		
		If plist.setFunc flags|=VALUE_ASSIGNABLE
	End
	
	Method ToString:String() Override

		Return "PropertyValue "+plist.pdecl.ident
	End

	Method ToRValue:Value() Override
	
		If Not plist.getFunc Throw New SemantEx( "Property '"+ToString()+"' is write only" )

		Return plist.getFunc.ToValue( instance ).Invoke( Null )
	End
	
	#rem
	Method UpCast:Value( type:Type ) Override
	
		Return ToRValue().UpCast( type )
	End
	#end
	
	Method Assign:Stmt( op:String,rvalue:Value,block:Block ) Override
	
		Local inst:=instance
		
		If op<>"="
		
			If Not plist.getFunc Throw New SemantEx( "Property '"+ToString()+"' is write only" )
			
			inst=inst.RemoveSideEffects( block )
			
			Local value:=plist.getFunc.ToValue( inst ).Invoke( Null )
			
			Local op2:=op.Slice( 0,-1 )	'strip '='
			Local node:=value.FindValue( op2 )
			If node
				op=op2
				Local args:=New Value[1]
				args[0]=rvalue
				rvalue=node.Invoke( args )
			Else
				ValidateAssignOp( op,value.type )
				Local rtype:=value.type
				If op2="shl" Or op2="shr" rtype=Type.IntType
				rvalue=New BinaryopValue( value.type,op2,value,rvalue.UpCast( rtype ) )
'				rvalue=New BinaryopValue( value.type,op,value,rvalue.UpCast( type ) )
			Endif
		
		Endif
		
		Local args:=New Value[1]
		args[0]=rvalue
		Local invoke:=plist.setFunc.ToValue( inst ).Invoke( args )
		
		Return New EvalStmt( invoke )
	End

	'should never be called?
	Property HasSideEffects:Bool() Override

		Return instance.HasSideEffects
	End
	
	Method RemoveSideEffects:Value( block:Block ) Override
	
		Local value:=instance.RemoveSideEffects( block )
		If value=instance Return Self
		
		Return New PropertyValue( plist,value )
	End
	
End

