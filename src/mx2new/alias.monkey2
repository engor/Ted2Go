
Namespace mx2

Class AliasDecl Extends Decl

	Field type:TypeExpr
	
	Method ToNode:SNode( scope:Scope ) Override
		Return New AliasType( Self,scope )
	End
End

Class AliasType Extends Type

	Field adecl:AliasDecl
	Field scope:Scope
	
	Method New( adecl:AliasDecl,scope:Scope )
		Self.pnode=adecl
		Self.adecl=adecl
		Self.scope=scope
	End
	
	Property Name:String() Override
		Return "{Alias}"
	End
	
	Property TypeId:String() Override
		SemantError( "AliasType.TypeId()" )
		Return ""
	End
	
	Method OnSemant:SNode() Override
		Local node:=adecl.type.Semant( scope )
		If Not node Throw New SemantEx( "Can't find type '"+adecl.type.ToString()+"'" )
		Return node
	End

End
