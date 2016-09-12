
Namespace mx2

Class Translator_CPP Extends Translator

	Field _lambdaId:Int
	
	Field _gctmps:=0
	
	Method Translate( fdecl:FileDecl ) 'Override
	
		_incs[fdecl.ident]=fdecl

		'***** Emit header file *****
		
		_buf.Clear()
		
		EmitBr()
		Emit( "#ifndef MX2_"+fdecl.ident.ToUpper()+"_H" )
		Emit( "#define MX2_"+fdecl.ident.ToUpper()+"_H" )
		EmitBr()
		Emit( "#include <bbmonkey.h>" )
		
		If fdecl.exhfile
			Emit( "#include ~q"+MakeIncludePath( fdecl.exhfile,ExtractDir( fdecl.hfile ) )+"~q" )
		End
		
		For Local ipath:=Eachin fdecl.imports
		
			If ipath.Contains( "*." ) Continue
		
			Local imp:=ipath.ToLower()
			
			If imp.EndsWith( ".h" ) Or imp.EndsWith( ".hh" ) Or imp.EndsWith( ".hpp" )
				Local path:=ExtractDir( fdecl.path )+ipath
				Emit( "#include ~q"+MakeIncludePath( path,ExtractDir( fdecl.hfile ) )+"~q" )
				Continue
			Endif
			
			If imp.EndsWith( ".h>" ) Or imp.EndsWith( ".hh>" ) Or imp.EndsWith( ".hpp>" )
				Emit( "#include "+ipath )
				Continue
			Endif
			
		Next			
		
		BeginDeps()
		
		Emit( "// ***** Internal *****" )
		
		EmitBr()
		For Local etype:=Eachin fdecl.enums
			Emit( "enum class "+EnumName( etype )+";" )
		Next
		
		EmitBr()
		For Local ctype:=Eachin fdecl.classes
			Emit( "struct "+ClassName( ctype )+";" )
		Next

		EmitBr()
		For Local vvar:=Eachin fdecl.globals
			Refs( vvar.type )
			Emit( "extern "+VarProto( vvar )+";" )
		Next
		
		EmitBr()
		For Local func:=Eachin fdecl.functions
			Refs( func.ftype )
			Emit( "extern "+FuncProto( func,True )+";" )
		Next
		
		'Ouch, have to emit classes in correct order!
		'
		Local emitted:=New StringMap<Bool>
		'
		EmitBr()
		For Local ctype:=Eachin fdecl.classes
			If emitted[ClassName( ctype )] Continue
			EmitClassProto( ctype,fdecl,emitted )
		Next
		
		EndDeps( ExtractDir( fdecl.hfile ) )
		
		EmitBr()		
		Emit( "#endif" )
		EmitBr()
		
		CSaveString( _buf.Join( "~n" ),fdecl.hfile )
		
		'***** Emit cpp source file *****
		
		_buf.Clear()
		
		EmitBr()
		Emit( "#include ~q"+MakeRelativePath( fdecl.hfile,ExtractDir( fdecl.cfile ) )+"~q" )
		EmitBr()
		
		BeginDeps()
		
		Emit( "// ***** Internal *****" )
		
		EmitBr()
		For Local vvar:=Eachin fdecl.globals
			Uses( vvar.type )
			Local proto:=VarProto( vvar )
			Emit( proto+";" )
		Next
		
		For Local func:=Eachin fdecl.functions
			EmitFunc( func )
		Next
		
		For Local ctype:=Eachin fdecl.classes
			EmitClassMembers( ctype )
		Next
		
		EmitGlobalInits( fdecl )

		EndDeps( ExtractDir( fdecl.cfile ) )
		
		EmitBr()
		
		CSaveString( _buf.Join( "~n" ),fdecl.cfile )
	End
	
	'***** Decls *****
	
	Method GCVarTypeName:String( type:Type )
	
		Local ctype:=TCast<ClassType>( type )
		If ctype And Not ctype.ExtendsVoid And (ctype.cdecl.kind="class" Or ctype.cdecl.kind="interface") Return ClassName( ctype )
		
		Local atype:=TCast<ArrayType>( type )
		If atype Return ArrayName( atype )
		
		Return ""
	End
	
	Method ElementType:String( type:Type )
	
		Local name:=GCVarTypeName( type )
		If Not name Return TransType( type )
		
		Return "bbGCVar<"+name+">"
	End
	
	Method VarType:String( vvar:VarValue )
	
		Local type:=vvar.type
	
		Local name:=GCVarTypeName( type )
		If Not name Return TransType( type )
		
		Select vvar.vdecl.kind
		Case "local"
			Return name+"*"
		Case "field"
			Return "bbGCVar<"+name+">"
		Case "global","const"
			Return "bbGCRootVar<"+name+">"
		End
		
		TransError( "Translator.VarType()" )
		Return ""
	End

	Method VarProto:String( vvar:VarValue ) Override
	
		Return VarType( vvar )+" "+VarName( vvar )
	End
	
	Method FuncProto:String( func:FuncValue ) Override

		Return FuncProto( func,True )
	End
	
	Method FuncProto:String( func:FuncValue,header:Bool )

		Local fdecl:=func.fdecl
		Local ftype:=func.ftype
		Local ctype:=func.scope.FindClass()
	
		Local retType:=""
		If Not func.IsCtor retType=TransType( ftype.retType )+" "

		Local params:=""
		If func.IsExtension
			Local tself:=func.selfType.IsStruct ? "&l_self" Else "l_self"
			params=TransType( func.selfType )+" "+tself
		Endif

		For Local p:=Eachin func.params
			If params params+=","
			params+=TransType( p.type )+" "+VarName( p )
		Next

		If func.IsCtor And ctype.IsStruct
			If Not ftype.argTypes.Length Or ftype.argTypes[0].Equals( ctype )
				If params params+=","
				params+="bbNullCtor_t"
			Endif
		Endif
		
		Local ident:=FuncName( func )
		If Not header And func.IsMember ident=ClassName( ctype )+"::"+ident
		
		Local proto:=retType+ident+"("+params+")"
		
		If header And func.IsMember
			If fdecl.IsAbstract Or fdecl.IsVirtual Or ctype.IsVirtual
				proto="virtual "+proto
				If fdecl.IsAbstract proto+="=0"
			Endif
		Endif
		
		Return proto
	End
	
	Method EmitGlobalInits( fdecl:FileDecl )
	
		EmitBr()
		Emit( "void mx2_"+fdecl.ident+"_init(){" )
		BeginGCFrame()
		Emit( "static bool done;" )
		Emit( "if(done) return;" )
		Emit( "done=true;")
		
		For Local vvar:=Eachin fdecl.globals
			If vvar.init Emit( Trans( vvar )+"="+Trans( vvar.init )+";" )
		Next
		
		EndGCFrame()
		Emit( "}" )
		
		EmitBr()
		Emit( "bbInit mx2_"+fdecl.ident+"_init_v(~q"+fdecl.ident+"~q,&mx2_"+fdecl.ident+"_init);" )
	
	End
	
	Method EmitClassProto( ctype:ClassType,fdecl:FileDecl,emitted:StringMap<Bool> )
	
		If ctype.cdecl.kind="protocol" Return
		
		Local insPos:=InsertPos
		
		EmitClassProto( ctype )
		
		emitted[ClassName( ctype )]=True
	
		For Local ctype2:=Eachin _usesTypes.Values
		
			If ctype2.cdecl.IsExtern Or ctype2.transFile<>fdecl Or emitted[ClassName( ctype2 )] Continue
			
			If insPos<>-1
				EmitBr()		
				BeginInsert( insPos )
				insPos=-1
			Endif

			EmitClassProto( ctype2,fdecl,emitted )
			
		Next
		
		If insPos=-1 EndInsert()
	
	End
	
	Method EmitClassProto( ctype:ClassType )
	
		Local cdecl:=ctype.cdecl
		Local cname:=ClassName( ctype )
		
		Local xtends:=""
		Local superName:String
	
		Select cdecl.kind
		
		Case "class"
		
			If ctype.superType
				Uses( ctype.superType )
				superName=ClassName( ctype.superType )
				xtends="public "+superName
			Else
				xtends="public bbObject"
			Endif
			
		Case "struct"

			If ctype.superType
				Uses( ctype.superType )
				superName=ClassName( ctype.superType )
				xtends="public "+superName
			Endif
		
		Case "interface"
		
			If Not ctype.ifaceTypes xtends="public bbInterface"
			
		End
		
		For Local iface:=Eachin ctype.ifaceTypes
			If iface.cdecl.kind="protocol" Continue
			Uses( iface )
			If xtends xtends+=","
			xtends+="public virtual "+ClassName( iface )
		Next
		
		If xtends xtends=" : "+xtends
		
		EmitBr()
		Emit( "struct "+cname+xtends+"{" )
		
		If ctype.superType
		
			Local done:=New StringMap<Bool>
		
			EmitBr()	
			For Local it:=Eachin ctype.scope.nodes
			
				Local flist:=Cast<FuncList>( it.Value )
				If Not flist Or it.Key="new" Continue
				
				For Local func:=Eachin flist.funcs
					If Not func.IsMethod Or func.scope<>ctype.superType.scope Continue	'Or func.fdecl.IsExtension Continue
					Local sym:=FuncName( func )
					If done[sym] Continue
					done[sym]=True
					Emit( "using "+superName+"::"+sym+";" )
				Next
			Next
		Endif
		
		Emit( "const char *typeName()const{return ~q"+cname+"~q;}" )
		
		'Emit fields...
		'
		Local needsInit:=False
		Local needsMark:=False

		EmitBr()		
		For Local vvar:=Eachin ctype.fields

			Refs( vvar.type )
			If IsGCType( vvar.type ) needsMark=True
			
			Local proto:=VarProto( vvar )
			
			If vvar.init
				If vvar.init.HasSideEffects
					Emit( proto+"{};" )
					needsInit=True
				Else
					Emit( proto+"="+Trans( vvar.init )+";" )
				Endif
			Else
				Emit( proto+"{};" )
			Endif
			
		Next

		If needsInit
			EmitBr()
			Emit( "void init();" )
		Endif
		
		If cdecl.kind="class"
		
			If needsMark
				EmitBr()
				Emit( "void gcMark();" )
			Endif
		
		Endif
		
		If debug
		
			If cdecl.kind="class"
				Emit( "void dbEmit();" )
			Else If cdecl.kind="struct"
				Emit( "static void dbEmit("+cname+"*);" )
			Endif

		Endif

		'Emit ctor methods
		'
		Local hasCtor:=False
		Local hasDefaultCtor:=False
		
		EmitBr()
		For Local func:=Eachin ctype.ctors
			
			hasCtor=True
			If Not func.ftype.argTypes hasDefaultCtor=True
			
			Refs( func.ftype )
			Emit( FuncProto( func,true )+";" )

		Next
		
		'Emit non-ctor methods
		'
		Local hasCmp:=False
		
		EmitBr()
		For Local func:=Eachin ctype.methods
			
			If func.fdecl.ident="<=>" hasCmp=True
			
			Refs( func.ftype )
			Emit( FuncProto( func,True )+";" )

		Next
		
		If cdecl.kind="struct"
			If hasCtor Or Not hasDefaultCtor
				EmitBr()
				Emit( cname+"(){" )
				Emit( "}" )
			Endif
			If Not hasDefaultCtor
				EmitBr()
				Emit( cname+"(bbNullCtor_t){" )
				If needsInit Emit( "init();" )
				Emit( "}" )
			Endif
		Else If cdecl.kind="class"
			If Not hasDefaultCtor
				EmitBr()
				Emit( cname+"(){" )
				If needsInit Emit( "init();" )
				Emit( "}" )
			Endif
		Endif

		Emit( "};" )
		
		If debug
			Local tname:=cname
			If Not IsStruct( ctype ) tname+="*"
			Emit( "bbString bbDBType("+tname+"*);" )
			Emit( "bbString bbDBValue("+tname+"*);" )
		Endif
		
		If IsStruct( ctype )

			EmitBr()
			If hasCmp
				Emit( "inline int bbCompare(const "+cname+"&x,const "+cname+"&y){return x.m__cmp(y);}" )
			Else
				Emit( "int bbCompare(const "+cname+"&x,const "+cname+"&y);" )
			Endif
		
			If needsMark
				EmitBr()
				Emit( "void bbGCMark(const "+ClassName( ctype )+"&);" )
			Endif
			
		Endif
		
	End
	
	Method EmitClassMembers( ctype:ClassType )
	
		Local cdecl:=ctype.cdecl
		If cdecl.kind="protocol" Return
		
		Local cname:=ClassName( ctype )
		
		'Emit fields...
		'
		Local needsInit:=False
		Local needsMark:=False

		EmitBr()		
		For Local vvar:=Eachin ctype.fields
			
			If IsGCType( vvar.type ) needsMark=True
			
			If vvar.init And vvar.init.HasSideEffects needsInit=True
			
'			If vvar.init And Not Cast<LiteralValue>( vvar.init ) needsInit=True
		Next
		
		'Emit init() method
		'
		If needsInit

			EmitBr()
			Emit( "void "+cname+"::init(){" )
			
			BeginGCFrame()
			
			For Local vvar:=Eachin ctype.fields
				If Not vvar.init Or Not vvar.init.HasSideEffects Continue

				Emit( Trans( vvar )+"="+Trans( vvar.init )+";" )
			Next
			
			EndGCFrame()

			Emit( "}" )
		
		Endif
		
		If cdecl.kind="class"
		
			If needsMark
			
				EmitBr()
				Emit( "void "+cname+"::gcMark(){" )
				
				If ctype.superType And ctype.superType<>Type.ObjectClass
					Emit( ClassName( ctype.superType )+"::gcMark();" )
				End
			
				For Local vvar:=Eachin ctype.fields
					If Not IsGCType( vvar.type ) Continue
					
					Uses( vvar.type )
					Emit( "bbGCMark("+VarName( vvar )+");" )
				Next
				
				Emit( "}" )
			
			Endif
			
		Endif
		
		If debug And cdecl.kind="class"
			EmitBr()
			
			Emit( "void "+cname+"::dbEmit(){" )

			If ctype.superType And Not ctype.superType.cdecl.IsExtern	'And ctype.superType<>Type.ObjectClass
				Emit( ClassName( ctype.superType )+"::dbEmit();" )
			End
			
			For Local vvar:=Eachin ctype.fields
				Emit( "bbDBEmit(~q"+vvar.vdecl.ident+"~q,&"+VarName( vvar )+");" )
			Next
			
			Emit( "}" )
		Endif
		
		If debug And cdecl.kind="struct"
			EmitBr()
			
			Emit( "void "+cname+"::dbEmit("+cname+"*p){" )
			
			For Local vvar:=Eachin ctype.fields
				Emit( "bbDBEmit(~q"+vvar.vdecl.ident+"~q,&p->"+VarName( vvar )+");" )
			Next
			
			Emit( "}" )
		Endif
	
		'Emit ctor methods
		'
		For Local func:=Eachin ctype.ctors
			
			EmitBr()
			EmitFunc( func,needsInit )
		Next
		
		'Emit non-ctor methods
		'
		Local hasCmp:=False
		
		For Local func:=Eachin ctype.methods
			
			If func.fdecl.ident="<=>" 
				hasCmp=True
			Endif

			EmitBr()
			EmitFunc( func )
		Next
		
		If debug
			Local tname:=cname
			If Not IsStruct( ctype ) tname+="*"
			
			Emit( "bbString bbDBType("+tname+"*){" )
			Emit( "return ~q"+ctype.Name+"~q;" )
			Emit( "}" )
			
			Emit( "bbString bbDBValue("+tname+"*p){" )
			
			If ctype.ExtendsVoid
				Emit( "return bbDBValue(*p);" )
			Else
				Select cdecl.kind
				Case "class"

					Emit( "return bbDBObjectValue(*p);" )
					
				Case "interface"
				
					Emit( "return bbDBInterfaceValue(*p);" )
					
				Case "struct"
				
					Emit( "return bbDBStructValue(p);" )
				End
			Endif
				
			Emit( "}" )
				
		Endif

		'Emit static struct methods
		'
		If IsStruct( ctype ) 

			If Not hasCmp
				EmitBr()
				Emit( "int bbCompare(const "+cname+"&x,const "+cname+"&y){" )
				For Local vvar:=Eachin ctype.fields
					Local vname:=VarName( vvar )
					Emit( "if(int t=bbCompare(x."+vname+",y."+vname+")) return t;" )
				Next
				Emit( "return 0;" )
				Emit( "}" )
			Endif
		
			If needsMark
		
				EmitBr()
				Emit( "void bbGCMark(const "+cname+"&t){" )
				
				If ctype.superType And ctype.superType<>Type.ObjectClass
					Emit( "bbGCMark(("+ClassName( ctype.superType )+"&)t);" )
				Endif
	
				For Local vvar:=Eachin ctype.fields
					If Not IsGCType( vvar.type ) Continue
					
					Uses( vvar.type )
					Emit( "bbGCMark(t."+VarName( vvar )+");" )
				Next
				
				Emit( "}" )
				
			Endif
			
		Endif

	End
	
	Method EmitFunc( func:FuncValue,init:Bool=False )
	
		If func.fdecl.IsAbstract Return
	
		Local proto:=FuncProto( func,False )
		
		If func.invokeNew
		
			proto+=":"+ClassName( func.invokeNew.ctype )+"("+TransArgs( func.invokeNew.args )+")"
			
			'Don't call init if we start with self.new!
			Local cscope:=Cast<ClassScope>( func.scope )
			If func.invokeNew.ctype=cscope.ctype init=False
		End
		
		EmitBr()
		
		Emit( proto+"{" )
		
		If _gctmps
			Emit( "bbGC::popTmps("+_gctmps+");" )
			_gctmps=0
		Endif
		
		If init Emit( "init();" )
		
		'is it 'main'?
		Local module:=func.scope.FindFile().fdecl.module
		
		If func=module.main
		
			Emit( "static bool done;" )
			Emit( "if(done) return;" )
			Emit( "done=true;" )
			
			For Local dep:=Eachin module.moduleDeps.Keys
			
				Local mod2:=Builder.modulesMap[dep]
				
				If mod2.main
					Emit( "void mx2_"+mod2.ident+"_main();mx2_"+mod2.ident+"_main();" )
				Endif
			Next
			
		Endif
		
		If debug And func.IsMethod
		
			If Not func.IsVirtual And Not func.IsExtension
				'			
				'Can't do this yet as it breaks mx2cc!
				'
				'Emit( "bbDBAssertSelf(this);" )
				'
			Endif
			
		Endif
		
		EmitBlock( func )
		
		Emit( "}" )
	End
	
	Method EmitLambda:String( func:FuncValue )
	
		Local ident:String="lambda"+_lambdaId
		_lambdaId+=1
		
		Local bbtype:="bbFunction<"+CFuncType( func.ftype )+">"
		
		Emit( "struct "+ident+" : public "+bbtype+"::Rep{" )
		
		Local ctorArgs:="",ctorInits:="",ctorVals:=""
		
		For Local vvar:=Eachin func.captures
			Local varty:=TransType( vvar.type )
			Local varid:=VarName( vvar )
			Emit( varty+" "+varid+";" )
			ctorArgs+=","+varty+" "+varid
			ctorInits+=","+varid+"("+varid+")"
			ctorVals+=","+Trans( vvar.init )
		Next
		
		If ctorArgs
			ctorVals="("+ctorVals.Slice( 1 )+")"
			Emit( ident+"("+ctorArgs.Slice( 1 )+"):"+ctorInits.Slice( 1 )+"{" )
			Emit( "}" )
		Endif
		
		Local retType:=TransType( func.ftype.retType )

		Local params:=""
		For Local p:=Eachin func.params
			If params params+=","
			params+=TransType( p.type )+" "+VarName( p )
		Next
		
		Emit( retType+" invoke("+params+"){" )
		
		EmitBlock( func )
		
		Emit( "}" )

		Emit( "void gcMark(){" )
		For Local vvar:=Eachin func.captures
			If Not IsGCType( vvar.type ) Continue
			Uses( vvar.type )
			If IsGCPtrType( vvar.type )
				Emit( "bbGCMarkPtr("+VarName( vvar )+");" )
			Else
				Emit( "bbGCMark("+VarName( vvar )+");" )
			Endif
		Next
		Emit( "}" )
		
		Emit( "};" )
		
		Return bbtype+"(new "+ident+ctorVals+")"
	End
	
	'***** Block *****
	
	Method BeginBlock()

		BeginGCFrame()
		If debug Emit( "bbDBBlock db_blk;" )

	End
	
	Method EmitStmts( block:Block )

		For Local stmt:=Eachin block.stmts
			EmitStmt( stmt )
			FreeGCTmps()
		Next

	End
	
	Method EndBlock()
	
		EndGCFrame()
	End
	
	Method EmitBlock( block:Block )
	
		BeginBlock()
		
		EmitStmts( block )
		
		EndBlock()
	End
	
	Method EmitBlock( func:FuncValue )
	
		BeginGCFrame( func )
		
		If debug 
		
			Emit( "bbDBFrame db_f{~q"+func.Name+":"+func.ftype.retType.Name+"("+func.ParamNames+")~q,~q"+func.pnode.srcfile.path+"~q};" )
			
			If func.IsMethod
				
				Select func.cscope.ctype.cdecl.kind
				Case "struct"
					Emit( ClassName( func.selfType )+"*self=&"+Trans( func.selfValue )+";" )
					Emit( "bbDBLocal(~qSelf~q,self);" )
				Case "class"
					Emit( ClassName( func.selfType )+"*self="+Trans( func.selfValue )+";" )
					Emit( "bbDBLocal(~qSelf~q,&self);" )
				End
				
			Endif
			
			For Local vvar:=Eachin func.params
				Emit( "bbDBLocal(~q"+vvar.vdecl.ident+"~q,&"+Trans( vvar )+");" )
			Next
			
		Endif
		
		EmitStmts( func.block )
	
		EndGCFrame()
	End
	
	'***** Stmt *****
	
	Method DebugInfo:String( stmt:Stmt )
		If debug And stmt.pnode Return "bbDBStmt("+stmt.pnode.srcpos+")"
		Return ""
	End
	
	Method EmitDebugInfo( stmt:Stmt )
		Local db:=DebugInfo( stmt )
		If db Emit( db+";" )
	End
	
	Method EmitStmt( stmt:Stmt )
	
		If Not stmt Return
		
		EmitDebugInfo( stmt )
		
		Local exitStmt:=Cast<ExitStmt>( stmt )
		If exitStmt EmitStmt( exitStmt ) ; Return
		
		Local continueStmt:=Cast<ContinueStmt>( stmt )
		If continueStmt EmitStmt( continueStmt ) ; Return
		
		Local returnStmt:=Cast<ReturnStmt>( stmt )
		If returnStmt EmitStmt( returnStmt ) ; Return
		
		Local varDeclStmt:=Cast<VarDeclStmt>( stmt )
		If varDeclStmt EmitStmt( varDeclStmt ) ; Return
		
		Local assignStmt:=Cast<AssignStmt>( stmt )
		If assignStmt EmitStmt( assignStmt ) ; Return
		
		Local evalStmt:=Cast<EvalStmt>( stmt )
		If evalStmt EmitStmt( evalStmt ) ; Return
		
		Local ifStmt:=Cast<IfStmt>( stmt )
		If ifStmt EmitStmt( ifStmt ) ; Return
		
		Local whileStmt:=Cast<WhileStmt>( stmt )
		If whileStmt EmitStmt( whileStmt ) ; Return
		
		Local repeatStmt:=Cast<RepeatStmt>( stmt )
		If repeatStmt EmitStmt( repeatStmt ) ; Return
		
		Local selectStmt:=Cast<SelectStmt>( stmt )
		If selectStmt EmitStmt( selectStmt ) ; Return
		
		Local forStmt:=Cast<ForStmt>( stmt )
		If forStmt EmitStmt( forStmt ) ; Return
		
		Local tryStmt:=Cast<TryStmt>( stmt )
		If tryStmt EmitStmt( tryStmt ) ; Return
		
		Local throwStmt:=Cast<ThrowStmt>( stmt )
		If throwStmt EmitStmt( throwStmt ) ; Return
		
		Local printStmt:=Cast<PrintStmt>( stmt )
		If printStmt EmitStmt( printStmt ) ; Return
		
		Throw New TransEx( "Translator_CPP.EmitStmt() Stmt '"+String.FromCString( stmt.typeName() )+"' not recognized" )
	End
	
	Method EmitStmt( stmt:PrintStmt )

		Emit( "bb_print("+Trans( stmt.value )+");" )
	End
	
	Method EmitStmt( stmt:ExitStmt )
	
		Emit( "break;" )
	End
	
	Method EmitStmt( stmt:ContinueStmt )
	
		Emit( "continue;" )
	End
	
	Method EmitStmt( stmt:ReturnStmt )
	
		If Not stmt.value Emit( "return;" ) ; Return
		
		Emit( "return "+Trans( stmt.value )+";" )
	End
	
	Method EmitStmt( stmt:VarDeclStmt )
		
		Local vvar:=stmt.varValue
		Local vdecl:=vvar.vdecl
		
		Refs( vvar.type )
		
		Local tvar:=""
		
		If vdecl.kind="local" And IsGCType( vvar.type )
		
			tvar=InsertGCTmp( vvar )

			If vvar.init Emit( tvar+"="+Trans( vvar.init )+";" )

		Else
		
			tvar=VarName( vvar )
			
			Local type:=VarType( vvar )
			If vdecl.kind="global" Or vdecl.kind="const" type="static "+type
			
			Local init:="{}"
			If vvar.init init="="+Trans( vvar.init )
			
			Emit( type+" "+tvar+init+";" )
			
		Endif
		
		If debug And vdecl.kind="local" Emit( "bbDBLocal(~q"+vvar.vdecl.ident+"~q,&"+tvar+");" )

	End
	
	Method EmitStmt( stmt:AssignStmt )
	
		Local op:=stmt.op
		Select op
		Case "~=" op="^="
		Case "mod=" op="%="
		Case "shl=" op="<<="
		Case "shr=" op=">>="
		Case "="
			Local vvar:=Cast<VarValue>( stmt.lhs )
			If vvar And vvar.vdecl.kind="param" FindGCTmp( vvar )
		End
		
		Local lhs:=Trans( stmt.lhs )
		Local rhs:=Trans( stmt.rhs )
		
		Uses( stmt.lhs.type )

		Emit( lhs+op+rhs+";" )
	End

	Method EmitStmt( stmt:EvalStmt )
	
		Emit( Trans( stmt.value )+";" )
	End
	
	Method EmitStmt( stmt:IfStmt )
	
		Emit( "if("+Trans( stmt.cond )+"){" )
		
		EmitBlock( stmt.block )
		
		While stmt.succ
		
			stmt=stmt.succ
			
			If stmt.cond
				Local db:=DebugInfo( stmt )
				If db db+=","
				Emit( "}else if("+db+Trans( stmt.cond )+"){" )
			Else
				Emit( "}else{" )
				EmitDebugInfo( stmt )
			Endif
			
			EmitBlock( stmt.block )
		Wend

		Emit( "}" )
	End
	
	Method EmitStmt( stmt:SelectStmt )
	
		Local tvalue:=Trans( stmt.value ),head:=True
		
		For Local cstmt:=Eachin stmt.cases
		
			If cstmt.values
				Local cmps:=""
				For Local value:=Eachin cstmt.values
					If cmps cmps+="||"
					cmps+=tvalue+"=="+Trans( value )
				Next
				cmps="if("+cmps+"){"
				If Not head cmps="}else "+cmps
				Emit( cmps )
			Else
				Emit( "}else{" )
			Endif
			head=False
			
			EmitBlock( cstmt.block )
		Next
		
		Emit( "}" )
	End
	
	Method EmitStmt( stmt:WhileStmt )
	
		If debug
			Emit( "{" )
			Emit( "bbDBLoop db_loop;" )
		Endif
	
		Emit( "while("+Trans( stmt.cond )+"){" )
		
		EmitBlock( stmt.block )
		
		Emit( "}" )
		
		If debug Emit( "}" )
	End
	
	Method EmitStmt( stmt:RepeatStmt )
	
		If debug
			Emit( "{" )
			Emit( "bbDBLoop db_loop;" )
		Endif
	
	
		If stmt.cond Emit( "do{" ) Else Emit( "for(;;){" )
		
		EmitBlock( stmt.block )
		
		If stmt.cond Emit( "}while(!("+Trans( stmt.cond )+"));" ) Else Emit( "}" )
		
		If debug Emit( "}" )
	End
	
	Method EmitStmt( stmt:ForStmt )
	
		Emit( "{" )
		BeginGCFrame()
		If debug Emit( "bbDBLoop db_loop;" )
	
		EmitStmts( stmt.iblock )
		
		Local cond:=Trans( stmt.cond )
		
		If stmt.incr

			EmitStmt( stmt.incr )
			Local incr:=_buf.Pop().Trim().Slice( 0,-1 )

			Emit( "for(;"+cond+";"+incr+"){" )
		Else
			Emit( "while("+cond+"){" )
		Endif
		
		EmitBlock( stmt.block )
		
		Emit( "}" )
		
		EndGCFrame()
		Emit( "}" )
	End
	
	Method EmitStmt( stmt:TryStmt )
	
		Emit( "try{" )

		EmitBlock( stmt.block )
		
		For Local cstmt:=Eachin stmt.catches
		
			Local vvar:=cstmt.vvar
		
			Uses( vvar.type )
			
			If IsGCType( vvar.type )
			
				Emit( "}catch("+TransType( vvar.type )+" ex){" )
				
				BeginBlock()
				
				Local tmp:=InsertGCTmp( vvar )
				
				Emit( tmp+"=ex;" )
				
				EmitStmts( cstmt.block )
				
				EndBlock()
			Else
			
				Emit( "}catch("+VarProto( vvar )+"){" )
				
				EmitBlock( cstmt.block )

			Endif
			
		Next
		
		Emit( "}" )
	End
	
	Method EmitStmt( stmt:ThrowStmt )
		If stmt.value Emit( "throw "+Trans( stmt.value )+";" ) Else Emit( "throw;" )
	End
	
	'***** Value *****
	
	Method Trans:String( value:Value ) Override
	
		Local upCastValue:=Cast<UpCastValue>( value )
		If upCastValue Return Trans( upCastValue )
		
		Local explicitCastValue:=Cast<ExplicitCastValue>( value )
		If explicitCastValue Return Trans( explicitCastValue )
	
		Local literalValue:=Cast<LiteralValue>( value )
		If literalValue Return Trans( literalValue )
		
		Local selfValue:=Cast<SelfValue>( value )
		If selfValue Return Trans( selfValue )
		
		Local superValue:=Cast<SuperValue>( value )
		If superValue Return Trans( superValue )
		
		Local invokeValue:=Cast<InvokeValue>( value )
		If invokeValue Return Trans( invokeValue )
		
		Local memberVarValue:=Cast<MemberVarValue>( value )
		If memberVarValue Return Trans( memberVarValue )
		
		Local memberFuncValue:=Cast<MemberFuncValue>( value )
		If memberFuncValue Return Trans( memberFuncValue )
		
		Local newObjectValue:=Cast<NewObjectValue>( value )
		If newObjectValue Return Trans( newObjectValue )
		
		Local newArrayValue:=Cast<NewArrayValue>( value )
		If newArrayValue Return Trans( newArrayValue )
		
		Local arrayIndexValue:=Cast<ArrayIndexValue>( value )
		If arrayIndexValue Return Trans( arrayIndexValue )
		
		Local stringIndexValue:=Cast<StringIndexValue>( value )
		If stringIndexValue Return Trans( stringIndexValue )
		
		Local pointerIndexValue:=Cast<PointerIndexValue>( value )
		If pointerIndexValue Return Trans( pointerIndexValue )
		
		Local unaryopValue:=Cast<UnaryopValue>( value )
		If unaryopValue Return Trans( unaryopValue )

		Local binaryopValue:=Cast<BinaryopValue>( value )
		If binaryopValue Return Trans( binaryopValue )
		
		Local ifThenElseValue:=Cast<IfThenElseValue>( value )
		If ifThenElseValue Return Trans( ifThenElseValue )
		
		Local pointerValue:=Cast<PointerValue>( value )
		If pointerValue Return Trans( pointerValue )
		
		Local funcValue:=Cast<FuncValue>( value )
		If funcValue Return Trans( funcValue )
		
		Local varValue:=Cast<VarValue>( value )
		If varValue Return Trans( varValue )
		
		Return "{* "+value.ToString()+" "+String.FromCString( value.typeName() )+" *}"
	End
	
	Method Trans:String( value:UpCastValue )
	
		Uses( value.type )
	
'		Local ctype:=TCast<ClassType>( value.value.type )
'		If ctype Uses( ctype )

		Local t:="("+Trans( value.value )+")"
		
		If IsValue( value.type ) Return TransType( value.type )+t

		Return "(("+TransType( value.type )+")"+t+")"
	End
	
	Method Trans:String( value:ExplicitCastValue )
	
		Uses( value.type )
	
		Local ctype:=TCast<ClassType>( value.type )
		If ctype 
'			Uses( ctype )
			Return "bb_object_cast<"+ClassName( ctype )+"*>("+Trans( value.value )+")"
		Endif
		
		Local t:="("+Trans( value.value )+")"
		
		If IsValue( value.type ) Return TransType( value.type )+t

		Return "(("+TransType( value.type )+")"+t+")"
	End
	
	Method TransNull:String( type:Type )
	
		Local ptype:=TCast<PrimType>( type )
		If ptype
			If ptype.IsIntegral Return "0"
			If ptype=Type.FloatType Return ".0f"
			If ptype=Type.DoubleType Return "0.0f"
			If ptype=Type.BoolType Return "false"
		Endif
		
		Refs( type )

		Local etype:=TCast<EnumType>( type )
		If etype Return EnumName( etype )+"(0)"

		If IsValue( type ) Return TransType( type )+"{}"
		
		Return "(("+TransType( type )+")0)"
	End

	Method Trans:String( value:LiteralValue )
	
		If Not value.value Return TransNull( value.type )
		
		Local ptype:=TCast<PrimType>( value.type )
		Select ptype
		Case Type.FloatType,Type.DoubleType
			Local t:=value.value
			If t.Find( "." )=-1 And t.Find( "e" )=-1 And t.Find( "E" )=-1 t+=".0"
			If ptype=Type.FloatType Return t+"f"
			Return t
		Case Type.StringType
			Return "BB_T("+EnquoteCppString( value.value )+")"
		End
		
		Refs( value.type )
		
		Local etype:=TCast<EnumType>( value.type )
		If etype Return EnumValueName( etype,value.value )
		
		If value.value="0" Return TransType( value.type )+"(0)"
		
		Return value.value
	End
	
	Method Trans:String( value:SelfValue )
	
		If value.func.IsExtension Return "l_self"
		
		If value.ctype.IsStruct Return "(*this)"
		
		Return "this"
	End
	
	Method Trans:String( value:SuperValue )
	
		Uses( value.ctype )
		
		Local cname:=ClassName( value.ctype )
		
		If IsStruct( value.ctype ) Return "(*static_cast<"+cname+"*>(this))"
		
		Return "static_cast<"+cname+"*>(this)"
	End
	
	Method TransMember:String( instance:Value,member:Value )
	
		Uses( instance.type )
		
		Local supr:=Cast<SuperValue>( instance )
		If supr Return ClassName( supr.ctype )+"::"+Trans( member )
		
		Local tinst:=Trans( instance )
		Local tmember:=Trans( member )

		If IsValue( instance.type ) Return tinst+"."+tmember
		
		If Cast<FuncValue>( member ) And IsVolatile( instance ) tinst="("+AllocGCTmp( instance.type )+"="+tinst+")"
		
		Return tinst+"->"+tmember
	End
	
	Method TransInvokeMember:String( instance:Value,member:FuncValue,args:Value[] )

		Uses( instance.type )
	
		If member.IsExtension
			
			Local tinst:=Trans( instance )
			
			If member.selfType.IsStruct
				If Not instance.IsLValue tinst="("+AllocGCTmp( instance.type )+"="+tinst+")"
			Else
				If IsVolatile( instance ) tinst="("+AllocGCTmp( instance.type )+"="+tinst+")"
			Endif
			
			If args tinst+=","
				
			Return Trans( member )+"("+tinst+TransArgs( args )+")"
		Endif
			
		Return TransMember( instance,member )+"("+TransArgs( args )+")"
	End
	
	Method Trans:String( value:InvokeValue )
	
		Local mfunc:=Cast<MemberFuncValue>( value.value )
		
		If mfunc Return TransInvokeMember( mfunc.instance,mfunc.member,value.args )
		
		Return Trans( value.value )+"("+TransArgs( value.args )+")"
	End

	Method Trans:String( value:MemberVarValue )
	
		Return TransMember( value.instance,value.member )
	End

	Method Trans:String( value:MemberFuncValue )

		Local ctype:=value.member.cscope.ctype
		
		Uses( ctype )

		Local cname:=ClassName( ctype )
		
		Return "bbMethod(("+cname+"*)("+Trans( value.instance )+"),&"+cname+"::"+Trans( value.member )+")"
	End
	
	Method Trans:String( value:NewObjectValue )
	
		Local ctype:=value.ctype
		
		Local cname:=ClassName( ctype )
		Uses( ctype )
	
		If ctype.ExtendsVoid
			Return "new "+cname+"("+TransArgs( value.args )+")"
		Endif
		
		If IsStruct( ctype )
			If Not value.args Return cname+"(bbNullCtor)"
			If value.args[0].type.Equals( ctype ) Return cname+"("+TransArgs( value.args )+",bbNullCtor)"
			Return cname+"("+TransArgs( value.args )+")"
		Endif
		
		Return "bbGCNew<"+cname+">("+TransArgs( value.args )+")"
	End
	
	Method Trans:String( value:NewArrayValue )
	
		Local atype:=value.atype
		Uses( atype )
	
		If value.inits Return ArrayName( atype )+"::create({"+TransArgs( value.inits )+"},"+value.inits.Length+")"
		
		Return ArrayName( atype )+"::create("+TransArgs( value.sizes )+")"
	End
	
	Method Trans:String( value:ArrayIndexValue )
		Return Trans( value.value )+"->at("+TransArgs( value.args )+")"
	End
	
	Method Trans:String( value:StringIndexValue )
		Return Trans( value.value )+"["+Trans( value.index )+"]"
	End
	
	Method Trans:String( value:PointerIndexValue )
		Return Trans( value.value )+"["+Trans( value.index )+"]"
	End

	Method Trans:String( value:UnaryopValue )
		Local op:=value.op
		Select op
		Case "not" op="!"
		End
		
		Local etype:=TCast<EnumType>( value.type )

		Local t:=Trans( value.value )

		If etype t="int("+t+")"
		
		t=op+t
		
		If etype t=EnumName( etype )+"("+t+")"
		
		Return t
	End
	
	Method Trans:String( value:BinaryopValue )
		Local op:=value.op
		Select op
		Case "<=>"
 
			Return "bbCompare("+Trans( value.lhs )+","+Trans( value.rhs )+")"
			
		Case "=","<>","<",">","<=",">="
		
			If op="=" op="==" Else If op="<>" op="!="
			
			If IsStruct( value.lhs.type ) Or (TCast<FuncType>( value.lhs.type ) And op<>"==" And op<>"!=" )
				Return "(bbCompare("+Trans( value.lhs )+","+Trans( value.rhs )+")"+op+"0)"
			Endif
			
		Case "mod"
		
			Local ptype:=TCast<PrimType>( value.type )
			If ptype=Type.FloatType Or ptype=Type.DoubleType Return "std::fmod("+Trans( value.lhs )+","+Trans( value.rhs )+")"
			
			op="%"
		Case "and" op="&&"
		Case "or" op="||"
		Case "~" op="^"
		Case "shl" op="<<"
		Case "shr" op=">>"
		End
		
		Local etype:=TCast<EnumType>( value.type )

		Local lhs:=Trans( value.lhs )
		Local rhs:=Trans( value.rhs )
		
		If etype lhs="int("+lhs+")" ; rhs="int("+rhs+")"
		
		Local t:="("+lhs+op+rhs+")"
		
		If etype t=EnumName( etype )+"("+t+")"
		
		Return t
	End
	
	Method Trans:String( value:IfThenElseValue )
		Return "("+Trans( value.value )+" ? "+Trans( value.thenValue )+" : "+Trans( value.elseValue )+")"
	End
	
	Method Trans:String( value:PointerValue )

		Return "&"+Trans( value.value )
	End
	
	Method Trans:String( value:FuncValue )
	
		Refs( value )
	
		If value.fdecl.kind="lambda" 
			Return EmitLambda( value )
		Endif
		
		Return FuncName( value )
	End
	
	Method Trans:String( value:VarValue )
	
		Refs( value )
	
		Local vdecl:=value.vdecl
		
		If (vdecl.kind="local" Or vdecl.kind="param") And IsGCType( value.type )
			Return FindGCTmp( value )
		Endif

		Return VarName( value )
	End
	
	'***** Args *****
	
	Method IsVolatile:Bool( arg:Value )
	
		Return IsGCType( arg.type ) And arg.HasSideEffects
	End
		
	Method TransArgs:String( args:Value[] )
	
		Local targs:=""
		
		For Local arg:=Eachin args
		
			Local t:=Trans( arg )
			
			If IsVolatile( arg )
				If _gcframe
					t=AllocGCTmp( arg.type )+"="+t
				Else
					t="bbGC::tmp("+t+")"
					_gctmps+=1
				Endif
			Endif
			
			If targs targs+=","
			targs+=t
		Next
		
		Return targs
	End
	
	'***** Type *****
	
	Method TransType:String( type:Type ) Override
	
		If TCast<VoidType>( type ) Return "void"
	
		Local classType:=TCast<ClassType>( type )
		If classType Return TransType( classType )
		
		Local enumType:=TCast<EnumType>( type )
		If enumType Return TransType( enumType )
	
		Local primType:=TCast<PrimType>( type )
		If primType Return TransType( primType )
		
		Local funcType:=TCast<FuncType>( type )
		If funcType Return TransType( funcType )
		
		Local arrayType:=TCast<ArrayType>( type )
		If arrayType Return TransType( arrayType )
		
		Local pointerType:=TCast<PointerType>( type )
		If pointerType Return TransType( pointerType )
		
		Local genArgType:=TCast<GenArgType>( type )
		If genArgType Return TransType( genArgType )
		
		Throw New TransEx( "Translator_CPP.Trans() Type '"+String.FromCString( type.typeName() )+"' not recognized" )
	End
	
	Method TransType:String( type:ClassType )
		If IsStruct( type ) Return ClassName( type )
		Return ClassName( type )+"*"
	End
	
	Method TransType:String( type:EnumType )
		Return EnumName( type )
	End
	
	Method TransType:String( type:PrimType )
		Return type.ctype.cdecl.symbol
	End
	
	Method TransType:String( type:FuncType )
		Return "bbFunction<"+CFuncType( type )+">"
	End
	
	Method TransType:String( type:ArrayType )
		Return ArrayName( type )+"*"
	End
	
	Method TransType:String( type:PointerType )
		Return TransType( type.elemType )+"*"
	End
	
	Method TransType:String( type:GenArgType )
		Return type.ToString()
	End
	
	Method ArrayName:String( type:ArrayType )
		Refs( type )
		If type.rank=1 Return "bbArray<"+ElementType( type.elemType )+">"
		Return "bbArray<"+ElementType( type.elemType )+","+type.rank+">"
	End
	
End
