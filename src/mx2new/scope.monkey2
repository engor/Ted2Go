
Namespace mx2

Class Scope

	'nesting
	Field outer:Scope
	Field inner:=New Stack<Scope>
	
	'symbol table
	Field nodes:=New StringMap<SNode>
	
	'what translator needs to emit
	Field transMembers:=New Stack<SNode>
	
	Method New( outer:Scope )
		Self.outer=outer
		If outer outer.inner.Push( Self )
	End
	
	Property Name:String() Virtual
		If outer Return outer.Name
		Return ""
	End
	
	Property TypeId:String() Virtual
		If outer Return outer.Name
		Return ""
	End
	
	Method ToString:String() Virtual
		If outer Return outer.ToString()
		Return ""
	End
	
	'Is generic scope? ie: scope has access to generic types.
	'
	Property IsGeneric:Bool() Virtual
	
		If outer Return outer.IsGeneric
		
		Return False
	End
	
	Method Insert:Bool( ident:String,node:SNode )
	
		Try
	
			Local func:=Cast<FuncValue>( node )
			If func
			
				Local flist:=Cast<FuncList>( nodes[ident] )
				If Cast<PropertyList>( flist ) flist=Null
				
				If Not flist
					If nodes.Contains( ident ) Throw New SemantEx( "Duplicate identifier '"+ident+"'",node.pnode )
					flist=New FuncList( ident,Self )
					nodes[ident]=flist
				Endif
				
				flist.PushFunc( func )
				Return True
	
			Endif
		
			If nodes.Contains( ident ) Throw New SemantEx( "Duplicate identifier '"+ident+"'",node.pnode )
			
			nodes[ident]=node
			Return True
		
		Catch ex:SemantEx
		
		End
		
		Return False
	End
	
	Method GetNode:SNode( ident:String )
	
		Local node:=nodes[ident]
		If node Return node.Semant()
		
		Return Null
	End
	
	Method GetType:Type( ident:String )
	
		Local node:=nodes[ident]
		If Not Cast<Type>( node ) Return Null
		
		node=node.Semant()
		If node Return node.ToType()
		
		Return Null
	End
	
	Method FindNode:SNode( ident:String ) Virtual
	
		Local node:=GetNode( ident )
		If node Return node
		
		If outer Return outer.FindNode( ident )
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Virtual
	
		Local type:=GetType( ident )
		If type Return type
		
		If outer Return outer.FindType( ident )
		
		Return Null
	End
	
	Method FindValue:Value( ident:String ) Virtual
	
		Local node:=FindNode( ident )
		If node Return node.ToValue( Null )
		
		Return Null
	End
	
	Method FindFile:FileScope() Virtual
		If outer Return outer.FindFile()
		
		SemantError( "Scope.FindFile()" )
		Return Null
	End
	
	Method FindClass:ClassType() Virtual
		If outer Return outer.FindClass()
		
		Return Null
	End
	
End

Class FileScope Extends Scope

	Field fdecl:FileDecl
	
	Field nmspace:NamespaceScope
	
	Field usings:Stack<NamespaceScope>
	
	Field toSemant:=New Stack<SNode>
	
	Method New( fdecl:FileDecl )
		Super.New( Null )
		
		Local module:=fdecl.module

		Self.fdecl=fdecl
		Self.usings=module.usings
		
		Local builder:=Builder.instance
		
		nmspace=builder.GetNamespace( fdecl.nmspace )
		outer=nmspace
		nmspace.inner.Push( Self )
		
		For Local use:=Eachin fdecl.usings
			Local nmspace:=builder.GetNamespace( use )
			If usings.Contains( nmspace ) Continue
			usings.Push( nmspace )
		Next
		
		For Local member:=Eachin fdecl.members

			Local node:=member.ToNode( Self )
			
			If member.IsPublic
				If Not nmspace.Insert( member.ident,node ) Continue
			Else
				If Not Insert( member.ident,node ) Continue
			Endif

			toSemant.Push( node )
		Next
	End
	
	Method FindNode:SNode( ident:String ) Override
	
		Local node:=GetNode( ident )
		If node Return node
	
		Local flist:FuncList
	
		For Local scope:=Eachin usings
		
			Local node2:=scope.GetNode( ident )
			If Not node2 Continue
			
			If Not node
				node=node2
				Continue
			Endif
			
			Local flist2:=Cast<FuncList>( node2 )

			If flist2
			
				If Not flist
					Local flist2:=Cast<FuncList>( node )
					If flist2 flist=New FuncList( flist2.ident,Self )
				Endif
				
				If flist
					For Local func:=Eachin flist2.funcs
						If flist.FindFunc( func.ftype.argTypes ) 
							Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
						Endif
						flist.funcs.Push( func )
					Next
					Continue
				Endif
				
			Endif
			
			Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
		Next
		
		If flist Return flist
		
		If node Return node
		
		If outer Return outer.FindNode( ident )
		
		Return Null
	End
	
	Method FindType:Type( ident:String ) Override
	
		Local type:=GetType( ident )
		If type Return type
		
		For Local scope:=Eachin usings
		
			Local type2:=scope.GetType( ident )
			If Not type2 Continue
			
			If type Throw New SemantEx( "Duplicate identifier '"+ident+"'" )
			
			type=type2
		Next
		
		If type Return type
		
		If outer Return outer.FindType( ident )
		
		Return Null
	End
		
	Method FindFile:FileScope() Override

		Return Self
	End
	
	Method Semant()
	
		For Local node:=Eachin toSemant
			Try			
				node.Semant()
			Catch ex:SemantEx
			End
		Next
		
	End
	
End

Class Block Extends Scope

	Field func:FuncValue

	Field stmts:=New Stack<Stmt>
	
	Field reachable:Bool
	
	Field loop:Bool
	Field inex:Bool
	
	Method New( func:FuncValue )
		Super.New( func.scope )
		
		Self.func=func
	End
	
	Method New( outer:Block )
		Super.New( outer )
		
		func=outer.func
		loop=outer.loop
		inex=outer.inex
	End
	
	Property IsGeneric:Bool() Override

		If func.IsGeneric Return True

		Return Super.IsGeneric
	End

	Method FindValue:Value( ident:String ) Override

		Local node:=FindNode( ident )
		If Not node Return Null
		
		Local vvar:=Cast<VarValue>( node )
		If vvar
			Select vvar.vdecl.kind
			Case "local","param","capture"
				If Cast<Block>( vvar.scope ).func<>func
				
					If func.fdecl.kind<>"lambda" Return Null
					
'					Print "Capturing "+vvar.vdecl.ident
					
					vvar=New VarValue( "capture",vvar.vdecl.ident,vvar,func.block )
					func.block.Insert( vvar.vdecl.ident,vvar )
					func.captures.Push( vvar )
					node=vvar
					
				Endif
			End
		Endif
		
		Return node.ToValue( func.selfValue )
	End
	
	Method Emit( stmt:Stmt )
	
		If reachable stmts.Push( stmt )
	End
	
	Method Semant:Bool( stmts:StmtExpr[] )
	
		reachable=True

		For Local expr:=Eachin stmts
		
			Try
			
				Local stmt:=expr.Semant( Self )
				
				If stmt Emit( stmt )
				
			Catch ex:SemantEx
			End

		Next
		
		Local result:=reachable
		
		reachable=True
		
		Return result
	End
	
	Method AllocLocal:VarValue( init:Value )

		Local ident:=""+func.nextLocalId
		func.nextLocalId+=1

		Local varValue:=New VarValue( "local",ident,init,Self )
		
		stmts.Push( New VarDeclStmt( Null,varValue ) )

		Return varValue
	End

	Method AllocLocal:VarValue( ident:String,init:Value )

		Local varValue:=New VarValue( "local",ident,init,Self )
		
		stmts.Push( New VarDeclStmt( Null,varValue ) )

		Insert( ident,varValue )

		Return varValue
	End
	
End
