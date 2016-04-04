
Namespace mx2.docs

Class DocsMaker

	Protected
	
	Field _module:Module
	
	Field _scope:Scope

	Field _pagesDir:String			'module/docs
	Field _pageTemplate:String
	
	Field _buf:=New StringStack
	Field _params:=New StringStack
	Field _return:String
	
	Function JsonEscape:String( str:String )
		str=str.Replace( "\","\\" )
		str=str.Replace( "~q","\~q" )
		str=str.Replace( "~n","\n" )
		str=str.Replace( "~r","\r" )
		str=str.Replace( "~t","\t" )
		Return "~q"+str+"~q"
	End
	
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
	
	Method EmitBr()
		_buf.Push( "" )
	End
	
	Method ReplaceLinks:String( line:String )
		Repeat
			Local i0:=line.Find( "[[" )
			If i0=-1 Return line
			Local i1:=line.Find( "]]",i0+2 )
			If i1=-1 Return line
			Local path:=line.Slice( i0+2,i1 )
			Local link:=ResolveLink( path,_scope )
			If Not link
				Print "Makedocs error: Can't resolve link '"+path+"'"
				link=path
			Endif
			line=line.Slice( 0,i0 )+link+line.Slice( i1+2 )
		Forever
		Return line
	End
	
	Method Emit( docs:String )
	
		If Not docs.Contains( "~n" )
			_buf.Push( ReplaceLinks( docs ) )
			Return
		Endif
		
		Local lines:=docs.Split( "~n" )
		
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
					'TODO
					Continue
				
				Default
					Print "Makedocs: unrecognized '"+lines[i]+"'"
				End

				Continue
			Endif
			
			_buf.Push( ReplaceLinks( line ) )
			
		Next
	End
	
	Method FlushParams()

		If Not _params.Length Return
		
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
	End
	
	Method Flush:String()
	
		FlushParams()
	
		Local markdown:=_buf.Join( "~n" ).Trim()+"~n"
		
		_buf.Clear()
		
		Local docs:=std.markdown.MarkdownToHtml( markdown )
		
		Return docs
	End
	
	Method MungUrl:String( url:String )
		url=url.Replace( "_","_0" )
		url=url.Replace( "<","_1" )
		url=url.Replace( ">","_2" )
		url=url.Replace( ",","_3" )
		url=url.Replace( "?","_4" )
		url=url.Replace( "&","_5" )
		url=url.Replace( "@","_6" )
		url=url.Replace( ".","_" )
		Return url
	End
	
	Method HtmlEsc:String( str:String )
		str=str.Replace( "&","&amp;" )
		str=str.Replace( "<","&lt;" )
		str=str.Replace( ">","&gt;" )
		Return str
	End
	
	Method MarkdownEsc:String( str:String )
		str=str.Replace( "\","\\" )
		str=str.Replace( "_","\_" )
		str=str.Replace( "<","\<" )
		str=str.Replace( ">","\>" )
		Return str
	End
	
	Method DeclSlug:String( decl:Decl,scope:Scope )
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
		slug=slug.Replace( ".","-" )
		Return slug
	End
	
	Method NamespaceSlug:String( nmspace:NamespaceScope )
		Local slug:=nmspace.Name
		slug=slug.Replace( ".","-" )
		Return slug
	End
	
	Method DeclPage:String( decl:Decl,scope:Scope )
	
		Return DeclSlug( decl,scope )
	End
	
	Method NamespacePage:String( nmspace:NamespaceScope )
	
		Return NamespaceSlug( nmspace )
	End
	
	Method MakeLink:String( text:String,url:String )

		Return "<a href='"+url+"'>"+text+"</a>"
	End
	
	Method MakeLink:String( text:String,module:String,page:String )
		
		Return "<a href='javascript:void(0)' onclick=~qdocsLinkClicked('"+page+"','"+module+"')~q>"+text+"</a>"
	End
	
	Method MakeLink:String( text:String,decl:Decl,scope:Scope )
	
		Local module:=scope.FindFile().fdecl.module.name
		Local page:=DeclPage( decl,scope )
		
		Return MakeLink( text,module,page )
	End
	
	Method ResolveLink:String( path:String,scope:Scope )
	
		Local i0:=0
		
		Repeat
		
			Local i1:=path.Find( ".",i0 )
			If i1=-1	'find 'leaf'
			
				Local id:=path.Slice( i0 )
'				Print "Finding node "+id+" in "+scope.Name
				
				Local node:=scope.FindNode( id )
				If Not node Return ""
				
				Local vvar:=Cast<VarValue>( node )
				If vvar Return MakeLink( id,vvar.vdecl,vvar.scope )
				
				Local flist:=Cast<FuncList>( node )
				If flist Return MakeLink( id,flist.funcs[0].fdecl,flist.funcs[0].scope )
				
				Local etype:=Cast<EnumType>( node )
				If etype Return MakeLink( id,etype.edecl,etype.scope.outer )
				
				Local ctype:=Cast<ClassType>( node )
				If ctype Return MakeLink( id,ctype.cdecl,ctype.scope.outer )
				
				Return ""
			Endif
			
			Local id:=path.Slice( i0,i1 )
			i0=i1+1
			
			Print "Finding type "+id+" in "+scope.Name
			
			Local type:=scope.FindType( id )
			If Not type Return ""
			
			Local ntype:=Cast<NamespaceType>( type )
			If ntype
				scope=ntype.scope
				Continue
			Endif
			
			Local etype:=Cast<EnumType>( type )
			If etype
				'stop at enum!
				Return MakeLink( id+"."+path.Slice( i0 ),etype.edecl,etype.scope.outer )
			Endif
			
			Local ctype:=Cast<ClassType>( type )
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
			Local cdecl:=Cast<ClassDecl>( decl )
			If cdecl And cdecl.genArgs ident+="<"+(",".Join( cdecl.genArgs ))+">"
			
			Local fdecl:=Cast<FuncDecl>( decl )
			If fdecl And fdecl.genArgs ident+="<"+(",".Join( fdecl.genArgs ))+">"
		Endif
		
		Return MarkdownEsc( ident )
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
		If i<>-1 Return desc.Slice( 0,i )
		Return desc
	End
	
	Method SavePage( docs:String,page:String )
		docs=_pageTemplate.Replace( "${CONTENT}",docs )
		stringio.SaveString( docs,_pagesDir+page+".html" )
	End
	
	Method TypeName:String( type:Type,prefix:String )
	
		Local vtype:=Cast<VoidType>( type )
		If vtype
			Return vtype.Name
		Endif
	
		Local gtype:=Cast<GenArgType>( type )
		If gtype
			Return gtype.Name.Replace( "?","" )
		Endif
	
		Local ptype:=Cast<PrimType>( type )
		If ptype
			Local ctype:=ptype.ctype
			Return MakeLink( ptype.Name,ctype.cdecl,ctype.scope.outer )
		Endif
		
		Local ntype:=Cast<NamespaceType>( type )
		If ntype
			Return ntype.Name
		Endif
		
		Local ctype:=Cast<ClassType>( type )
		If ctype
			Local args:=""
			For Local type:=Eachin ctype.types
				args+=","+TypeName( type,prefix )
			Next
			If args args="\< "+args.Slice( 1 )+" \>"
			
			If ctype.instanceOf ctype=ctype.instanceOf
			
			Return MakeLink( MarkdownEsc( ctype.cdecl.ident ),ctype.cdecl,ctype.scope.outer )+args
		Endif
		
		Local etype:=Cast<EnumType>( type )
		If etype
			Local name:=etype.Name
			If name.StartsWith( prefix ) name=name.Slice( prefix.Length )
			Return MakeLink( MarkdownEsc( name ),etype.edecl,etype.scope.outer )
		Endif
		
		Local qtype:=Cast<PointerType>( type )
		If qtype
			Return TypeName( qtype.elemType,prefix )+" Ptr"
		Endif
		
		Local atype:=Cast<ArrayType>( type )
		If atype
			If atype.rank=1 Return TypeName( atype.elemType,prefix )+"\[ \]"
			Return TypeName( atype.elemType,prefix )+"\[ ,,,,,,,,,".Slice( 0,atype.rank+2 )+" \]"
		End
		
		Local ftype:=Cast<FuncType>( type )
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
		Local module:=fscope.fdecl.module.name
		Local nmspace:=fscope.nmspace.Name
		Emit( "_Module: &lt;"+module+"&gt;_  " )
		Emit( "_Namespace:_ <em>"+MakeLink( nmspace,module,NamespacePage( fscope.nmspace ) )+"</em>" )
		EmitBr()
		Emit( "#### "+DeclName( decl,scope ) )
		EmitBr()
	End
	
	Method DocsHidden:Bool( decl:Decl )
		Return (decl.IsPrivate And Not decl.docs) Or decl.docs.StartsWith( "@hidden" )
	End
	
	Method EmitMembers( kind:String,scope:Scope,inherited:Bool )
	
		Local init:=True
	
		For Local node:=Eachin scope.nodes

			Local ctype:=Cast<ClassType>( node.Value )
			If ctype
				Local decl:=ctype.cdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>ctype.scope.outer) Continue
				
				If init
					init=False
					Local kinds:=kind.Capitalize() + (kind="class" ? "es" Else "s")
					EmitBr()
					Emit( "| "+kinds+" | |" )
					Emit( "|:---|:---|" )
				Endif
				
				Emit( "| "+DeclIdent( decl,ctype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			End
			
			Local etype:=Cast<EnumType>( node.Value )
			If etype
				If kind<>"enum" Continue
				Local decl:=etype.edecl
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>etype.scope.outer) Continue
				
				If init
					init=False
					EmitBr()
					Emit( "| Enums | |" )
					Emit( "|:---|:---|" )
				Endif

				Emit( "| "+DeclIdent( decl,etype.scope.outer )+" | "+DeclDesc( decl )+" |" )
				Continue
			End

			Local vvar:=Cast<VarValue>( node.Value )
			If vvar
				Local decl:=vvar.vdecl
				If kind<>decl.kind Continue
				If DocsHidden( decl ) Continue
				If inherited<>(scope<>vvar.scope) Continue

				If init
					init=False
					EmitBr()
					Emit( "| "+kind.Capitalize()+"s | |" )
					Emit( "|:---|:---|" )
				Endif

				Emit( "| "+DeclIdent( decl,vvar.scope )+" | "+DeclDesc( decl )+" |" )
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
					EmitBr()
					Emit( "| Properties | |" )
					Emit( "|:---|:---|" )
				Endif

				Emit( "| "+DeclIdent( decl,plist.scope )+" | "+DeclDesc( decl )+" |" )
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
						EmitBr()
						Emit( "| "+kind.Capitalize()+"s | |" )
						Emit( "|:---|:---|" )
					Endif
					
					Emit( "| "+DeclIdent( decl,func.scope )+" | "+DeclDesc( decl )+" |" )
					Exit
					
				Next
				Continue
			Endif
			
		Next

	End
	
	Method MakeNamespaceDocs:String( nmspace:NamespaceScope )
	
		_scope=nmspace
	
		Emit( "_Module: &lt;"+_module.name+"&gt;_  " )
		Emit( "_Namespace: "+nmspace.Name+"_" )
		
		EmitMembers( "enum",nmspace,True )
		EmitMembers( "struct",nmspace,True )
		EmitMembers( "class",nmspace,True )
		EmitMembers( "interface",nmspace,True )
		EmitMembers( "const",nmspace,True )
		EmitMembers( "global",nmspace,True )
		EmitMembers( "function",nmspace,True )
		
		Return Flush()
	End
	
	Method MakeEnumDocs:String( etype:EnumType )
		Local decl:=etype.edecl
		
		If DocsHidden( decl ) Return ""
		
		_scope=etype.scope.outer

		EmitHeader( decl,etype.scope.outer )
		
		Emit( "##### Enum "+DeclIdent( decl ) )
		
		Emit( decl.docs )
		
		Return Flush()
	End
	
	Method MakeClassDocs:String( ctype:ClassType )
	
		Local decl:=ctype.cdecl
		
		If DocsHidden( decl ) Return ""
		
		_scope=ctype.scope.outer
		
		EmitHeader( decl,ctype.scope.outer )
		
		Local xtends:=""
		If decl.superType
			xtends=" Extends "+TypeName( ctype.superType,ctype.scope.outer )
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
		
		Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl,True )+xtends+implments+mods )
		
		Emit( decl.docs )
		
		For Local inh:=0 Until 1
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
		
		Return Flush()
	End
	
	Method MakeVarDocs:String( vvar:VarValue )
	
		Local decl:=vvar.vdecl
		
		If DocsHidden( decl ) Return ""
		
		_scope=vvar.scope
		
		EmitHeader( decl,vvar.scope )
		
		Emit( "##### "+decl.kind.Capitalize()+" "+DeclIdent( decl )+" : "+TypeName( vvar.type,vvar.scope ) )
		
		Emit( decl.docs )
		
		Return Flush()
	End
		
	Method MakePropertyDocs:String( plist:PropertyList )
	
		Local decl:=plist.pdecl
		
		If DocsHidden( decl ) Return ""

		Local func:=plist.getFunc
		If Not func func=plist.setFunc
		If Not func Return ""
		Local type:=func.ftype.argTypes ? func.ftype.argTypes[1] Else func.ftype.retType
		
'		Local fdecl:=func.fdecl

		_scope=func.scope
		
		EmitHeader( decl,func.scope )
		
		Emit( "##### Property "+DeclIdent( decl )+" : "+TypeName( type,func.scope ) )
		
		Emit( decl.docs )
		
		Return Flush()
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
			
			_scope=func.scope
			
			If Not docs
				docs=New StringStack
				EmitHeader( decl,func.scope )
			Endif
			
			docs.Push( decl.docs )
			
			Local tkind:=decl.kind.Capitalize()+" "
			If decl.IsOperator tkind=""
			
			Local params:=""
			For Local i:=0 Until func.ftype.argTypes.Length
				Local ident:=MarkdownEsc( func.fdecl.type.params[i].ident )
				Local type:=TypeName( func.ftype.argTypes[i],func.scope )
				Local init:=""
				If func.fdecl.type.params[i].init
					init=" ="+func.fdecl.type.params[i].init.ToString()
				Endif
				params+=" , "+ident+" : "+type+init
			Next
			params=params.Slice( 3 )
			
			Emit( "##### "+tkind+DeclIdent( decl )+" : "+TypeName( func.ftype.retType,func.scope )+" ( "+params+" ) " )

		Next
		
		If Not docs Return ""
		
		For Local doc:=Eachin docs
			Emit( doc )
		Next
		
		Return Flush()
	End
	
End
