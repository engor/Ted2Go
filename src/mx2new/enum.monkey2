
Namespace mx2

Class EnumDecl Extends Decl

	Field superType:TypeExpr

	Method ToNode:SNode( scope:Scope ) Override
	
		Return New EnumType( Self,scope )
	End
	
End

Class EnumType Extends Type

	Field edecl:EnumDecl
	Field scope:Scope
	
	Field superType:EnumType
	Field nextInit:Int
	
	Method New( edecl:EnumDecl,outer:Scope )
		Self.pnode=edecl
		Self.edecl=edecl
		Self.scope=New Scope( outer )
	End
	
	Method ToString:String() Override
		Return edecl.ident
	End
	
	Method OnSemant:SNode() Override
	
		If edecl.superType
			Try
				superType=Cast<EnumType>( edecl.superType.Semant( scope ) )
				
				If Not superType Or superType.edecl.kind<>"enum"
					Throw New SemantEx( "Cant find super type "+edecl.superType.ToString(),edecl )
				Endif
				
				nextInit=superType.nextInit
				
			Catch ex:ParseEx
			End
			
		Endif
	
'		Local escope:=scope
'		If edecl.IsExtern
'			escope=escope.FindFile()
'			If edecl.IsPublic escope=escope.outer
'		Endif
		
		For Local decl:=Eachin edecl.members
		
			Local vdecl:=Cast<VarDecl>( decl )
			
			If edecl.IsExtern
			
				Local value:=New LiteralValue( Self,vdecl.symbol )
				scope.Insert( decl.ident,value )
				
			Else
			
				If vdecl.init
					Try
						Local value:=Cast<LiteralValue>( vdecl.init.SemantRValue( scope ) )
						If Not value Throw New SemantEx( "Enum member '"+vdecl.ToString()+"' initalizer must be constant",vdecl )
						If value.type<>Type.IntType And value.type<>Self Throw New SemantEx( "Enum member '"+vdecl.ToString()+"' type error" )
						nextInit=Int( value.value )
					Catch ex:SemantEx
					End
				Endif
				
				Local value:=New LiteralValue( Self,String( nextInit  ) )
				scope.Insert( decl.ident,value )
				nextInit+=1
				
			Endif
		Next
		
		Return Self
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=scope.GetNode( ident )
		If node Return node
		
		If superType Return superType.FindNode( ident )
		
		Return Null
	End
	
	Method DistanceToType:Int( type:Type ) Override
	
		If type=Self Return 0
		
		If type=Type.BoolType Return MAX_DISTANCE
		
		Local ptype:=Cast<PrimType>( type )
		If ptype
			If ptype.IsIntegral Return MAX_DISTANCE
			Return -1
		Endif
	
		Local etype:=Cast<EnumType>( type )
		If Not etype Return -1
		
		Local dist:=0
		While etype
			If etype=Self Return dist
			etype=etype.superType
		Wend
		
		Return -1
	End

End

