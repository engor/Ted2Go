
Namespace mx2

Class NodeFinder

	Field ident:String
	Field findType:Bool
	Field node:SNode
	Field flist:FuncList
	
	Method New( ident:String,findType:Bool )
		Self.ident=ident
		Self.findType=findType
	End
	
	Property Found:SNode()
		Return node
	End
	
	Method Find( scope:Scope )
		If findType 
			Add( scope.GetType( ident ) )
		Else
			Add( scope.GetNode( ident ) )
		Endif
	End
	
	Method Add( node:SNode )
	
		If Not node Return
	
		If Not Self.node
			Self.node=node
			Return
		Endif
		
		Local flist:=Cast<FuncList>( node )
		
		If Self.flist
		
			If Not flist Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
			
			AddFuncs( flist,Self.flist )
			
		Else If flist
		
			Local src:=Cast<FuncList>( Self.node )
			If Not src Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
			
			Local dst:=New FuncList( ident,Null )
			
			AddFuncs( src,dst )
			AddFuncs( flist,dst )
			
			Self.flist=dst
			Self.node=dst
			
		Else

			Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
		
		End
	End

	Method AddFuncs( src:FuncList,dst:FuncList )
	
		For Local func:=Eachin src.funcs
			If dst.FindFunc( func.ftype.argTypes ) 
				Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
			Endif
			dst.funcs.Push( func )
		Next
	End
	
End
