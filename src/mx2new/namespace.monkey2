
Namespace mx2

Class NamespaceType Extends Type

	Field ident:String
	Field scope:NamespaceScope
	
	Method New( ident:String,outer:NamespaceScope )
		Self.ident=ident
		Self.scope=New NamespaceScope( Self,outer )
	End
	
	Method ToString:String() Override
		Return ident
	End
	
	'***** Type overrides *****

	Method FindNode:SNode( ident:String ) Override
	
		Local node:=scope.GetNode( ident )
		If node Return node
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Override
	
		Local type:=scope.GetType( ident )
		If type Return type
		
		Return Null
	End
End

Class NamespaceScope Extends Scope

	Field ntype:NamespaceType
	
	Method New( ntype:NamespaceType,outer:NamespaceScope )
		Super.New( outer )
		
		Self.ntype=ntype
	End
	
	Method ToString:String() Override
	
		If Not ntype Return ""
	
		If outer
			Local str:=outer.ToString()
			If str Return str+"."+ntype.ident
		Endif
		
		Return ntype.ident
	End
	
	Method FindRoot:NamespaceScope()
	
		Local nmspace:=Cast<NamespaceScope>( outer )
		If nmspace And nmspace.ntype Return nmspace.FindRoot()
		
		Return Self
	End

End
