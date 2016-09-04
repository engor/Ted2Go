
Namespace mx2

Class AliasDecl Extends Decl

	Field genArgs:String[]
	Field type:Expr
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Local types:=New Type[genArgs.Length]
		For Local i:=0 Until types.Length
			types[i]=New GenArgType( i,genArgs[i],Null,Null )
		Next
		
		Return New AliasType( Self,scope,types,Null )
		
	End
End

Class AliasType Extends ProxyType

	Field adecl:AliasDecl
	Field scope:Scope
	Field types:Type[]
	Field instanceOf:AliasType
	
	Field instances:Stack<AliasType>
	
	Method New( adecl:AliasDecl,scope:Scope,types:Type[],instanceOf:AliasType )
		Self.adecl=adecl
		Self.scope=scope
		Self.types=types
		Self.instanceOf=instanceOf
		
		If AnyTypeGeneric( types ) flags|=TYPE_GENERIC
	End
	
	Property Name:String() Override

		Return adecl.ident+":"+_alias.Name
	End

	Method OnSemant:SNode() Override
	
'		If IsGeneric Return Self
		
		Local tscope:=scope
		If types
			tscope=New Scope( tscope )
			For Local i:=0 Until types.Length
				tscope.Insert( adecl.genArgs[i],types[i] )
			Next
		Endif
		
		_alias=adecl.type.SemantType( tscope )
		
		flags=_alias.flags
		
		Return Self
	End
	
	Method GenInstance:Type( types:Type[] ) Override

		If Not IsGeneric Return Super.GenInstance( types )

		If types.Length<>Self.types.Length Throw New SemantEx( "Wrong number of generic type parameters" )

		If Not instances instances=New Stack<AliasType>
	
		For Local inst:=Eachin instances
			If TypesEqual( inst.types,types ) Return inst
		Next
		
		Local inst:=New AliasType( adecl,scope,types,Self )
		instances.Push( inst )
		
		inst.Semant()
		
		Return inst
	End

End
