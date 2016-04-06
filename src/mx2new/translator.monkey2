
Namespace mx2

'Really only for c++ translator right now, but splits out some grunt work from main translator!

Function IsGCType:Bool( type:Type )

	If TCast<FuncType>( type ) Return True
	
	If TCast<ArrayType>( type ) Return True
	
	Local ctype:=TCast<ClassType>( type )
	If Not ctype Return False
	
	If ctype.IsVoid Return False
	
	If ctype.cdecl.kind="class" Or ctype.cdecl.kind="interface" Return True
	
	If ctype.cdecl.kind="struct" Return HasGCMembers( ctype.scope )
	
	Return False
End

Function HasGCMembers:Bool( scope:Scope )

	For Local node:=Eachin scope.transMembers
	
		Local varv:=Cast<VarValue>( node )
		If varv And IsGCType( varv.type ) Return True
	
	Next
	
	Return False
End
	
'Visitor that looks for gc params on LHS of an assignment.
'
Class AssignedGCParamsVisitor Extends StmtVisitor

	Field gcparams:=New StringMap<VarValue>
	
	Method Visit( stmt:AssignStmt ) Override
		Local vvar:=Cast<VarValue>( stmt.lhs )
		If vvar And vvar.vdecl.kind="param" And IsGCType( vvar.type ) gcparams[vvar.vdecl.ident]=vvar
	End

End

Class Translator

	Field debug:Bool
	
	Method New()
		Local builder:=Builder.instance
		Self.debug=builder.opts.config="debug"
	End
	
	Method Trans:String( value:Value ) Abstract
	
	Method TransType:String( type:Type ) Abstract

	Method VarProto:String( vvar:VarValue ) Abstract
	
	Method FuncProto:String( func:FuncValue ) Abstract

	'***** Emit *****
	
	Field _buf:=New StringStack
	Field _indent:String
	Field _insertStack:=New Stack<Stack<String>>
	
	Method EmitBr()
		If _buf.Length And Not _buf.Top Return
		_buf.Push( "" )
	End
	
	Method Emit( str:String )
	
		If Not str Return
	
		If str.StartsWith( "}" ) _indent=_indent.Slice( 0,-2 )

		_buf.Push( _indent+str )

		If str.EndsWith( "{" ) _indent+="  "
	End
	
	Property InsertPos:Int()
	
		Return _buf.Length
	End
	
	Method Slice:Stack<String>( pos:Int )
	
		Local buf:=_buf.Slice( pos )
		
		_buf.Resize( pos )
		
		Return buf
	End
	
	Method BeginInsert( pos:Int )
	
		Local buf:=_buf.Slice( pos )
	
		_insertStack.Push( buf )
		
		_buf.Resize( pos )
	End
	
	Method EndInsert()
	
		Local buf:=_insertStack.Pop()
		
		_buf.Append( buf )

	End
	
	'***** GCFrame *****
	
	Class GCTmp
		Field used:Bool
		Field type:Type
		Field ident:String
	End

	Class GCFrame
		Field outer:GCFrame
		Field inspos:Int
		Field depth:Int
		Field ident:String
		Field vars:=New StringMap<VarValue>
		Field tmps:=New Stack<GCTmp>
		
		Method New( outer:GCFrame,inspos:Int )
			Self.outer=outer
			Self.inspos=inspos
			If outer Self.depth=outer.depth+1
			ident="f"+depth
		End
	End
	
	Field _gcframe:GCFrame
	
	Method BeginGCFrame()

		_gcframe=New GCFrame( _gcframe,InsertPos )
	End
	
	Method BeginGCFrame( func:FuncValue )
	
		BeginGCFrame()
		
		Local visitor:=New AssignedGCParamsVisitor
		visitor.Visit( func.block )
		
		For Local it:=Eachin visitor.gcparams
			InsertGCTmp( it.Value )
		Next
		
	End
	
	Method EndGCFrame()
	
		If Not _gcframe.vars.Empty Or Not _gcframe.tmps.Empty
	
			BeginInsert( _gcframe.inspos )
			
			Emit( "struct "+_gcframe.ident+"_t : public bbGCFrame{" )
			
			Local ctorArgs:="",ctorInits:="",ctorVals:=""
			
			For Local varval:=Eachin _gcframe.vars.Values

				Local varty:=TransType( varval.type )
				Local varid:=VarName( varval )
			
				Emit( varty+" "+varid+"{};" )
				
				If varval.vdecl.kind="param"
					ctorArgs+=","+varty+" "+varid
					ctorInits+=","+varid+"("+varid+")"
					ctorVals+=","+varid
				Endif
				
			Next
			
			For Local tmp:=Eachin _gcframe.tmps
				Emit( TransType( tmp.type )+" "+tmp.ident+"{};" )
			Next
			
			If ctorArgs
				ctorVals="{"+ctorVals.Slice( 1 )+"}"
				Emit( _gcframe.ident+"_t("+ctorArgs.Slice( 1 )+"):"+ctorInits.Slice( 1 )+"{" )
				Emit( "}" )
			Else
				ctorVals="{}"
			Endif
			
			Emit( "void gcMark(){" )

			For Local vvar:=Eachin _gcframe.vars.Values
				Uses( vvar.type )
				Emit( "bbGCMark("+VarName( vvar )+");" )
			Next
			
			For Local tmp:=Eachin _gcframe.tmps
				Uses( tmp.type )
				Emit( "bbGCMark("+tmp.ident+");" )
			Next
			
			Emit( "}" )
			
			Emit( "}"+_gcframe.ident+ctorVals+";" )
	
			EndInsert()
			
		Endif
			
		_gcframe=_gcframe.outer
	End
	
	Method AllocGCTmp:String( type:Type )
	
		For Local i:=0 Until _gcframe.tmps.Length
			Local tmp:=_gcframe.tmps[i]
			If tmp.used Or Not tmp.type.Equals( type ) Continue
			tmp.used=True
			Return _gcframe.ident+"."+tmp.ident
		Next
		
		Local tmp:=New GCTmp
		tmp.used=True
		tmp.type=type
		tmp.ident="t"+_gcframe.tmps.Length
		_gcframe.tmps.Push( tmp )
		
		Return _gcframe.ident+"."+tmp.ident
	End
	
	Method FreeGCTmps()
		For Local i:=0 Until _gcframe.tmps.Length
			_gcframe.tmps[i].used=False
		Next
	End
	
	Method InsertGCTmp:String( vvar:VarValue )
	
		_gcframe.vars[vvar.vdecl.ident]=vvar
		Return _gcframe.ident+"."+VarName( vvar )
	End
	
	Method FindGCTmp:String( vvar:VarValue )

		Local vdecl:=vvar.vdecl
		Local frame:=_gcframe
		
		While frame
			If frame.vars[vdecl.ident]=vvar Return frame.ident+"."+VarName( vvar )
			frame=frame.outer
		Wend
		
		'should really be an unassigned param
		'		
		Return VarName( vvar )
	End
	
	'***** Dependancies *****
	
	Field _usesFiles:=New StringMap<FileDecl>
	Field _usesTypes:=New StringMap<ClassType>
	
	Field _refs:=New StringMap<SNode>
	Field _refsVars:=New Stack<VarValue>
	Field _refsFuncs:=New Stack<FuncValue>
	Field _refsTypes:=New Stack<ClassType>

	Field _incs:=New StringMap<FileDecl>
	
	Field _depsPos:Int
	
	Method BeginDeps()
		_depsPos=InsertPos
	End
	
	Method EndDeps()
	
		BeginInsert( _depsPos )
	
		EmitBr()
		Emit( "// ***** External *****" )

		EmitBr()
		For Local fdecl:=Eachin _usesFiles.Values

			EmitInclude( fdecl )
		Next
		
		EmitBr()
		For Local ctype:=Eachin _refsTypes
		
			If Not Included( ctype.transFile ) Emit( "struct "+ClassName( ctype )+";" )
		Next
		_refsTypes.Clear()
		
		EmitBr()	
		For Local vvar:=Eachin _refsVars
		
			If Not Included( vvar.transFile ) Emit( "extern "+VarProto( vvar )+";" )
		Next
		_refsVars.Clear()
	
		EmitBr()
		For Local func:=Eachin _refsFuncs
		
			If Not Included( func.transFile ) Emit( "extern "+FuncProto( func )+";" )
		Next
		_refsFuncs.Clear()
		
		EmitBr()
		
		EndInsert()
	End
	
	Method Included:Bool( fdecl:FileDecl )
	
		Return _incs.Contains( fdecl.ident )
	End
	
	Method EmitInclude( fdecl:FileDecl )
	
		If _incs.Contains( fdecl.ident ) Return
		
		Emit( "#include ~q"+fdecl.hfile+"~q" )
		
		_incs[fdecl.ident]=fdecl
	End
	
	Method AddRef:Bool( name:String,node:SNode )
		If _refs.Contains( name ) Return True
		_refs[name]=node
		Return False
	End
	
	Method Refs( vvar:VarValue )
	
		If vvar.vdecl.IsExtern Uses( vvar.transFile ) ; Return
	
		Select vvar.vdecl.kind
		Case "field"
			Refs( vvar.type )
			Uses( vvar.scope.FindClass() )
		Case "const","global"
			If AddRef( VarName( vvar ),vvar ) Return
			_refsVars.Push( vvar )
			Refs( vvar.type )
		Case "local","param","capture"
		Default
			Throw New TransEx( "Trans.Refs() VarValue '"+String.FromCString( vvar.typeName() )+"' not recognized" )
		End
	End
	
	Method Refs( func:FuncValue )

		Local fdecl:=func.fdecl
			
		If fdecl.IsExtern Uses( func.transFile ) ; Return
		
		If fdecl.kind="function" Or func.IsExtension
			If AddRef( FuncName( func ),func ) Return
			_refsFuncs.Push( func )
			Refs( func.ftype )
		Else If fdecl.kind="method"
			Uses( func.scope.FindClass() )
			Refs( func.ftype )
		Else If fdecl.kind="lambda"
		Else
			Throw New TransEx( "Trans.Refs() FuncValue '"+String.FromCString( func.typeName() )+"' not recognized" )
		End
	End
	
	Method Refs( type:Type )
	
		Local ctype:=TCast<ClassType>( type )
		If ctype
			If IsStruct( ctype ) Uses( ctype ) ; Return
			If AddRef( ClassName( ctype ),ctype ) Return
			_refsTypes.Push( ctype )
			Return
		Endif
		
		Local ftype:=TCast<FuncType>( type )
		If ftype
			Refs( ftype.retType )
			For Local type:=Eachin ftype.argTypes
				Refs( type )
			Next
			Return
		Endif
		
		Local atype:=TCast<ArrayType>( type )
		If atype
			Refs( atype.elemType )
			Return
		Endif
		
		Local ptype:=TCast<PointerType>( type )
		If ptype
			Refs( ptype.elemType )
			Return
		Endif
		
	End
	
	Method Uses( type:Type )
		Local ctype:=TCast<ClassType>( type )
		If ctype Uses( ctype )
	End
	
	Method Uses( ctype:ClassType )
		_usesTypes[ ClassName( ctype ) ]=ctype
		Uses( ctype.transFile )
	End
	
	Method Uses( fdecl:FileDecl )
		_usesFiles[ fdecl.ident ]=fdecl
	End
	
	'***** MISC *****

	Method IsStruct:Bool( type:Type )

		Local ctype:=TCast<ClassType>( type )
		Return ctype And ctype.cdecl.kind="struct"
	End
	
	Method IsValue:Bool( type:Type )
	
		Return TCast<PrimType>( type ) Or TCast<FuncType>( type ) Or IsStruct( type )
	End
	
	Method CFuncType:String( type:FuncType )
	
		Local retType:=TransType( type.retType )
		
		Local argTypes:=""
		For Local i:=0 Until type.argTypes.Length
			If argTypes argTypes+=","
			argTypes+=TransType( type.argTypes[i] )
		Next
		
		Return retType+"("+argTypes+")"
	End

End
