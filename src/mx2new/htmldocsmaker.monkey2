
Namespace mx2.docs

Const PAGES_DIR:="docs/__PAGES__/"

Class HtmlDocsMaker Extends DocsMaker

	Method MakeDocs:String( module:Module )
	
		_module=module
		_buf.Clear()
		_indent=""
		_sep=False
		
		_pagesDir=_module.baseDir+PAGES_DIR
		_pageTemplate=stringio.LoadString( "docs/modules_page_template.html" )

		DeleteDir( _pagesDir,True )
		CreateDir( _pagesDir,True )
		
		EmitModule()
		
		Local tree:=_buf.Join( "~n" )
		
		stringio.SaveString( tree,_pagesDir+"index.js" )

		Return tree
	End
	
	Method EmitModule()
	
		Local nmspaces:=New StringMap<NamespaceScope>
		
		For Local fscope:=Eachin _module.fileScopes
		
			Local nmspace:=Cast<NamespaceScope>( fscope.outer )
			If Not nmspace Continue
			
			nmspaces[nmspace.ntype.ident]=nmspace
		Next
		
		BeginNode( "<"+_module.name+">" )
		
		For Local nmspace:=Eachin nmspaces.Values
		
			EmitNamespace( nmspace )
			
		Next
		
		EndNode()
	End
	
	Private
	
	Field _buf:=New StringStack
	Field _indent:String
	Field _sep:Bool
	
	Field _posStack:=New IntStack
	
	Method EmitTree( str:String )
	
		If str.StartsWith( "}" ) Or str.StartsWith( "]" )
		
			_indent=_indent.Slice( 0,-2 )
			_sep=False
			
		Endif
	
		If _sep str=","+str
		_sep=True
		
		_buf.Push( _indent+str )
	
		If str.EndsWith( "{" ) Or str.EndsWith( "[" ) 
			_indent+="  "
			_sep=False
		Endif
	
	End
	
	Method BeginNode( name:String,page:String="" )
		If page page=",page:'"+page+"'"
		Local module:=",module:'"+_module.name+"'"
		_posStack.Push( _sep )
		_posStack.Push( _buf.Length )
		EmitTree( "{ name:'"+name+"'"+module+page+",children:[" )
	End
	
	Method EndNode( force:Bool=False )
		EmitTree( "] }" )
		Local pos:=_posStack.Pop()
		Local sep:=_posStack.Pop()
		If force Or _buf.Length-pos>2 Return
		_buf.Resize( pos )
		_sep=sep
	End
	
	Method EmitLeaf( name:String,page:String="" )
		If page page=",page:'"+page+"'"
		Local module:=",module:'"+_module.name+"'"
		EmitTree( "{ name:'"+name+"'"+module+page+",children:[] }" )
	End
	
	Method EmitLeaf( decl:Decl,page:String="" )

		EmitLeaf( DeclIdent( decl,False ),page )
	End
	
	Method EmitNode( decl:Decl,scope:Scope,page:String="",force:Bool=False )
	
		EmitNode( DeclIdent( decl,False ),scope,page,force )
	End
	
	Method EmitNode( name:String,scope:Scope,page:String="",force:Bool=False )
	
		BeginNode( name,page )
	
'		BeginNode( "Namespaces" )
'		EmitNamespaces( scope )
'		EndNode()

		BeginNode( "Aliases" )
		EmitAliases( scope,"alias" )
		EndNode()
		
		BeginNode( "Enums" )
		EmitEnums( scope,"enum" )
		EndNode()
		
		BeginNode( "Structs" )
		EmitClasses( scope,"struct" )
		EndNode()		
		
		BeginNode( "Classes" )
		EmitClasses( scope,"class" )
		EndNode()
		
		BeginNode( "Interfaces" )
		EmitClasses( scope,"interface" )
		EndNode()
		
		BeginNode( "Constants" )
		EmitVars( scope,"const" )
		EndNode()

		BeginNode( "Globals" )
		EmitVars( scope,"global" )
		EndNode()
		
		BeginNode( "Fields" )
		EmitVars( scope,"field" )
		EndNode()

		BeginNode( "Contructors" )		
		EmitFuncs( scope,"constructor" )
		EndNode()
		
		BeginNode( "Properties" )
		EmitProperties( scope,"property" )
		EndNode()

		BeginNode( "Operators" )		
		EmitFuncs( scope,"operator" )
		EndNode()
		
		BeginNode( "Methods" )
		EmitFuncs( scope,"method" )
		EndNode()

		BeginNode( "Functions" )
		EmitFuncs( scope,"function" )
		EndNode()
		
		EndNode( force )
		
	End
	
	Method EmitNamespaces( scope:Scope )
	
		For Local node:=Eachin scope.nodes
		
			Local ntype:=Cast<NamespaceType>( node.Value )
			If Not ntype Continue
			
			EmitNode( ntype.Name,ntype.scope )
			
		Next
	End
	
	Method EmitNamespace( nmspace:NamespaceScope )

		Local docs:=MakeNamespaceDocs( nmspace )
		If Not docs Return
		
		Local page:=NamespacePage( nmspace )
		SavePage( docs,page )
		
		EmitNode( nmspace.ntype.Name,nmspace,page )
	End
	
	Method EmitVars( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local vvar:=Cast<VarValue>( node.Value )
			If Not vvar Or vvar.transFile.module<>_module Or vvar.vdecl.kind<>kind Continue
			
			Local docs:=MakeVarDocs( vvar )
			If Not docs Continue
			
			Local page:=DeclPage( vvar.vdecl,vvar.scope )
			SavePage( docs,page )
			
			EmitLeaf( vvar.vdecl,page )
			
		Next
	
	End
	
	Method EmitAliases( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If Not atype Or atype.adecl.kind<>kind Continue
			
			Local docs:=MakeAliasDocs( atype )
			If Not docs Continue
			
			Local page:=DeclPage( atype.adecl,atype.scope )
			SavePage( docs,page )
			
			EmitLeaf( atype.adecl,page )

		Next
	
	End
	
	Method EmitEnums( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local etype:=Cast<EnumType>( node.Value )
			If Not etype Or etype.edecl.kind<>kind Continue
			
			Local docs:=MakeEnumDocs( etype )
			If Not docs Continue
			
			Local page:=DeclPage( etype.edecl,etype.scope.outer )
			SavePage( docs,page )
			
			EmitLeaf( etype.edecl,page )
			
		Next
	
	End
	
	Method EmitClasses( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local ctype:=Cast<ClassType>( node.Value )
			If Not ctype Or ctype.transFile.module<>_module Or ctype.cdecl.kind<>kind Continue
			
			Local docs:=MakeClassDocs( ctype )
			If Not docs Continue

			Local page:=DeclPage( ctype.cdecl,ctype.scope.outer )
			SavePage( docs,page )
			
			EmitNode( ctype.cdecl,ctype.scope,page,True )
		Next
	
	End
	
	Method EmitProperties( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local plist:=Cast<PropertyList>( node.Value )
			If Not plist Or plist.pdecl.kind<>kind Continue
			
			Local docs:=MakePropertyDocs( plist )
			If Not docs Continue
			
			Local page:=DeclPage( plist.pdecl,plist.scope )
			SavePage( docs,page )
			
			EmitLeaf( plist.pdecl,page )

		Next
	
	End
	
	Method EmitFuncs( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local flist:=Cast<FuncList>( node.Value )
			If Not flist Continue
			
			Local docs:=MakeFuncDocs( flist,kind )
			If Not docs Continue
			
			Local page:=DeclPage( flist.funcs[0].fdecl,flist.funcs[0].scope )
			SavePage( docs,page )
			
			EmitLeaf( flist.funcs[0].fdecl,page )
			
		Next
	
	End
	
End
