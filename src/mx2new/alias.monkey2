
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
	
	Method OnSemant:SNode() Override
		Local node:=adecl.type.Semant( scope )
		If Not node Throw New SemantEx( "Can't find type '"+adecl.type.ToString()+"'" )
		Return node
	End

End
