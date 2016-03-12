
Namespace mx2

#If __CONFIG__="mx2new"
#Import "<hoedown.monkey2>"
Using hoedown
#Else
Using lib.hoedown
#Endif

Class DocsMaker

	Method MakeDocs:String( module:Module )
	
		_module=module
		_buf.Clear()
		_indent=""
		_sep=False
		
		EmitModule()
		
		Return _buf.Join( "~n" )
	End

	Private
	
	Function FindSpc:Int( str:String )
	
		For Local i:=0 Until str.Length
			If str[i]<=32 Return i
		Next
		
		Return str.Length
	End
	
	Function FindChar:Int( str:String )
	
		For Local i:=0 Until str.Length
			If str[i]>32 Return i
		Next
		
		Return -1
	End
	
	Function JsonEscape:String( str:String )
		str=str.Replace( "\","\\" )
		str=str.Replace( "~q","\~q" )
		str=str.Replace( "~n","\n" )
		str=str.Replace( "~r","\r" )
		str=str.Replace( "~t","\t" )
		Return "~q"+str+"~q"
	End
	
	Function MarkdownToHtml:String( markdown:String )
	
		Return markdown
		
		#rem
		Local ob:=hoedown_buffer_new( 4096 )
		
		Local r:=hoedown_html_renderer_new( HOEDOWN_HTML_NONE,10 )
		
		Local doc:=hoedown_document_new( r,HOEDOWN_EXT_TABLES|HOEDOWN_EXT_FENCED_CODE,10 )
			
		hoedown_document_render( doc,ob,UByte Ptr(markdown.ToUtf8String()),markdown.Utf8Length )
'		hoedown_document_render( doc,ob,markdown,markdown.Utf8Length )
		
		Local html:=String.FromCString( hoedown_buffer_cstr( ob ) )
		
		hoedown_document_free( doc )
		
		hoedown_html_renderer_free( r )
		
		hoedown_buffer_free( ob )
		
		Return html
		#end
	End
	
	Function FixIdent:String( ident:String )
	
		If ident.StartsWith( "@" ) Return ident.Slice( 1 ).Capitalize()
		Return ident
	End
	
	Function ScopePath:String( scope:Scope )
	
		Local path:=""
		If scope.outer path=ScopePath( scope.outer )
		
		Local nmspace:=Cast<NamespaceScope>( scope )
		If Not nmspace Or Not nmspace.ntype Or Not nmspace.ntype.ident Return path
		
		If path Return path+"."+nmspace.ntype.ident
		
		Return nmspace.ntype.ident
	End
	
	Function DeclPath:String( node:SNode )
	
		Local etype:=Cast<EnumType>( node )
		If etype Return ScopePath( etype.scope.outer )+"."+FixIdent( etype.edecl.ident )
	
		Local ctype:=Cast<ClassType>( node )
		If ctype Return ScopePath( ctype.scope.outer )+"."+FixIdent( ctype.cdecl.ident )
		
		Local func:=Cast<FuncValue>( node )
		If func Return ScopePath( func.scope )+"."+FixIdent( func.fdecl.ident )
		
		Local vvar:=Cast<VarValue>( node )
		If vvar Return ScopePath( vvar.scope )+"."+FixIdent( vvar.vdecl.ident )
		
		Return "?????"
	End
	
	Function TypeName:String( type:Type )
	
		If type=Type.VoidType Return "Void"
		
		Local gtype:=Cast<GenArgType>( type )
		If gtype Return gtype.ident
		
		Local etype:=Cast<EnumType>( type )
		If etype Return DeclPath( etype )
		
		Local ptype:=Cast<PrimType>( type )
		If ptype Return TypeName( ptype.ctype )
		
		Local atype:=Cast<ArrayType>( type )
		If atype Return TypeName( atype.elemType )+"[,,,,,,,,,,".Slice( 0,atype.rank )+"]"
		
		Local ptrtype:=Cast<PointerType>( type )
		If ptrtype Return TypeName( ptrtype.elemType )+" Ptr"
		
		Local ctype:=Cast<ClassType>( type )
		If ctype
			Local name:=DeclPath( type )
			If Not ctype.types Return name
			Local args:=""
			For Local type:=Eachin ctype.types
				If args args+=","
				args+=TypeName( type )
			Next
			Return name+"<"+args+">"
		Endif
		
		Local ftype:=Cast<FuncType>( type )
		If ftype
			Local ret:=TypeName( ftype.retType )
			Local args:=""
			For Local type:=Eachin ftype.argTypes
				If args args+=","
				args+=TypeName( type )
			Next
			Return ret+"("+args+")"
		Endif
		
		Return "?????"
	End
	
	Field _module:Module
	Field _buf:=New StringStack
	Field _indent:String
	Field _sep:Bool
	
	Class Docs
	
		Field buf:=New StringStack
		Field params:=New StringMap<String>
		Field retrn:String
		
		Method Append( docs:String )
		
			Local lines:=docs.Split( "~n" )
			
			'unindent
			Local min:=10000
			For Local line:=Eachin lines
				If Not line.Trim() Continue
				Local i:=FindChar( line )
				If i<>-1 min=Min( min,i )
			Next
			
			For Local i:=0 Until lines.Length
			
				Local line:=lines[i].Slice( min )
				
				If line.StartsWith( "@" )
				
					Local i:=FindSpc( line )
					Local id:=line.Slice( 1,i )
					line=line.Slice( i ).Trim()
					
					If id="param"
	
						Local i:=FindSpc( line )
						Local id:=line.Slice( 0,i )
						line=line.Slice( i ).Trim()
						
						If Not id Or Not line Continue
						
						params[id]=line
						
						
					Else If id="return"
					
						retrn=line
						
					Endif
					
				Else
				
					If line.Trim() buf.Push( line ) Else buf.Push( "" )
					
				Endif
				
			Next
			
		End
		
		Method Join:String()
			While Not buf.Empty And Not buf.Top
				buf.Pop()
			Wend
			Return buf.Join( "~n" )
		End
	
	End
	
	Method Emit( str:String )
	
		If str="}" Or str="]" 
		
			_indent=_indent.Slice( 0,-2 )
			_sep=False
	
			If _buf.Length
				Local top:=_buf.Top
				If top.EndsWith( "{" ) Or top.EndsWith( "[" )
					_sep=top.Trim().StartsWith( "," )
					_buf.Pop()
					Return
				Endif
			Endif
		Endif
	
		If _sep str=","+str
		_sep=True
		
		_buf.Push( _indent+str )
	
		If str.EndsWith( "{" ) Or str.EndsWith( "[" ) 
			_indent+="  "
			_sep=False
		Endif
	
	End
	
	Method EmitString( key:String,value:String )
		Emit( "~q"+key+"~q:"+JsonEscape( value ) )
	End
	
	Method EmitIdent( ident:String )
		Emit( "~qident~q:~q"+FixIdent( ident )+"~q" )
	End
	
	Method EmitIdent( decl:Decl )
		EmitIdent( decl.ident )
	End
	
	Method EmitDocs( docs:String )
		If docs EmitString( "docs",MarkdownToHtml( docs ) )
	End
	
	Method EmitDocs( decl:Decl )
		If Not decl.docs Return
		
		Local docs:=New Docs
		docs.Append( decl.docs )
		
		EmitDocs( docs.Join() )
	End
	
	Method EmitFlags( decl:Decl )
		Emit( "~qflags~q:"+decl.flags )
	End
	
	Method EmitType( type:Type )
		EmitString( "type",TypeName( type ) )
	End
	
	Method EmitGenArgs( genArgs:String[] )
		If genArgs EmitString( "genArgs",",".Join( genArgs ) )
	End
	
	Method EmitScope( scope:Scope )
	
		Emit( "~qnamespaces~q:[" )
		EmitNamespaces( scope )
		Emit( "]" )
		
		Emit( "~qaliases~q:[" )
		EmitAliases( scope,"alias" )
		Emit( "]" )
		
		Emit( "~qenums~q:[" )
		EmitEnums( scope,"enum" )
		Emit( "]" )
		
		Emit( "~qclasses~q:[" )
		EmitClasses( scope,"class" )
		Emit( "]" )
		
		Emit( "~qconstants~q:[" )
		EmitVars( scope,"const" )
		Emit( "]" )
		
		Emit( "~qglobals~q:[" )
		EmitVars( scope,"global" )
		Emit( "]" )
		
		Emit( "~qfields~q:[" )
		EmitVars( scope,"field" )
		Emit( "]" )
		
		Emit( "~qconstructors~q:[" )
		EmitFuncs( scope,"method",True,False )
		Emit( "]" )
		
		Emit( "~qproperties~q:[" )
		EmitProperties( scope,"property" )
		Emit( "]" )
		
		Emit( "~qoperators~q:[" )
		EmitFuncs( scope,"method",False,True )
		Emit( "]" )
		
		Emit( "~qmethods~q:[" )
		EmitFuncs( scope,"method" )
		Emit( "]" )
		
		Emit( "~qfunctions~q:[" )
		EmitFuncs( scope,"function" )
		Emit( "]" )
		
	End
	
	Method EmitModule()
	
		Local nmspaces:=New StringMap<NamespaceScope>
		
		For Local fscope:=Eachin _module.fileScopes
		
			Local nmspace:=Cast<NamespaceScope>( fscope.outer )
			If Not nmspace Continue
			
			nmspaces[nmspace.FindRoot().ntype.ident]=nmspace
		Next
		
		Emit( "{" )
		
		Emit( "~qmodule~q:{" )
		
		Emit( "~qname~q:~q"+_module.name+"~q" )
		
		Emit( "~qnamespaces~q:[" )
		For Local nmspace:=Eachin nmspaces.Values
				
			Emit( "{" )
			
			EmitIdent( nmspace.ntype.ident )
			
			EmitScope( nmspace )
			
			Emit( "}" )
		Next
		Emit( "]" )
		
		Emit( "}" )
		
		Emit( "}" )
	End
	
	Method EmitNamespaces( scope:Scope )
	
		For Local node:=Eachin scope.nodes
		
			Local ntype:=Cast<NamespaceType>( node.Value )
			If Not ntype Continue
			
			Emit( "{" )
			
			EmitIdent( ntype.ident )
			
			EmitScope( ntype.scope )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitVars( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local vvar:=Cast<VarValue>( node.Value )
			If Not vvar Or vvar.transFile.module<>_module Or vvar.vdecl.kind<>kind Continue
			
			Local decl:=vvar.vdecl
			
			Emit( "{" )
			
			EmitIdent( decl )
			EmitDocs( decl )
			EmitFlags( decl )
			EmitType( vvar.type )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitEnums( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local etype:=Cast<EnumType>( node.Value )
			If Not etype Or etype.edecl.kind<>kind Continue
			
			Local decl:=etype.edecl
			
			Emit( "{" )
			
			EmitIdent( decl )
			EmitDocs( decl )
			EmitFlags( decl )
			
			EmitScope( etype.scope )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitClasses( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
	
			Local ctype:=Cast<ClassType>( node.Value )
			If Not ctype Or ctype.transFile.module<>_module Or ctype.cdecl.kind<>kind Continue
	
			Local decl:=ctype.cdecl
					
			Emit( "{" )
			
			EmitIdent( decl )
			EmitDocs( decl )
			EmitFlags( decl )
			EmitGenArgs( decl.genArgs )
			If ctype.superType EmitString( "superType",TypeName( ctype.superType ) )
			If ctype.ifaceTypes
				Local str:=""
				For Local iface:=Eachin ctype.ifaceTypes
					If str str+=","
					str+=JsonEscape( TypeName( iface ) )
				Next
				Emit( "~qifaceTypes~q:["+str+"]" )
			Endif
			
			EmitScope( ctype.scope )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitProperties( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local plist:=Cast<PropertyList>( node.Value )
			If Not plist Or plist.pdecl.kind<>kind Continue
			
			Local decl:=plist.pdecl
			
			Emit( "{" )
			
			EmitIdent( decl )
			EmitDocs( decl )
			EmitFlags( decl )
			EmitType( plist.type )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitAliases( scope:Scope,kind:String )
	
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If Not atype Or atype.scope.FindFile().fdecl.module<>_module Or atype.adecl.kind<>kind Continue
	
			Local decl:=atype.adecl
					
			Emit( "{" )
			
			EmitIdent( decl )
			EmitDocs( decl )
			EmitFlags( decl )
			EmitType( Cast<Type>( atype.semanted ) )
			
			Emit( "}" )
		Next
	
	End
	
	Method EmitFuncs( scope:Scope,kind:String,ctor:Bool=False,optor:Bool=False )
	
		For Local node:=Eachin scope.nodes
		
			Local flist:=Cast<FuncList>( node.Value )
			If Not flist Continue
			
			If kind="method" And ctor And flist.ident<>"new" Continue
			If kind="method" And Not ctor And flist.ident="new" Continue
			
			Local docs:Docs
			For Local func:=Eachin flist.funcs
				If func.fdecl.kind<>kind Continue
				If optor And Not func.fdecl.IsOperator Continue
				
				If Not docs docs=New Docs
				
				docs.Append( func.fdecl.docs )
			Next
			If Not docs Return
	
			Emit( "{" )
			
			EmitIdent( flist.ident )
			EmitDocs( docs.Join() )
	
			Emit( "~qoverloads~q:[" )
			For Local func:=Eachin flist.funcs
				If func.fdecl.kind<>kind Continue
				If optor And Not func.fdecl.IsOperator Continue
				
				Emit( "{" )
				
				If func.ftype.retType<>Type.VoidType Or docs.retrn
				
					Emit( "~qreturn~q:{" )
					
					EmitType( func.ftype.retType )
					
					EmitDocs( docs.retrn )
					
					Emit( "}" )
					
				Endif
				
				Emit( "~qparams~q:[" )
				For Local p:=Eachin func.params
				
					Local decl:=p.vdecl
				
					Emit( "{" )
					
					EmitIdent( decl )
					
					If docs.params.Contains( p.vdecl.ident ) EmitDocs( docs.params[decl.ident] )
					
					EmitFlags( decl )
					
					EmitType( p.type )
						
					If p.init EmitString( "default",p.init.ToString() )
						
					Emit( "}" )
					
				Next
				Emit( "]" )
				
				Emit( "}" )
			Next
			Emit( "]" )
			
			Emit( "}" )
		Next
	
	End

End
