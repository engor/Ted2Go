
Namespace mx2.docs

Const PAGES_DIR:="docs/__PAGES__/"

Class JsonBuffer

	Method Emit( json:String )
	
		If json.StartsWith( "}" ) Or json.StartsWith( "]" )

			_indent=_indent.Slice( 0,-2 )
			_sep=False
			
			If _blks.Pop()=_buf.Length
				_buf.Resize( _buf.Length-1 )
				If _buf.Length
					Local t:=_buf.Top
					If Not (t.EndsWith( "{" ) Or t.EndsWith( "[" )) _sep=True
				Endif
				Return
			Endif

		Endif
	
		If _sep json=","+json
		_buf.Push( _indent+json )
	
		If json.EndsWith( "{" ) Or json.EndsWith( "[" ) 

			_blks.Push( _buf.Length )

			_indent+="  "
			_sep=False

			Return
		Endif

		_sep=True
	
	End
	
	Method Flush:String()
		Local json:=_buf.Join( "~n" )
		_buf.Clear()
		Return json
	End
	
	Private

	Field _buf:=New StringStack
	Field _blks:=New IntStack
	Field _indent:String
	Field _sep:Bool

End

Class HtmlDocsMaker Extends DocsMaker

	Method MakeDocs:String( module:Module )
	
		_module=module
		
		_pagesDir=_module.baseDir+PAGES_DIR
		_pageTemplate=stringio.LoadString( "docs/modules_page_template.html" )
		
		DeleteDir( _pagesDir,True )
		CreateDir( _pagesDir,True )
		
		EmitModule()
		
		Local tree:=_js.Flush()
		
		stringio.SaveString( tree,_pagesDir+"index.js" )

		Return tree
	End
	
	Method EmitModule()
	
		Local nmspaces:=New StringMap<NamespaceScope>
		
		Local nmspaceDocs:=New StringMap<String>
		
		For Local fscope:=Eachin _module.fileScopes
		
			Local nmspace:=Cast<NamespaceScope>( fscope.outer )
			If Not nmspace Continue
			
			nmspaces[nmspace.Name]=nmspace
			
			nmspaceDocs[nmspace.Name]+=fscope.fdecl.docs
		Next

		Local page:=""
		
		#rem
		Local md:=stringio.LoadString( _module.baseDir+"/docs/module.md" )
		If md
			_scope=Null
			page="module"
			Emit( md )
			Local html:=Flush()
			SavePage( html,page )
		Endif
		#end
		
		BeginNode( _module.name,page )
		
		For Local nmspace:=Eachin nmspaces.Values
		
			EmitNamespace( nmspace,nmspaceDocs[nmspace.Name] )
			
		Next
		
		EndNode()
	End
	
	Private
	
	Field _js:=New JsonBuffer

	Field _namespaceDocs:=New StringMap<String>
	
	Method BeginNode( name:String,page:String="" )
	
		If page page=",data:{page:'"+_module.name+":"+page+"'}"
		
		_js.Emit( "{ text:'"+name+"'"+page+",children:[" )

	End
	
	Method EndNode()

		_js.Emit( "] }" )
	End
	
	Method EmitLeaf( name:String,page:String="" )
	
		If page page=",data:{page:'"+_module.name+":"+page+"'}"
		
		_js.Emit( "{ text:'"+name+"'"+page+",children:[] }" )
		
	End
	
	Method EmitLeaf( decl:Decl,page:String="" )

		EmitLeaf( decl.ident,page )

	End
	
	Method EmitNode( decl:Decl,scope:Scope,page:String="" )
	
		EmitNode( decl.ident,scope,page )

	End
	
	Method EmitNode( name:String,scope:Scope,page:String="" )
	
		BeginNode( name,page )
	
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
		
		EndNode()
		
	End
	
	Method EmitNamespace( nmspace:NamespaceScope,docs:String )

		_linkScope=nmspace
	
		_md.Emit( "_Module: &lt;"+_module.name+"&gt;_  " )
		_md.Emit( "_Namespace: "+nmspace.Name+"_" )
		
		EmitMembers( "alias",nmspace,True )
		EmitMembers( "enum",nmspace,True )
		EmitMembers( "struct",nmspace,True )
		EmitMembers( "class",nmspace,True )
		EmitMembers( "interface",nmspace,True )
		EmitMembers( "const",nmspace,True )
		EmitMembers( "global",nmspace,True )
		EmitMembers( "function",nmspace,True )
		
		_md.Emit( docs )

		docs=_md.Flush()
		
		Local page:=NamespacePath( nmspace )
		SavePage( docs,page )
		
		EmitNode( nmspace.ntype.Name,nmspace,page )
	End
	
	Method EmitVars( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local vvar:=Cast<VarValue>( node.Value )
			If Not vvar Or vvar.vdecl.kind<>kind Or DocsHidden( vvar.vdecl ) Continue
			
			If vvar.transFile.module<>_module Continue
			
			Local docs:=MakeVarDocs( vvar )

			Local page:=DeclPath( vvar.vdecl,vvar.scope )
			SavePage( docs,page )
			
			Print "save page:"+page
			
			EmitLeaf( vvar.vdecl,page )
			
		Next
	
	End
	
	Method EmitAliases( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If Not atype Or atype.adecl.kind<>kind Or DocsHidden( atype.adecl ) Continue

			Local docs:=MakeAliasDocs( atype )

			Local page:=DeclPath( atype.adecl,atype.scope )
			SavePage( docs,page )
			
			EmitLeaf( atype.adecl,page )

		Next
	
	End
	
	Method EmitEnums( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local etype:=Cast<EnumType>( node.Value )
			If Not etype Or etype.edecl.kind<>kind Or DocsHidden( etype.edecl ) Continue
			
			Local docs:=MakeEnumDocs( etype )

			Local page:=DeclPath( etype.edecl,etype.scope.outer )
			SavePage( docs,page )
			
			EmitLeaf( etype.edecl,page )
			
		Next
	
	End
	
	Method EmitClasses( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local ctype:=Cast<ClassType>( node.Value )
			If Not ctype Or ctype.cdecl.kind<>kind Or DocsHidden( ctype.cdecl ) Continue
			
			If ctype.transFile.module<>_module Continue
			
			Local docs:=MakeClassDocs( ctype )

			Local page:=DeclPath( ctype.cdecl,ctype.scope.outer )
			SavePage( docs,page )
			
			EmitNode( ctype.cdecl,ctype.scope,page )
		Next
	
	End
	
	Method EmitProperties( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local plist:=Cast<PropertyList>( node.Value )
			If Not plist Or plist.pdecl.kind<>kind Or DocsHidden( plist.pdecl ) Continue
			
			Local docs:=MakePropertyDocs( plist )
			
			Local page:=DeclPath( plist.pdecl,plist.scope )
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
			
			Local page:=DeclPath( flist.funcs[0].fdecl,flist.funcs[0].scope )
			SavePage( docs,page )
			
			EmitLeaf( flist.funcs[0].fdecl,page )
			
		Next
	
	End
	
End
