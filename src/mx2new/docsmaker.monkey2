
Namespace mx2.docs

Class MarkdownBuffer

	Alias LinkResolver:String( link:String )

	Method New( linkResolver:LinkResolver=Null )
		_linkResolver=linkResolver
	End

	Method Emit( markdown:String )
	
		If Not markdown.Contains( "~n" )
			_buf.Push( ReplaceLinks( markdown ) )
			Return
		Endif
		
		Local lines:=markdown.Split( "~n" )
		
		For Local i:=0 Until lines.Length
		
			Local line:=lines[i].Trim()
			
			If line.StartsWith( "@" )

				Local j:=FindSpc( line )
				Local id:=line.Slice( 1,j )
				line=line.Slice( j ).Trim()
				
				Select id
				Case "param"
				
					_params.Push( line )
					
				Case "return"
				
					_return=line
					
				Case "example"
				
					Local indent:=FindChar( lines[i] )
					i+=1
					
					_buf.Push( "```" )
					
					Local buf:=New StringStack
					
					While i<lines.Length
						Local line:=lines[i]
						If line.Trim().StartsWith( "@end" ) Exit
						i+=1
						line=line.Slice( indent )
						If line.StartsWith( "\#" ) line=line.Slice( 1 )
						buf.Push( line )
					Wend
					
					_buf.Push( buf.Join( "~n" ).Trim() )
					
					_buf.Push( "```" )
					
				Case "see"
				
					Continue
				
				Default
				
					Print "MarkdownBuffer: unrecognized '"+lines[i]+"'"
					
				End

				Continue
			Endif
			
			_buf.Push( ReplaceLinks( line ) )
			
		Next
	
	End
	
	Method EmitBr()
	
		_buf.Push( "" )
	End
	
	Method Flush:String()

		If _params.Length	
		
			EmitBr()
			Emit( "| Parameters |    |" )
			Emit( "|:-----------|:---|" )
			
			For Local p:=Eachin _params
			
				Local i:=FindSpc( p )
				Local id:=p.Slice( 0,i )
				p=p.Slice( i ).Trim()
				
				If Not id Or Not p Continue
				
				Emit( "| `"+id+"` | "+p+" |" )
			Next
			
			_params.Clear()
			
		Endif
		
		Local markdown:=_buf.Join( "~n" ).Trim()+"~n"
		
		_buf.Clear()
		
		Local docs:=hoedown.MarkdownToHtml( markdown )
		
		Return docs
	End
	
	Private
	
	Field _linkResolver:LinkResolver
	Field _buf:=New StringStack
	Field _params:=New StringStack
	Field _return:String
	
	Method FindSpc:Int( str:String )
		For Local i:=0 Until str.Length
			If str[i]<=32 Return i
		Next
		Return str.Length
	End

	Method FindChar:Int( str:String )
		For Local i:=0 Until str.Length
			If str[i]>32 Return i
		Next
		Return -1
	End
	
	Method ReplaceLinks:String( line:String )
	
		Repeat
			Local i0:=line.Find( "[[" )
			If i0=-1 Return line
			
			Local i1:=line.Find( "]]",i0+2 )
			If i1=-1 Return line
			
			Local path:=line.Slice( i0+2,i1 )
			Local link:=path
			
			If _linkResolver<>Null
				link=_linkResolver( path )
				If Not link
					Print "Makedocs error: Can't resolve link '"+path+"'"
					link=path
				Endif
			Endif
			
			line=line.Slice( 0,i0 )+link+line.Slice( i1+2 )
		Forever
		
		Return line
	End

End

Class DocsMaker

	Protected
	
	Field _module:Module
	
	Field _linkScope:Scope

	Field _pagesDir:String			'module/docs
	
	Field _pageTemplate:String
	
	Field _md:MarkdownBuffer
	
	Method New()
	
		_md=New MarkdownBuffer( Lambda:String( link:String )
			Return ResolveLink( link,_linkScope )
		End )
		
	End
	
	Method Esc:String( id:String )
		id=id.Replace( "_","\_" )
		id=id.Replace( "<","\<" )
		id=id.Replace( ">","\>" )
		Return id
	End	
	
	Method DeclPath:String( decl:Decl,scope:Scope )
	
		Local ident:=decl.ident.Replace( "@","" )
		If Not IsIdent( ident[0] ) ident=OpSym( ident )
		
		Local slug:=scope.Name+"."+ident
		
		Repeat
			Local i:=slug.Find( "<" )
			If i=-1 Exit
			Local i2:=slug.Find( ">",i+1 )
			If i2=-1 Exit
			slug=slug.Slice( 0,i )+slug.Slice( i2+1 )
		Forever
		
		Return slug
	End
	
	Method NamespacePath:String( nmspace:NamespaceScope )
	
		Return nmspace.Name
	End
	
	Method DeclSlug:String( decl:Decl,scope:Scope )

		Local module:=scope.FindFile().fdecl.module.name

		Local slug:=module+":"+DeclPath( decl,scope ).Replace( ".","-" )
		
		Return slug
	End
	
	Method NamespaceSlug:String( nmspace:NamespaceScope )
	
		Local slug:=_module.name+":"+NamespacePath( nmspace ).Replace( ".","-" )
		
		Return slug
	End
	
	Method MakeLink:String( text:String,decl:Decl,scope:Scope )
	
		Local slug:=DeclSlug( decl,scope )
		
		Return "<a href=~qjavascript:void('"+slug+"')~q onclick=~qdocsLinkClicked('"+slug+"')~q>"+text+"</a>"
	End
	
	Method MakeLink:String( text:String,nmspace:NamespaceScope )
	
		Local slug:=NamespaceSlug( nmspace )
		
		Return "<a href=~qjavascript:void('"+slug+"')~q onclick=~qdocsLinkClicked('"+slug+"')~q>"+text+"</a>"
	End

	Method ResolveLink:String( path:String,scope:Scope )
	
		Local i0:=0
		
		Local tpath:=""
		
		Repeat
		
			Local i1:=path.Find( ".",i0 )
			If i1=-1
			
				Local id:=path.Slice( i0 )

				Local node:=scope.FindNode( id )
				If Not node
					Return path
				Endif
				
				tpath+=id
				
				Local vvar:=Cast<VarValue>( node )
				If vvar Return MakeLink( tpath,vvar.vdecl,vvar.scope )
				
				Local flist:=Cast<FuncList>( node )
				If flist Return MakeLink( tpath,flist.funcs[0].fdecl,flist.funcs[0].scope )
				
				Local etype:=TCast<EnumType>( node )
				If etype Return MakeLink( tpath,etype.edecl,etype.scope.outer )
				
				Local ctype:=TCast<ClassType>( node )
				If ctype Return MakeLink( tpath,ctype.cdecl,ctype.scope.outer )
				
				Return ""
			Endif
			
			Local id:=path.Slice( i0,i1 )
			i0=i1+1
			
			Local type:Type
			If scope
				Try
					type=scope.FindType( id )
				Catch ex:SemantEx
					Print "Exception!"
				End
			Else If Not tpath
				For Local fscope:=Eachin _module.fileScopes
					If id<>fscope.nmspace.ntype.ident Continue
					type=fscope.nmspace.ntype
					Exit
				Next
			Endif

			If Not type 
				Return path
			Endif
			
			tpath+=id+"."
			
			Local ntype:=TCast<NamespaceType>( type )
			If ntype
				scope=ntype.scope
				Continue
			Endif
			
			Local etype:=TCast<EnumType>( type )
			If etype
				'stop at enum!
				Return MakeLink( tpath+"."+path.Slice( i0 ),etype.edecl,etype.scope.outer )
			Endif
			
			Local ctype:=TCast<ClassType>( type )
			If ctype
				scope=ctype.scope
				Continue
			Endif
			
			Return ""
			
		Forever
			
		Return ""
	End
	
	Method DeclIdent:String( decl:Decl,gen:Bool=False )

		Local ident:=decl.ident
		
		If decl.IsOperator
			ident="Operator "+ident
		Else If ident="new"
			ident="New"
		Else If ident.StartsWith( "@" )
			ident=ident.Slice( 1 ).Capitalize()
		Endif
		
		If gen
			Local adecl:=Cast<AliasDecl>( decl )
			If adecl And adecl.genArgs ident+="<"+(",".Join( adecl.genArgs ))+">"
			
			Local cdecl:=Cast<ClassDecl>( decl )
			If cdecl And cdecl.genArgs ident+="<"+(",".Join( cdecl.genArgs ))+">"
			
			Local fdecl:=Cast<FuncDecl>( decl )
			If fdecl And fdecl.genArgs ident+="<"+(",".Join( fdecl.genArgs ))+">"
		Endif
		
		Return Esc( ident )
	End
	
	Method DeclIdent:String( decl:Decl,scope:Scope,gen:Bool=False )

		Return MakeLink( DeclIdent( decl,gen ),decl,scope )
	End
	
	Method DeclName:String( decl:Decl,scope:Scope )
	
		Local path:=""
		Local nmspace:=scope.FindFile().nmspace
		
		While scope<>nmspace
			If Not scope Return "?????"
			Local cscope:=Cast<ClassScope>( scope )
			If cscope
				Local decl:=cscope.ctype.cdecl
				path=DeclIdent( decl,cscope.outer,True )+"."+path
			Endif
			scope=scope.outer
		Wend
		
		If path path=path.Slice( 0,-1 )+"."
		
		Return path+DeclIdent( decl )
	End
	
	Method DeclDesc:String( decl:Decl )
		Local desc:=decl.docs
		Local i:=desc.Find( "~n" )
		If i<>-1 desc=desc.Slice( 0,i )
'		desc=Esc( desc )
		Return desc
	End
	
	Method SavePage( docs:String,page:String )
		page=page.Replace( ".","-" )
		docs=_pageTemplate.Replace( "${CONTENT}",docs )
		
'		Print "Saving page:"+_pagesDir+page+".html"
		
		stringio.SaveString( docs,_pagesDir+page+".html" )
	End
	
	Method TypeName:String( type:Type,prefix:String )
	
		Local xtype:=Cast<AliasType>( type )
		If xtype
		
			If xtype.instanceOf xtype=xtype.instanceOf
			
			Return MakeLink( Esc( xtype.adecl.ident ),xtype.adecl,xtype.scope )
		Endif
	
		Local vtype:=TCast<VoidType>( type )
		If vtype
			Return vtype.Name
		Endif
	
		Local gtype:=TCast<GenArgType>( type )
		If gtype
			Return gtype.Name.Replace( "?","" )
		Endif
	
		Local ptype:=TCast<PrimType>( type )
		If ptype
			Local ctype:=ptype.ctype
			Return MakeLink( Esc( ptype.Name ),ctype.cdecl,ctype.scope.outer )
		Endif
		
		Local ntype:=TCast<NamespaceType>( type )
		If ntype
			Return Esc( ntype.Name )
		Endif
		
		Local ctype:=TCast<ClassType>( type )
		If ctype
			Local args:=""
			For Local type:=Eachin ctype.types
				args+=","+TypeName( type,prefix )
			Next
			If args args="\< "+args.Slice( 1 )+" \>"
			
			If ctype.instanceOf ctype=ctype.instanceOf
			
			Return MakeLink( Esc( ctype.cdecl.ident ),ctype.cdecl,ctype.scope.outer )+args
		Endif
		
		Local etype:=TCast<EnumType>( type )
		If etype
			Local name:=etype.Name
			If name.StartsWith( prefix ) name=name.Slice( prefix.Length )
			Return MakeLink( Esc( name ),etype.edecl,etype.scope.outer )
		Endif
		
		Local qtype:=TCast<PointerType>( type )
		If qtype
			Return TypeName( qtype.elemType,prefix )+" Ptr"
		Endif
		
		Local atype:=TCast<ArrayType>( type )
		If atype
			If atype.rank=1 Return TypeName( atype.elemType,prefix )+"\[ \]"
			Return TypeName( atype.elemType,prefix )+"\[ ,,,,,,,,,".Slice( 0,atype.rank+2 )+" \]"
		End
		
		Local ftype:=TCast<FuncType>( type )
		If ftype
			Local args:=""
			For Local arg:=Eachin ftype.argTypes
				args+=","+TypeName( arg,prefix )
			Next
			args=args.Slice( 1 )
			Return TypeName( ftype.retType,prefix )+"( "+args+" )"
		Endif
		
		Print type.Name+"!!!!!!"
		Assert( False )
		Return ""
	End
	
	Method TypeName:String( type:Type,scope:Scope )
		Local prefix:=scope.FindFile().nmspace.Name+"."
		Return TypeName( type,prefix )
	End
	
	Method EmitHeader( decl:Decl,scope:Scope )
		Local fscope:=scope.FindFile()
		Local nmspace:=fscope.nmspace
		Local module:=fscope.fdecl.module
		_md.Emit( "_Module: &lt;"+module.name+"&gt;_  " )
		_md.Emit( "_Namespace:_ _"+MakeLink( NamespacePath( nmspace ),nmspace )+"_" )
		_md.EmitBr()
		_md.Emit( "#### "+DeclName( decl,scope ) )
		_md.EmitBr()
	End
	
	Method DocsHidden:Bool( decl:Decl )
		Return (decl.IsPrivate And Not decl.docs) Or decl.docs.StartsWith( "@hidden" )
	End
	
	Method EmitMembers( kind:String,scope:Scope,inherited:Bool )
	
		Local init:=True
	
		For Local node:=Eachin scope.nodes
		
			Local atype:=Cast<AliasType>( node.Value )
			If atype
				If kind<>"alias" Continue
				Local decl:=atype.adecl
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>atype.scope) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| Aliases | &nbsp; |" )
					_md.Emit( "|:---|:---" )
				Endif
				
				_md.Emit( "| "+DeclIdent( decl,atype.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
				

			Local ctype:=Cast<ClassType>( node.Value )
			If ctype
				Local decl:=ctype.cdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>ctype.scope.outer) Continue
				
				If init
					init=False
					Local kinds:=kind.Capitalize() + (kind="class" ? "es" Else "s")
					_md.EmitBr()
					_md.Emit( "| "+kinds+" | |" )
					_md.Emit( "|:---|:---|" )
				Endif
				
				_md.Emit( "| "+DeclIdent( decl,ctype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
			
			Local etype:=Cast<EnumType>( node.Value )
			If etype
				If kind<>"enum" Continue
				Local decl:=etype.edecl
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>etype.scope.outer) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| Enums | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,etype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif

			Local vvar:=Cast<VarValue>( node.Value )
			If vvar
				Local decl:=vvar.vdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>vvar.scope) Continue

				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| "+kind.Capitalize()+"s | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,vvar.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
			
			Local plist:=Cast<PropertyList>( node.Value )
			If plist
				If kind<>"property" Continue
				Local decl:=plist.pdecl
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>plist.scope) Continue
				
				If init
					init=False
					_md.EmitBr()
					_md.Emit( "| Properties | |" )
					_md.Emit( "|:---|:---|" )
				Endif

				_md.Emit( "| "+DeclIdent( decl,plist.scope )+" | "+DeclDesc( decl )+" |" )
				Continue
			Endif
		
			Local flist:=Cast<FuncList>( node.Value )
			If flist
				If kind<>"constructor" And kind<>"operator" And kind<>"method" And kind<>"function" Continue

				For Local func:=Eachin flist.funcs
					Local decl:=func.fdecl
					If DocsHidden( decl ) Continue
					If inherited<>(scope<>func.scope) Continue
					
					If kind="constructor" 
						If decl.ident<>"new" Continue
					Else If kind="operator"
						If Not decl.IsOperator Continue
					Else If kind<>decl.kind Or decl.ident="new" Or decl.IsOperator
						Continue
					Endif
					
					If init
						init=False
						_md.EmitBr()
						_md.Emit( "| "+kind.Capitalize()+"s | |" )
						_md.Emit( "|:---|:---|" )
					Endif
					
					_md.Emit( "| "+DeclIdent( decl,func.scope )+" | "+DeclDesc( decl )+" |" )
					Exit
					
				Next
				Continue
			Endif
			
		Next

	End
	
	#rem
	Method MakeNamespaceDocs:String( nmspace:NamespaceScope )
	
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
		
		_md.Emit( _namespaceDocs[nmspace.ntype.ident] )
		
		Return _md.Flush()
	End
	#end
	
	Method MakeAliasDocs:String( atype:AliasType )
		Local decl:=atype.adecl
		
		If DocsHidden( decl ) Return ""
		
		_linkScope=atype.scope
		
		EmitHeader( decl,atype.scope )
		
		_md.Emit( "##### Alias "+DeclIdent( decl,True )+" : "+TypeName( atype._alias,atype.scope ) )
		
		_md.Emit( decl.docs )
		
		Return _md.Flush()
	End
	
	Method MakeEnumDocs:String( etype:EnumType )
		Local decl:=etype.edecl
		
		If DocsHidden( decl ) Return ""
		
		_linkScope=etype.scope.outer

		EmitHeader( decl,etype.scope.outer )
		
		_md.Emit( "##### Enum "+DeclIdent( decl ) )
		
		_md.Emit( decl.docs )
		
		Return _md.Flush()
	End
	
	Method MakeClassDocs:String( ctype:ClassType )
	
		Local decl:=ctype.cdecl
		
		If DocsHidden( decl ) Return ""
		
		_linkScope=ctype.scope	'.outer
		
		EmitHeader( decl,ctype.scope.outer )
		
		Local xtends:=""
		If ctype.superType
			If ctype.superType<>Type.ObjectClass
				xtends=" Extends "+TypeName( ctype.superType,ctype.scope.outer )
			Endif
		Else If ctype.isvoid
			xtends=" Extends Void"
		Endif
		
		Local implments:=""
		If decl.ifaceTypes
			Local ifaces:=""
			For Local iface:=Eachin ctype.ifaceTypes
				ifaces+=","+TypeName( iface,ctype.scope.outer )
			Next
			ifaces=ifaces.Slice( 1 )
			If decl.kind="interface"
				xtends=" Extends "+ifaces
			Else
				implments=" Implements "+ifaces
			Endif
		Endif
		
		Local mods:=""
		If decl.IsVirtual
			mods+=" Virtual"
		Else If decl.IsAbstract
			mods+=" Abstract"
		Else If decl.IsFinal
			mods+=" Final"
		Endif
		
		_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl,True )+xtends+implments+mods )
		
		_md.Emit( decl.docs )
		
		For Local inh:=0 Until 1
			EmitMembers( "alias",ctype.scope,inh )
			EmitMembers( "enum",ctype.scope,inh )
			EmitMembers( "struct",ctype.scope,inh )
			EmitMembers( "class",ctype.scope,inh )
			EmitMembers( "interface",ctype.scope,inh )
			EmitMembers( "const",ctype.scope,inh )
			EmitMembers( "global",ctype.scope,inh )
			EmitMembers( "field",ctype.scope,inh )
			EmitMembers( "property",ctype.scope,inh )
			EmitMembers( "constructor",ctype.scope,inh )
			EmitMembers( "operator",ctype.scope,inh )
			EmitMembers( "method",ctype.scope,inh )
			EmitMembers( "function",ctype.scope,inh )
		End
		
		Return _md.Flush()
	End
	
	Method MakeVarDocs:String( vvar:VarValue )
	
		Local decl:=vvar.vdecl
		
		If DocsHidden( decl ) Return ""
		
		_linkScope=vvar.scope
		
		EmitHeader( decl,vvar.scope )
		
		_md.Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl )+" : "+TypeName( vvar.type,vvar.scope ) )
		
		_md.Emit( decl.docs )
		
		Return _md.Flush()
	End
		
	Method MakePropertyDocs:String( plist:PropertyList )
	
		Local decl:=plist.pdecl
		
		If DocsHidden( decl ) Return ""

		Local func:=plist.getFunc
		If Not func func=plist.setFunc
		If Not func Return ""
		Local type:=func.ftype.argTypes ? func.ftype.argTypes[1] Else func.ftype.retType
		
'		Local fdecl:=func.fdecl

		_linkScope=func.scope
		
		EmitHeader( decl,func.scope )
		
		_md.Emit( "##### Property "+DeclIdent( decl )+" : "+TypeName( type,func.scope ) )
		
		_md.Emit( decl.docs )
		
		Return _md.Flush()
	End
	
	Method MakeFuncDocs:String( flist:FuncList,kind:String )

		If Cast<PropertyList>( flist ) Return ""

		Local docs:StringStack
				
		For Local func:=Eachin flist.funcs
			Local decl:=func.fdecl
			
			If DocsHidden( decl ) Continue
			
			If kind="constructor"
				If decl.ident<>"new" Continue
			Else If kind="operator"
				If Not decl.IsOperator Continue
			Else If kind<>decl.kind Or decl.ident="new" Or decl.IsOperator
				Continue
			Endif
			
			_linkScope=func.scope
			
			If Not docs
				docs=New StringStack
				EmitHeader( decl,func.scope )
			Endif
			
			docs.Push( decl.docs )
			
			Local tkind:=decl.kind.Capitalize()+" "
			If decl.IsOperator tkind=""
			
			Local params:=""
			For Local i:=0 Until func.ftype.argTypes.Length
				Local ident:=Esc( func.fdecl.type.params[i].ident )
				Local type:=TypeName( func.ftype.argTypes[i],func.scope )
				Local init:=""
				If func.fdecl.type.params[i].init
					init=" ="+func.fdecl.type.params[i].init.ToString()
				Endif
				params+=" , "+ident+" : "+type+init
			Next
			params=params.Slice( 3 )
			
			_md.Emit( "##### "+tkind+DeclIdent( decl,True )+" : "+TypeName( func.ftype.retType,func.scope )+" ( "+params+" ) " )

		Next
		
		If Not docs 
			_md.Flush()
			Return ""
		Endif
		
		For Local doc:=Eachin docs
			_md.Emit( doc )
		Next
		
		Return _md.Flush()
	End
	
End
