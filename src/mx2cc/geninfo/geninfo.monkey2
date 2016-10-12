
Namespace mx2.geninfo

Class ParseInfoGenerator

	Method GenParseInfo:JsonValue( fdecl:FileDecl )
	
		Local node:=GenNode( fdecl )
		
		Return node
	End
	
	Private
	
	'Generic...
	'
	Method GenNode<T>:JsonArray( args:T[] )
	
		Local arr:=New JsonArray
		For Local arg:=Eachin args
			arr.Push( GenNode( arg ) )
		Next
		Return arr
	End
	
	Method GenNode:JsonArray( args:String[] )

		Local arr:=New JsonArray
		For Local arg:=Eachin args
			arr.Push( New JsonString( arg ) )
		Next
		Return arr
	End
	
	'Decls...
	'
	Method MakeNode:JsonObject( decl:Decl )
	
		Local node:=New JsonObject

		node.SetString( "srcpos",(decl.srcpos Shr 12)+":"+(decl.srcpos & $fff) )
		node.SetString( "endpos",(decl.endpos Shr 12)+":"+(decl.endpos & $fff) )
		node.SetString( "kind",decl.kind )
		node.SetString( "ident",decl.ident )
		node.SetNumber( "flags",decl.flags )
		
		If decl.members node.SetValue( "members",GenNode( decl.members ) )
		
		Return node
	End
	
	Method GenNode:JsonObject( decl:Decl )
	
		Local classDecl:=Cast<ClassDecl>( decl )
		If classDecl Return GenNode( classDecl )
		
		Local funcDecl:=Cast<FuncDecl>( decl )
		If funcDecl Return GenNode( funcDecl )
		
		Local aliasDecl:=Cast<AliasDecl>( decl )
		If aliasDecl Return GenNode( aliasDecl )
		
		Local varDecl:=Cast<VarDecl>( decl )
		If varDecl Return GenNode( varDecl )
		
		Local propertyDecl:=Cast<PropertyDecl>( decl )
		If propertyDecl Return GenNode( propertyDecl )
		
		Return MakeNode( decl )
	End
	
	Method GenNode:JsonObject( decl:ClassDecl )
	
		Local node:=MakeNode( decl )
		
		If decl.genArgs node.SetValue( "genArgs",GenNode( decl.genArgs ) )
		
		If decl.superType node.SetValue( "superType",GenNode( decl.superType ) )
		
		If decl.ifaceTypes node.SetValue( "ifaceTypes",GenNode( decl.ifaceTypes ) )
		
		Return node
	End

	Method GenNode:JsonObject( decl:FuncDecl )

		Local node:=MakeNode( decl )
		
		If decl.genArgs node.SetValue( "genArgs",GenNode( decl.genArgs ) )
		
		If decl.type node.SetValue( "type",GenNode( decl.type ) )
		
		If decl.whereExpr node.SetValue( "where",GenNode( decl.whereExpr ) )
		
		Return node
	End
	
	Method GenNode:JsonObject( decl:AliasDecl )

		Local node:=MakeNode( decl )
		
		If decl.genArgs node.SetValue( "genArgs",GenNode( decl.genArgs ) )
		
		If decl.type node.SetValue( "type",GenNode( decl.type ) )
		
		Return node
	End
	
	Method GenNode:JsonObject( decl:VarDecl )
	
		Local node:=MakeNode( decl )
		
		If decl.type node.SetValue( "type",GenNode( decl.type ) )
		
		If decl.init node.SetValue( "init",GenNode( decl.init ) )
		
		Return node
	End
	
	Method GenNode:JsonObject( decl:PropertyDecl )
	
		Local node:=MakeNode( decl )
		
		If decl.getFunc node.SetValue( "getFunc",GenNode( decl.getFunc ) )
		
		If decl.setFunc node.SetValue( "setFunc",GenNode( decl.setFunc ) )
		
		Return node
	
	End
	
	'Expressions...
	'
	Method MakeNode:JsonObject( expr:Expr,kind:String )
	
		Local node:=New JsonObject

		node.SetString( "srcpos",(expr.srcpos Shr 12)+":"+(expr.srcpos & $fff) )
		node.SetString( "endpos",(expr.endpos Shr 12)+":"+(expr.endpos & $fff) )
		node.SetString( "kind",kind )
		
		Return node
	End
	
	Method GenNode:JsonObject( expr:Expr )
	
		Local identExpr:=Cast<IdentExpr>( expr )
		If identExpr Return GenNode( identExpr )
		
		Local memberExpr:=Cast<MemberExpr>( expr )
		If memberExpr Return GenNode( memberExpr )
		
		Local genericExpr:=Cast<GenericExpr>( expr )
		If genericExpr Return GenNode( genericExpr )
		
		Local literalExpr:=Cast<LiteralExpr>( expr )
		If literalExpr Return GenNode( literalExpr )

		Local newObjectExpr:=Cast<NewObjectExpr>( expr )
		If newObjectExpr Return GenNode( newObjectExpr )

		Local newArrayExpr:=Cast<NewArrayExpr>( expr )
		If newArrayExpr Return GenNode( newArrayExpr )
				
		Local funcTypeExpr:=Cast<FuncTypeExpr>( expr )
		If funcTypeExpr Return GenNode( funcTypeExpr )
		
		Local arrayTypeExpr:=Cast<ArrayTypeExpr>( expr )
		If arrayTypeExpr Return GenNode( arrayTypeExpr )
		
		Local pointerTypeExpr:=Cast<PointerTypeExpr>( expr )
		If pointerTypeExpr Return GenNode( pointerTypeExpr )
		
		Return MakeNode( expr,"????Expr?????" )
	End
	
	Method GenNode:JsonObject( expr:IdentExpr )
	
		Local node:=MakeNode( expr,"ident" )
		
		node.SetString( "ident",expr.ident )
		
		Return node
	End
	
	Method GenNode:JsonObject( expr:MemberExpr )
	
		Local node:=MakeNode( expr,"member" )
		
		node.SetValue( "expr",GenNode( expr.expr ) )
		
		node.SetString( "ident",expr.ident )
	
		Return node
	End
	
	Method GenNode:JsonObject( expr:GenericExpr )

		Local node:=MakeNode( expr,"generic" )
		
		node.SetValue( "expr",GenNode( expr.expr ) )
		
		node.SetValue( "args",GenNode( expr.args ) )
		
		Return node
	End
	
	Method GenNode:JsonObject( expr:LiteralExpr )
	
		Local node:=MakeNode( expr,"literal" )
		
		node.SetString( "toke",expr.toke )
		
		Return node
	End
	
	Method GenNode:JsonObject( expr:NewObjectExpr )
	
		Local node:=MakeNode( expr,"newobject" )
		
		node.SetValue( "type",GenNode( expr.type ) )
		
		node.SetValue( "args",GenNode( expr.args ) )
		
		Return node
	End
		
	Method GenNode:JsonObject( expr:NewArrayExpr )
	
		Local node:=MakeNode( expr,"newarray" )
		
		node.SetValue( "type",GenNode( expr.type ) )
		
		If expr.sizes node.SetValue( "sizes",GenNode( expr.sizes ) )

		If expr.inits node.SetValue( "inits",GenNode( expr.inits ) )
		
		Return node
	End
		
	Method GenNode:JsonObject( expr:FuncTypeExpr )

		Local node:=MakeNode( expr,"functype" )
		
		node.SetValue( "retType",GenNode( expr.retType ) )
		
		node.SetValue( "params",GenNode( expr.params ) )
		
		Return node
	End

	Method GenNode:JsonObject( expr:ArrayTypeExpr )
	
		Local node:=MakeNode( expr,"arraytype" )
		
		node.SetValue( "type",GenNode( expr.type ) )
		
		node.SetNumber( "rank",expr.rank )
		
		Return node
	End
	
	Method GenNode:JsonObject( expr:PointerTypeExpr )
	
		Local node:=MakeNode( expr,"pointertype" )
		
		node.SetValue( "type",GenNode( expr.type ) )
		
		Return node
	End

End
