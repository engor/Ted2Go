
Namespace mx2

Class Translator_CPP Extends Translator

	Field _lambdaId:Int
	
	Method Translate( fdecl:FileDecl ) Override
	
		_incs[fdecl.ident]=fdecl

		'***** Emit header file *****
		
		_buf.Clear()
		
		EmitBr()
		Emit( "#ifndef MX2_"+fdecl.ident.ToUpper()+"_H" )
		Emit( "#define MX2_"+fdecl.ident.ToUpper()+"_H" )
		EmitBr()
		Emit( "#include <bbmonkey.h>" )
		
		If fdecl.exhfile
			Emit( "#include ~q"+MakeRelativePath( fdecl.exhfile,ExtractDir( fdecl.hfile ) )+"~q" )
		End
		
		For Local imp:=Eachin fdecl.imports
		
			If imp.Contains( "*.h" ) Continue
		
			If imp.EndsWith( ".h>" )
				Emit( "#include "+imp )
				Continue
			Endif
			
			If imp.EndsWith( ".h" )
				Local path:=ExtractDir( fdecl.path )+imp
				Emit( "#include ~q"+MakeRelativePath( path,ExtractDir( fdecl.hfile ) )+"~q" )
				Continue
			Endif
			
		Next			
		
		BeginDeps()
		
		Emit( "// ***** Internal *****" )
		
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
		
		EndDeps()
		
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
			Emit( VarProto( vvar )+";" )
		Next
		
		For Local func:=Eachin fdecl.functions
			EmitFunc( func )
		Next
		
		For Local ctype:=Eachin fdecl.classes
			EmitClassMembers( ctype )
		Next
		
		EmitGlobalInits( fdecl )
		
		EndDeps()
		
		EmitBr()
		
		CSaveString( _buf.Join( "~n" ),fdecl.cfile )
	End
	
	'***** Decls *****
	
	Method VarType:String( type:Type )
	
		Local ctype:=Cast<ClassType>( type )
		If ctype And IsGCType( ctype ) Return "bbGCVar<"+ClassName( ctype )+">"
		
		Local atype:=Cast<ArrayType>( type )
		If atype Return "bbGCVar<"+ArrayName( atype )+">"
		
		Return Trans( type )
	End
	
	Method VarProto:String( vvar:VarValue ) Override
	
		Return VarType( vvar.type )+" "+VarName( vvar )
	End
	
	Method FuncProto:String( func:FuncValue ) Override

		Return FuncProto( func,True )
	End
	
	Method FuncProto:String( func:FuncValue,header:Bool )

		Local fdecl:=func.fdecl
		Local ftype:=func.ftype
		Local ctype:=func.scope.FindClass()
	
		Local retType:=""
		If Not func.IsCtor retType=Trans( ftype.retType )+" "

		Local params:=""
		If func.IsExtension params=Trans( ctype )+" l_self"

		For Local p:=Eachin func.params
			If params params+=","
			params+=Trans( p.type )+" "+VarName( p )
		Next
		
		Local ident:=FuncName( func )
		If Not header And fdecl.kind="method" And Not func.IsExtension ident=ClassName( ctype )+"::"+ident
		
		Local proto:=retType+ident+"("+params+")"
		
		If header And func.IsMethod And Not func.IsExtension
			If fdecl.IsAbstract Or fdecl.IsVirtual Or ctype.IsVirtual
				proto="virtual "+proto
				If fdecl.IsAbstract proto+="=0"
			Endif
		Endif
		
		Return proto
	End
	
	Method EmitGlobalInits( fdecl:FileDecl )
	
		Local gcFrame:=""		
		For Local vvar:=Eachin fdecl.globals
			If Not IsGCType( vvar.type ) Continue
			gcFrame="mx2_"+fdecl.ident+"_root"
			Exit
		Next
		
		If gcFrame
			EmitBr()
			Emit( "struct "+gcFrame+" : public bbGCRoot{" )
			Emit( "void gcMark(){" )
			For Local vvar:=Eachin fdecl.globals
				If Not IsGCType( vvar.type ) Continue
				Emit( "bbGCMark("+Trans( vvar )+");" )
			Next
			Emit( "}" )
			Emit( "};" )
		Endif
		
'		In case something get stripped...
'		Emit( "extern bbInit mx2_"+fdecl.ident+"_init;" )

		EmitBr()
		Emit( "void mx2_"+fdecl.ident+"_init(){" )
		BeginGCFrame()
		Emit( "static bool done;" )
		Emit( "if(done) return;" )
		Emit( "done=true;")
		If gcFrame Emit( "new "+gcFrame+";" )
		
'		Emit( "(void)mx2_"+fdecl.ident+"_init;" )

		For Local vvar:=Eachin fdecl.globals
			If vvar.init Emit( Trans( vvar )+"="+Trans( vvar.init )+";" )
		Next
		EndGCFrame()
		Emit( "}" )
		
		EmitBr()
		Emit( "bbInit mx2_"+fdecl.ident+"_init_v(~q"+fdecl.ident+"~q,&mx2_"+fdecl.ident+"_init);" )
	
	End
	
	Method EmitClassProto( ctype:ClassType,fdecl:FileDecl,emitted:StringMap<Bool> )
	
		Local insPos:=InsertPos
		
		EmitClassProto( ctype )
		
		emitted[ClassName( ctype )]=True
	
		For Local ctype2:=Eachin _usesTypes.Values
		
			If ctype2.transFile<>fdecl Or emitted[ClassName( ctype2 )] Continue
			
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
			
		Case "interface"
		
			If Not ctype.ifaceTypes xtends="public bbInterface"
			
		Case "struct"
		
		End
		
		If cdecl.kind<>"struct"
			For Local iface:=Eachin ctype.ifaceTypes
				Uses( iface )
				If xtends xtends+=","
				xtends+="public virtual "+ClassName( iface )
			Next
		Endif
		
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
					If Not func.IsMethod Or func.scope<>ctype.superType.scope Continue
					Local sym:=FuncName( func )
					If done[sym] Continue
					done[sym]=True
					Emit( "using "+superName+"::"+sym+";" )
				Next
			Next
		Endif
		
		Emit( "const char *typeName(){return~q"+cname+"~q;}" )
		
		'Emit fields...
		'
		Local needsInit:=False
		Local needsMark:=False

		EmitBr()		
		For Local node:=Eachin ctype.scope.transMembers
			Local vvar:=Cast<VarValue>( node )
			If Not vvar Continue
			
			Refs( vvar.type )

			If IsGCType( vvar.type ) needsMark=True
			
			If Cast<LiteralValue>( vvar.init )
				Emit( VarProto( vvar )+"="+Trans( vvar.init )+";" )
			Else
				Emit( VarProto( vvar )+"{};" )
				If vvar.init needsInit=True
			Endif

		Next

		If needsInit
		
			EmitBr()
			Emit( "void init();" )
			
		Endif
		
		If needsMark And cdecl.kind="class"
		
			EmitBr()
			Emit( "void gcMark();" )
			
		Endif

		'Emit ctor methods
		'
		Local hasCtor:=False
		Local hasDefaultCtor:=False
		
		EmitBr()
		For Local node:=Eachin ctype.scope.transMembers
			Local func:=Cast<FuncValue>( node )
			If Not func Or func.fdecl.ident<>"new" Continue
			
			hasCtor=True
			If Not func.ftype.argTypes hasDefaultCtor=True
			
			Refs( func.ftype )
			Emit( FuncProto( func,true )+";" )
		Next
		
		'Emit non-ctor methods
		'
		Local hasCmp:=False
		
		EmitBr()
		For Local node:=Eachin ctype.scope.transMembers
			Local func:=Cast<FuncValue>( node )
			If Not func Or func.fdecl.ident="new" Continue
			
			If func.fdecl.ident="<=>" hasCmp=True
			
			Refs( func.ftype )
			Emit( FuncProto( func,True )+";" )
		Next
		
		'Emit default ctor
		'		
		If Not hasDefaultCtor
			EmitBr()
			Emit( cname+"(){" )
			If needsInit Emit( "init();" )
			Emit( "}" )
		End
		
		Emit( "};" )
		
		If IsStruct( ctype )

			EmitBr()
			If hasCmp
				Emit( "inline int bbCompare("+cname+"&x,"+cname+"&y){return x.m__cmp(y);}" )
			Else
				Emit( "int bbCompare("+cname+"&x,"+cname+"&y);" )
			Endif
		
			If needsMark
				EmitBr()
				Emit( "void bbGCMark(const "+ClassName( ctype )+"&);" )
			Endif
			
		Endif
		
	End
	
	Method EmitClassMembers( ctype:ClassType )
	
		Local cdecl:=ctype.cdecl
		Local cname:=ClassName( ctype )
	
		'Emit fields...
		'
		Local needsInit:=False
		Local needsMark:=False

		EmitBr()		
		For Local node:=Eachin ctype.scope.transMembers
			Local vvar:=Cast<VarValue>( node )
			If Not vvar Continue
			
			If IsGCType( vvar.type ) needsMark=True
			If vvar.init And Not Cast<LiteralValue>( vvar.init ) needsInit=True
		Next
		
		'Emit init() method
		'
		If needsInit

			EmitBr()
			Emit( "void "+cname+"::init(){" )
			
			BeginGCFrame()
			
			For Local node:=Eachin ctype.scope.transMembers
				Local vvar:=Cast<VarValue>( node )
				If Not vvar Or Not vvar.init Or Cast<LiteralValue>( vvar.init ) Continue
				
				Emit( Trans( vvar )+"="+Trans( vvar.init )+";" )
			Next
			
			EndGCFrame()

			Emit( "}" )
		
		Endif
		
		'Emit virtual gcMark() for class
		'
		If needsMark And ctype.cdecl.kind="class"
		
			EmitBr()
			Emit( "void "+cname+"::gcMark(){" )
			
			If ctype.superType And ctype.superType<>Type.ObjectClass
				Emit( ClassName( ctype.superType )+"::gcMark();" )
			End
		
			For Local node:=Eachin ctype.scope.transMembers
				Local vvar:=Cast<VarValue>( node )
				If Not vvar Or Not IsGCType( vvar.type ) Continue
				
				Uses( vvar.type )
				Emit( "bbGCMark("+VarName( vvar )+");" )
			Next
			
			Emit( "}" )
			
		Endif
	
		'Emit ctor methods
		'
		For Local node:=Eachin ctype.scope.transMembers
			Local func:=Cast<FuncValue>( node )
			If Not func Or func.fdecl.ident<>"new" Continue
			
			EmitBr()
			EmitFunc( func,needsInit )
		Next
		
		'Emit non-ctor methods
		'
		Local hasCmp:=False
		
		For Local node:=Eachin ctype.scope.transMembers
			Local func:=Cast<FuncValue>( node )
			If Not func Or func.fdecl.ident="new" Continue
			
			If func.fdecl.ident="<=>" 
				hasCmp=True
			Endif

			EmitBr()
			EmitFunc( func )
		Next
		
		'Emit static struct methods
		'
		If IsStruct( ctype ) 

			If Not hasCmp
				EmitBr()
				Emit( "int bbCompare("+cname+"&x,"+cname+"&y){" )
				For Local node:=Eachin ctype.scope.transMembers
					Local vvar:=Cast<VarValue>( node )
					If Not vvar Continue
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
	
				For Local node:=Eachin ctype.scope.transMembers
					Local vvar:=Cast<VarValue>( node )
					If Not vvar Or Not IsGCType( vvar.type ) Continue
					
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
		End
		
		EmitBr()
		
		Emit( proto+"{" )
		
		If init Emit( "init();" )
		
		'is it 'main'?
		Local module:=func.scope.FindFile().fdecl.module
		
		If func=module.main
		
			Emit( "static bool done;" )
			Emit( "if(done) return;" )
			Emit( "done=true;" )
			
			Local builder:=Builder.instance
			For Local dep:=Eachin module.moduleDeps
			
				Local mod2:=builder.modulesMap[dep]
				If Not mod2.main Continue
				
				Emit( "void mx2_"+mod2.ident+"_main();mx2_"+mod2.ident+"_main();" )
			Next
		Endif
	
		Emit( func.block )
		
		Emit( "}" )
	End
	
	Method EmitLambda:String( func:FuncValue )
	
		Local ident:String="lambda"+_lambdaId
		_lambdaId+=1
		
		Local bbtype:="bbFunction<"+CFuncType( func.ftype )+">"
		
		Emit( "struct "+ident+" : public "+bbtype+"::Rep{" )
		
		Local ctorArgs:="",ctorInits:="",ctorVals:=""
		
		For Local vvar:=Eachin func.captures
			Local varty:=Trans( vvar.type )
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
		
		Local retType:=Trans( func.ftype.retType )

		Local params:=""
		For Local p:=Eachin func.params
			If params params+=","
			params+=Trans( p.type )+" "+VarName( p )
		Next
		
		Emit( retType+" invoke("+params+"){" )
		
		Emit( func.block )
		
		Emit( "}" )

		Emit( "void gcMark(){" )
		For Local vvar:=Eachin func.captures
			If IsGCType( vvar.type ) 
				Uses( vvar.type )
				Emit( "bbGCMark("+VarName( vvar )+");" )
			Endif
		Next
		Emit( "}" )
		
		Emit( "};" )
		
		Return bbtype+"(new "+ident+ctorVals+")"
	End
	
	'***** Block *****
	
	Method Emit( block:Block,gc:Bool=True )
	
		If gc BeginGCFrame( block )
		
		For Local stmt:=Eachin block.stmts
		
			Emit( stmt )
			FreeGCTmps()
			
		Next
		
		If gc EndGCFrame()
	End
	
	'***** Stmt *****
	
	Method Emit( stmt:Stmt )
	
		If Not stmt Return
	
		Local exitStmt:=Cast<ExitStmt>( stmt )
		If exitStmt Emit( exitStmt ) ; Return
		
		Local continueStmt:=Cast<ContinueStmt>( stmt )
		If continueStmt Emit( continueStmt ) ; Return
		
		Local returnStmt:=Cast<ReturnStmt>( stmt )
		If returnStmt Emit( returnStmt ) ; Return
		
		Local varDeclStmt:=Cast<VarDeclStmt>( stmt )
		If varDeclStmt Emit( varDeclStmt ) ; Return
		
		Local assignStmt:=Cast<AssignStmt>( stmt )
		If assignStmt Emit( assignStmt ) ; Return
		
		Local evalStmt:=Cast<EvalStmt>( stmt )
		If evalStmt Emit( evalStmt ) ; Return
		
		Local ifStmt:=Cast<IfStmt>( stmt )
		If ifStmt Emit( ifStmt ) ; Return
		
		Local whileStmt:=Cast<WhileStmt>( stmt )
		If whileStmt Emit( whileStmt ) ; Return
		
		Local repeatStmt:=Cast<RepeatStmt>( stmt )
		If repeatStmt Emit( repeatStmt ) ; Return
		
		Local selectStmt:=Cast<SelectStmt>( stmt )
		If selectStmt Emit( selectStmt ) ; Return
		
		Local forStmt:=Cast<ForStmt>( stmt )
		If forStmt Emit( forStmt ) ; Return
		
		Local tryStmt:=Cast<TryStmt>( stmt )
		If tryStmt Emit( tryStmt ) ; Return
		
		Local throwStmt:=Cast<ThrowStmt>( stmt )
		If throwStmt Emit( throwStmt ) ; Return
		
		Local printStmt:=Cast<PrintStmt>( stmt )
		If printStmt Emit( printStmt ) ; Return
		
		Throw New TransEx( "Translator_CPP.Emit() Stmt '"+String.FromCString( stmt.typeName() )+"' not recognized" )
	End
	
	Method Emit( stmt:PrintStmt )
	
		Emit( "puts("+Trans( stmt.value )+".c_str());fflush( stdout );" )
	End
	
	Method Emit( stmt:ExitStmt )
	
		Emit( "break;" )
	End
	
	Method Emit( stmt:ContinueStmt )
	
		Emit( "continue;" )
	End
	
	Method Emit( stmt:ReturnStmt )
	
		If Not stmt.value Emit( "return;" ) ; Return
		
		Emit( "return "+Trans( stmt.value )+";" )
	End
	
	Method Emit( stmt:VarDeclStmt )
		
		Local vvar:=stmt.varValue
		Local vdecl:=vvar.vdecl
		
		Refs( vvar.type )
		
		If vdecl.kind="local" And IsGCType( vvar.type )
		
			Local t:=InsertGCTmp( vvar )
			If vvar.init Emit( t+"="+Trans( vvar.init )+";" )
			Return

		Endif

		Local init:="{}"
		If vvar.init init="="+Trans( vvar.init )
		
		Emit( Trans( vvar.type )+" "+VarName( vvar )+init+";" )
	End
	
	Method Emit( stmt:AssignStmt )
	
		Local op:=stmt.op
		Select op
		Case "~=" op="^="
		Case "mod=" op="%="
		Case "shl=" op="<<="
		Case "shr" op=">>="
		Case "="
			Local vvar:=Cast<VarValue>( stmt.lhs )
			If vvar And vvar.vdecl.kind="param" FindGCTmp( vvar )
		End
		
		Local lhs:=Trans( stmt.lhs )
		Local rhs:=Trans( stmt.rhs )

		Local etype:=Cast<EnumType>( stmt.lhs.type )
		If etype And etype.edecl.IsExtern
			If op<>"="
				If stmt.lhs.HasSideEffects Print "Danger Will Robinson!!!!!!"
				rhs=lhs+op.Slice( 0,-1 )+rhs
				op="="
			Endif
			rhs=etype.edecl.symbol+"("+rhs+")"
		Endif
		
		Emit( lhs+op+rhs+";" )
	End

	Method Emit( stmt:EvalStmt )
		Emit( Trans( stmt.value )+";" )
	End
	
	Method Emit( stmt:IfStmt )
	
		Emit( "if("+Trans( stmt.cond )+"){" )
		
		Emit( stmt.block )
		
		While stmt.succ
			stmt=stmt.succ
			If stmt.cond
				Emit( "}else if("+Trans( stmt.cond )+"){" )
			Else
				Emit( "}else{" )
			Endif
			Emit( stmt.block )
		Wend

		Emit( "}" )
	End
	
	Method Emit( stmt:WhileStmt )
	
		Emit( "while("+Trans( stmt.cond )+"){" )
		
		Emit( stmt.block )
		
		Emit( "}" )
	End
	
	Method Emit( stmt:RepeatStmt )
	
		If stmt.cond Emit( "do{" ) Else Emit( "for(;;){" )
		
		Emit( stmt.block )
		
		If stmt.cond Emit( "}while(!("+Trans( stmt.cond )+"));" ) Else Emit( "}" )
	End
	
	Method Emit( stmt:SelectStmt )
	
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
			
			Emit( cstmt.block )
		Next
		
		Emit( "}" )
	End
	
	Method Emit( stmt:ForStmt )
	
		Emit( "{" )
		
		BeginGCFrame()
		
		Emit( stmt.iblock,False )
		
		Local cond:=Trans( stmt.cond )
		
		If stmt.incr

			Emit( stmt.incr )
			Local incr:=_buf.Pop().Trim().Slice( 0,-1 )

			Emit( "for(;"+cond+";"+incr+"){" )
		Else
			Emit( "while("+cond+"){" )
		Endif
		
		Emit( stmt.block,False )
		
		Emit( "}" )
		
		EndGCFrame()
		
		Emit( "}" )
	End
	
	Method Emit( stmt:TryStmt )
	
		Emit( "try{" )

		Emit( stmt.block )
		
		For Local cstmt:=Eachin stmt.catches
		
			Local vvar:=cstmt.vvar
		
			Uses( vvar.type )
			
			If IsGCType( vvar.type )
			
				Emit( "}catch("+Trans( vvar.type )+" ex){" )
				
				BeginGCFrame()
				
				Emit( InsertGCTmp( vvar )+"=ex;" )
				
				Emit( cstmt.block,False )
				
				EndGCFrame()
				
			Else
			
				Emit( "}catch("+VarProto( vvar )+"){" )
				
				Emit( cstmt.block )

			Endif
			
		Next
		
		Emit( "}" )
	End
	
	Method Emit( stmt:ThrowStmt )
	
		Emit( "throw "+Trans( stmt.value )+";" )
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
	
		Local ctype:=Cast<ClassType>( value.value.type )
		If ctype Uses( ctype )
		
		Local t:="("+Trans( value.value )+")"
		
		If IsValue( value.type ) Return Trans( value.type )+t

		Return "(("+Trans( value.type )+")"+t+")"
	End
	
	Method Trans:String( value:ExplicitCastValue )
	
		Local ctype:=Cast<ClassType>( value.type )
		If ctype 
			Uses( ctype )
			Return "bb_object_cast<"+ClassName( ctype )+"*>("+Trans( value.value )+")"
		Endif
		
		Local t:="("+Trans( value.value )+")"
		
		If IsValue( value.type ) Return Trans( value.type )+t

		Return "(("+Trans( value.type )+")"+t+")"
	End
	
	Method TransNull:String( type:Type )
	
		Local ptype:=Cast<PrimType>( type )
		If ptype
			If ptype.IsIntegral Return "0"
			If ptype=Type.FloatType Return ".0f"
			If ptype=Type.DoubleType Return "0.0f"
			If ptype=Type.BoolType Return "false"
		Endif

		Local etype:=Cast<EnumType>( type )
		If etype
			If etype.edecl.IsExtern Return etype.edecl.symbol+"(0)"
			Return "0"
		Endif
		
		If IsValue( type ) Return Trans( type )+"{}"
		
		Return "nullptr"
	End

	Method Trans:String( value:LiteralValue )
	
		If Not value.value Return TransNull( value.type )
		
		Select value.type
		Case Type.FloatType,Type.DoubleType
			Local t:=value.value
			If t.Find( "." )=-1 And t.Find( "e" )=-1 And t.Find( "E" )=-1 t+=".0"
			If value.type=Type.FloatType Return t+"f"
			Return t
		Case Type.StringType
			Return "BB_T("+EnquoteCppString( value.value )+")"
		End
		
		If value.value="0" Return Trans( value.type )+"(0)"
		
		Return value.value
	End
	
	Method Trans:String( value:SelfValue )
		If IsStruct( value.ctype ) Return "(*this)"
		Return "this"
	End
	
	Method Trans:String( value:SuperValue )
		Local type:=ClassName( value.ctype )
		If IsStruct( value.ctype ) Return "(*static_cast<"+type+"*>(this))"
		Return "static_cast<"+type+"*>(this)"
	End
	
	Method TransMember:String( instance:Value,member:Value )
	
		Local ctype:=Cast<ClassType>( instance.type )
		If ctype Uses( ctype )

		Local supr:=Cast<SuperValue>( instance )
		If supr Return ClassName( Cast<ClassType>( supr.type ) )+"::"+Trans( member )
		
		Local tinst:=Trans( instance )
		Local tmember:=Trans( member )

		If IsValue( instance.type ) Return tinst+"."+tmember
		
		If Cast<FuncValue>( member ) And IsVolatile( instance ) tinst="("+AllocGCTmp( instance.type )+"="+tinst+")"
		
		Return tinst+"->"+tmember
	End
	
	Method Trans:String( value:InvokeValue )
	
		Local mfunc:=Cast<MemberFuncValue>( value.value )
		
		If mfunc
		
			Local instance:=mfunc.instance
			Local member:=mfunc.member
			
			If member.IsExtension
			
				Refs( member )

				Local tinst:=Trans( instance )
				If IsVolatile( instance ) tinst="("+AllocGCTmp( instance.type )+"="+tinst+")"
				If value.args tinst+=","
				
				Return Trans( member )+"("+tinst+TransArgs( value.args )+")"
			Endif
			
			Return TransMember( instance,member )+"("+TransArgs( value.args )+")"
		Endif
		
		Return Trans( value.value )+"("+TransArgs( value.args )+")"
	End

	Method Trans:String( value:MemberVarValue )
	
		Return TransMember( value.instance,value.member )
	End

	Method Trans:String( value:MemberFuncValue )

		Local ctype:=value.member.scope.FindClass()
		Uses( ctype )

		Local cname:=ClassName( ctype )
		
		Return "bbMethod(("+cname+"*)("+Trans( value.instance )+"),&"+cname+"::"+Trans( value.member )+")"
	End
	
	Method Trans:String( value:NewObjectValue )
	
		Local ctype:=value.ctype
	
		Uses( ctype )
	
		If IsStruct( ctype ) Return ClassName( ctype )+"("+TransArgs( value.args )+")"
		
		If ctype.IsVoid Return "new "+ClassName( ctype )+"("+TransArgs( value.args )+")"
		
		Return "bbGCNew<"+ClassName( ctype )+">("+TransArgs( value.args )+")"
	End
	
	Method Trans:String( value:NewArrayValue )
	
		If value.inits Return ArrayName( value.atype )+"::create({"+TransArgs( value.inits )+"},"+value.inits.Length+")"
		
		Return ArrayName( value.atype )+"::create("+TransArgs( value.sizes )+")"
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
		
		Local t:=op+Trans( value.value )
		
		Local etype:=Cast<EnumType>( value.type )
		If etype And etype.edecl.IsExtern t=etype.edecl.symbol+t
		
		Return t
	End
	
	Method Trans:String( value:BinaryopValue )
		Local op:=value.op
		Select op
		Case "<=>" 
			Return "bbCompare("+Trans( value.lhs )+","+Trans( value.rhs )+")"
			
		Case "=","<>","<",">","<=",">="
		
			If op="=" op="==" Else If op="<>" op="!="
			
			If IsStruct( value.lhs.type ) Or (Cast<FuncType>( value.lhs.type ) And op<>"==" And op<>"!=" )
				Return "(bbCompare("+Trans( value.lhs )+","+Trans( value.rhs )+")"+op+"0)"
			Endif
			
		Case "mod"
			If value.type=Type.FloatType Or value.type=Type.DoubleType Return "std::fmod("+Trans( value.lhs )+","+Trans( value.rhs )+")"
			op="%"
		Case "and" op="&&"
		Case "or" op="||"
		Case "~" op="^"
		Case "shl" op="<<"
		Case "shr" op=">>"
		End
		
		Local t:="("+Trans( value.lhs )+op+Trans( value.rhs )+")"
		
		Local etype:=Cast<EnumType>( value.type )
		If etype And etype.edecl.IsExtern t=etype.edecl.symbol+t
		
		Return t
	End
	
	Method Trans:String( value:IfThenElseValue )
		Return Trans( value.value )+" ? "+Trans( value.thenValue )+" : "+Trans( value.elseValue )
	End
	
	Method Trans:String( value:PointerValue )

		Return "&"+Trans( value.value )
	End
	
	Method Trans:String( value:FuncValue )
	
		If value.fdecl.kind="lambda" 
			Refs( value.ftype )
			Return EmitLambda( value )
		Endif
		
		Refs( value )
		
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
	
		If Not IsGCType( arg.type ) Return False
		
'		If _gcframe Return True
		
		If arg.HasSideEffects Return True
		
		Return False
	End
		
	Method TransArgs:String( args:Value[] )
	
		Local targs:=""
		
		For Local arg:=Eachin args
		
			Local t:=Trans( arg )
			
			If IsVolatile( arg ) t=AllocGCTmp( arg.type )+"="+t
			
			If targs targs+=","
			targs+=t
		Next
		
		Return targs
	End
	
	'***** Type *****
	
	Method Trans:String( type:Type ) Override
	
		If type=Type.VoidType Return "void"
	
		Local classType:=Cast<ClassType>( type )
		If classType Return Trans( classType )
		
		Local enumType:=Cast<EnumType>( type )
		If enumType Return Trans( enumType )
	
		Local primType:=Cast<PrimType>( type )
		If primType Return Trans( primType )
		
		Local funcType:=Cast<FuncType>( type )
		If funcType Return Trans( funcType )
		
		Local arrayType:=Cast<ArrayType>( type )
		If arrayType Return Trans( arrayType )
		
		Local pointerType:=Cast<PointerType>( type )
		If pointerType Return Trans( pointerType )
		
		Local genArgType:=Cast<GenArgType>( type )
		If genArgType Return Trans( genArgType )
		
		Throw New TransEx( "Translator_CPP.Trans() Type '"+String.FromCString( type.typeName() )+"' not recognized" )
	End
	
	Method Trans:String( type:ClassType )
		If IsStruct( type ) Return ClassName( type )
		Return ClassName( type )+"*"
	End
	
	Method Trans:String( type:EnumType )
		If type.edecl.IsExtern Return type.edecl.symbol
		Return "bbInt"
	End
	
	Method Trans:String( type:PrimType )
		Return type.ctype.cdecl.symbol
	End
	
	Method Trans:String( type:FuncType )
		Return "bbFunction<"+CFuncType( type )+">"
	End
	
	Method Trans:String( type:ArrayType )
		Return ArrayName( type )+"*"
	End
	
	Method Trans:String( type:PointerType )
		Return Trans( type.elemType )+"*"
	End
	
	Method Trans:String( type:GenArgType )
		Return type.ToString()
	End
	
	Method ArrayName:String( type:ArrayType )
		Return "bbArray<"+VarType( type.elemType )+","+type.rank+">"
	End
	
End
