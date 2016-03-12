
Namespace mx2

Class TryParseEx
End

Class Parser

	Method New()
	End
	
	Method New( source:String,ppsyms:StringMap<String> )
	
		_ppsyms=ppsyms
		
		_toker=New Toker( source )
		Bump()
	End	

	Method ParseFile:FileDecl( ident:String,srcPath:String,ppsyms:StringMap<String> )
	
		_ppsyms=ppsyms
		
		_fdecl=New FileDecl
		_fdecl.ident=ident
		_fdecl.path=srcPath
		_fdecl.nmspace="default"
		
		Local source:=LoadString( srcPath )
		_toker=New Toker( source )
		
		'PARSE!
		
		PNode.parsing=_fdecl

		Bump()
		CParseEol()
		
		If CParse( "namespace" )
			Try
				_fdecl.nmspace=ParseDottedIdent()
				ParseEol()
			Catch ex:ParseEx
				SkipToNextLine()
			End
		Endif
		
		_idscope=_fdecl.nmspace+"."
		
		Local flags:=DECL_PUBLIC
		
		Local usings:=New StringStack
		usings.Push( "monkey" )
		
		While Toke
			Select Toke
			Case "public"
				flags=CParseAccess( flags )
				CParseEol()
			Case "private"
				flags=CParseAccess( flags )
				CParseEol()
			Case "using"
				Try
					Bump()
					usings.Push( ParseDottedIdent() )
					ParseEol()
				Catch ex:ParseEx
					SkipToNextLine()
				End
			Default
				Exit
			End
		Wend
		
		_fdecl.members=ParseDecls( Null,flags )
		
		_fdecl.usings=usings.ToArray()
		_fdecl.imports=_imports.ToArray()
		_fdecl.errors=_errors.ToArray()
		_fdecl.endpos=EndPos
		
		PNode.parsing=Null
		
		Return _fdecl
	End
	
	Method ParseDecls:Decl[]( parent:Decl,flags:Int )
	
		Local idscope:=_idscope
		If parent _idscope+=parent.ident+"."
	
		Local decls:=New Stack<Decl>
		
		While Toke
			Select Toke
			Case "end"
				Exit
			Case "extern"
				Bump()
				flags&=~DECL_ACCESSMASK
				flags|= DECL_EXTERN | DECL_PUBLIC
				flags=CParseAccess( flags )
				CParseEol()
			Case "public","private","protected"
				flags&=~DECL_EXTERN
				flags=CParseAccess( flags )
				CParseEol()
			Case "const"
				ParseVars( decls,flags )
			Case "global"
				ParseVars( decls,flags )
			Case "field"
				ParseVars( decls,flags )
			Case "local"
				ParseVars( decls,flags )
			Case "alias"
				ParseAliases( decls,flags )
			Case "class"
				decls.Push( ParseClass( flags ) )
			Case "struct"
				decls.Push( ParseClass( flags ) )
			Case "interface"
				decls.Push( ParseClass( flags ) )
			Case "enum"
				decls.Push( ParseEnum( flags ) )
			Case "function"
				decls.Push( ParseFunc( flags ) )
			Case "method"
				decls.Push( ParseFunc( flags ) )
			Case "operator"
				decls.Push( ParseFunc( flags ) )
			Case "property"
				decls.Push( ParseProperty( flags ) )
			Default
				Try
					Error( "Unexpected token '"+Toke+"'" )
				Catch ex:ParseEx
				End
				SkipToNextLine()
			End
		Wend
		
		_idscope=idscope
		
		Return decls.ToArray()
	End
	
	Method CParseAccess:Int( flags:Int )
	
		Select Toke
		Case "public" flags=flags & ~(DECL_ACCESSMASK) | DECL_PUBLIC
		Case "private" flags=flags & ~(DECL_ACCESSMASK) | DECL_PRIVATE
		Case "protected" flags=flags & ~(DECL_ACCESSMASK) | DECL_PROTECTED
		Default Return flags
		End
		Bump()
		Return flags
	End
	
	Method ParseAliases( decls:Stack<Decl>,flags:Int )
	
		Local kind:=Parse()
		
		Try
			Repeat
			
				Local decl:=New AliasDecl
				
				decl.srcpos=SrcPos
				decl.kind=kind
				decl.docs=Docs()
				decl.flags=flags
				decl.ident=ParseIdent()
				decl.idscope=_idscope
				
				Parse( ":" )
				decl.type=ParseType()
				
				decl.endpos=EndPos
				decls.Push( decl )
			
			Until Not CParse( "," )
			
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
	End
	
	Method ParseVars( decls:Stack<Decl>,flags:Int )
	
		Local kind:=Parse()
		
		Try
			Repeat
			
				Local decl:=New VarDecl
				
				decl.srcpos=SrcPos
				decl.kind=kind
				decl.docs=Docs()
				decl.flags=flags
				decl.ident=ParseIdent()
				decl.idscope=_idscope
				
				If flags & DECL_EXTERN
					Parse( ":" )
					decl.type=ParseType()
					If CParse( "=" ) decl.symbol=ParseString() Else decl.symbol=decl.ident
				Else If CParse( ":" )
					decl.type=ParseType()
					If CParse( "=" ) decl.init=ParseExpr()
				Else If CParse( ":=" )
					decl.init=ParseExpr()
				Endif
				
				decl.endpos=EndPos
				decls.Push( decl )
				
			Until Not CParse( "," )
			
			ParseEol()
			
		Catch ex:ParseEx

			SkipToNextLine()
		End
	End
	
	Method ParseClass:ClassDecl( flags:Int )
	
		Local srcpos:=SrcPos
		Local kind:=Parse()
		Local docs:=Docs()
		Local ident:="?????"
		Local genArgs:String[]
		Local superType:TypeExpr
		Local ifaceTypes:TypeExpr[]
		Local symbol:=""
	
		Local mflags:=DECL_PUBLIC | (flags & DECL_EXTERN)
		
		If kind="interface" mflags|=DECL_IFACEMEMBER
		
		Try
			ident=ParseIdent()

			genArgs=ParseGenArgs()
			
			If CParse( "extends" )
				If kind="interface"
					ifaceTypes=ParseTypes()
				Else
					superType=ParseType()
				Endif
			Endif
			
			If CParse( "implements" )
				ifaceTypes=ParseTypes()
			Endif
			
			Select Toke
			Case "virtual","abstract","final"
			
				If kind="interface" Error( "Interfaces are implicitly abstract" )
				
				If CParse( "virtual" )
					flags|=DECL_VIRTUAL
				Else If CParse( "abstract" )
					flags|=DECL_ABSTRACT
				Else If CParse( "final" )
					flags|=DECL_FINAL
				Endif
				
			End
			
			If flags & DECL_EXTERN
				If CParse( "=" ) symbol=ParseString()
			Endif
		
			ParseEol()
		
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Local decl:=New ClassDecl
		decl.srcpos=srcpos
		decl.kind=kind
		decl.ident=ident
		decl.flags=flags
		decl.docs=docs
		decl.genArgs=genArgs
		decl.superType=superType
		decl.ifaceTypes=ifaceTypes
		decl.symbol=symbol
		
		decl.members=ParseDecls( decl,mflags )
		
		Try
			Parse( "end" )
			CParse( decl.kind )
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		decl.endpos=EndPos
		Return decl
	End
	
	Method ParseFunc:FuncDecl( flags:Int )
	
		Local srcpos:=SrcPos
		Local kind:=Parse()
		Local docs:=Docs()
		Local ident:="?????"
		Local genArgs:String[]
		Local type:FuncTypeExpr
		Local whereExpr:Expr
		Local symbol:String
	
		Try

			Select kind
	
			Case "lambda"
			
			Case "getter"
			
				kind="method"
				flags|=DECL_GETTER
				
			Case "setter"
			
				kind="method"
				flags|=DECL_SETTER
			
			Case "operator"
			
				kind="method"
				flags|=DECL_OPERATOR
			
				Select Toke
				Case "*","/","+","-","&","|","~~"
					ident=Parse()
				Case "*=","/=","+=","-=","&=","|=","~~="
					ident=Parse()
				Case "<",">","<=",">=","=","<>","<=>"
					ident=Parse()
				Case "["
					Bump()
					Parse( "]" )
					If CParse( "=" ) ident="[]=" Else ident="[]"
				Default
					Error( "Operator must be one of: * / + - & | ~~ [] < > <= >= = <> <=>" )
				End
				
			Case "method"
			
				If CParse( "new" ) ident="new" Else ident=ParseIdent()
				
			Default
			
				ident=ParseIdent()
			End
	
			genArgs=ParseGenArgs()
			
			If CParse( ":" )
				type=Cast<FuncTypeExpr>( ParseType() )
				If Not type Error( "Expecting function type" )
			Else
				type=ParseFuncType( New IdentTypeExpr( "void",SrcPos,SrcPos ) )
			Endif
			
			For Local param:=Eachin type.params
				If Not param.ident Error( "Missing parameter identifier" )
			Next
			
			Select kind
			Case "property"
				If type.params.Length=0
					kind="method"
					flags|=DECL_GETTER
				Else If type.params.Length=1
					kind="method"
					flags|=DECL_SETTER
				Else
					Error( "Property must have 0 or 1 parameters" )
				End
			Case "method"
				If (flags & DECL_GETTER)
					If type.params.Length<>0 Error( "Getters must have 0 parameters" )
				Else If (flags & DECL_SETTER )
					If type.params.Length<>1 Error( "Setters must have 1 parameter" )
				Endif
			End
			
			Select Toke
			Case "virtual","abstract","override","final","extension"
			
				If flags & DECL_IFACEMEMBER Error( "Interface methods are implictly abstract" )
				
				If CParse( "virtual" )
					flags|=DECL_VIRTUAL
				Else If CParse( "abstract" )
					flags|=DECL_ABSTRACT
				Else If CParse( "override" )
					flags|=DECL_OVERRIDE
					If CParse( "final" ) flags|=DECL_FINAL
				Else If CParse( "final" )
					flags|=DECL_FINAL
				Else If CParse( "extension" )
					If kind<>"method" Or Not (flags & DECL_EXTERN) Error( "Only extern methods can be declared 'Extension'" )
					flags|=DECL_EXTENSION
				Endif
				
			End
			
			If CParse( "where" )
				whereExpr=ParseExpr()
			Endif
			
			If flags & DECL_EXTERN
				If CParse( "=" ) symbol=ParseString()
			Endif
			
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Local decl:=New FuncDecl
		decl.srcpos=srcpos
		decl.kind=kind
		decl.docs=docs
		decl.ident=ident
		decl.flags=flags
		decl.genArgs=genArgs
		decl.type=type
		decl.whereExpr=whereExpr
		decl.symbol=symbol
		
		If flags & (DECL_EXTERN|DECL_ABSTRACT|DECL_IFACEMEMBER)
			decl.endpos=EndPos
			Return decl
		Endif
		
		decl.stmts=ParseStmts( True )
		
		Try
		
			Select Toke
			Case "setter"
				If Not (flags & DECL_GETTER) Error( "Setter must appear after getter" )
			Case "getter"
				If Not (flags & DECL_SETTER) Error( "Getter must appear after setter" )
			Default
				Parse( "end" )
				CParse( kind )
				If kind<>"lambda" ParseEol()
			End
			
		Catch ex:ParseEx
		
			If kind="lambda" SkipToEol() Else SkipToNextLine()
		End
		
		decl.endpos=EndPos

		Return decl
	End
	
	Method ParseEnum:EnumDecl( flags:Int )
	
		Local decl:=New EnumDecl
		
		decl.srcpos=SrcPos
		decl.flags=flags
		decl.kind=Parse()
		decl.docs=Docs()
		
		Try
			decl.ident=ParseIdent()
			decl.idscope=_idscope
			
			If CParse( "extends" ) decl.superType=ParseType()
			
			If flags & DECL_EXTERN
				If CParse( "=" ) decl.symbol=ParseString() Else decl.symbol=decl.ident
			Endif
			
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Local members:=New Stack<Decl>
		
		While TokeType=TOKE_IDENT
		
			Try
				Local decl:=New VarDecl
				
				decl.srcpos=SrcPos
				decl.kind="const"
				decl.flags=DECL_PUBLIC|(flags & DECL_EXTERN)
				decl.ident=ParseIdent()
				decl.idscope=_idscope
				decl.docs=Docs()
				
				If flags & DECL_EXTERN
					If CParse( "=" ) decl.symbol=ParseString() Else decl.symbol=decl.ident
				Else
					If CParse( "=" ) decl.init=ParseExpr()
				Endif
				
				decl.endpos=EndPos
				members.Push( decl )
				
				If Not CParse( "," ) ParseEol() Else CParseEol()
								
			Catch ex:ParseEx
			
				SkipToNextLine()
			End
		
		Wend

		decl.members=members.ToArray()
		
		Try
		
			Parse( "end" )
			CParse( "enum" )
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		decl.endpos=EndPos
		
		Return decl
	End
	
	Method ParseProperty:PropertyDecl( flags:Int )
	
		Local decl:=New PropertyDecl
		
		decl.srcpos=SrcPos
		decl.flags=flags
		decl.kind="property"
		decl.docs=Docs()
		
		Local func:=ParseFunc( flags )
		decl.ident=func.ident
		
		If func.IsGetter
		
			decl.getFunc=func
			
			If Toke="setter"
				decl.setFunc=ParseFunc( flags )
				decl.setFunc.ident=decl.ident
			Endif
			
		Else If func.IsSetter

			decl.setFunc=func

			If Toke="getter"
				decl.getFunc=ParseFunc( flags )
				decl.getFunc.ident=decl.ident
			Endif
			
		Endif
		
		decl.endpos=EndPos
		
		Return decl
	End
	
	Method ParseStmts:StmtExpr[]( block:Bool )
		If block Return ParseBlockStmts()
		Return ParseSimpleStmts()
	End
	
	Method ParseBlockStmts:StmtExpr[]()
	
		Local stmts:=New Stack<StmtExpr>
		
		While Toke
			
			Select Toke
			Case "if"
				stmts.Push( ParseIf() )
			Case "while"
				stmts.Push( ParseWhile() )
			Case "repeat"
				stmts.Push( ParseRepeat() )
			Case "for"
				stmts.Push( ParseFor() )
			Case "select"
				stmts.Push( ParseSelect() )
			Case "try"
				stmts.Push( ParseTry() )
			Case "local","const","global"
				Local decls:=New Stack<Decl>
				ParseVars( decls,DECL_PUBLIC )
				For Local decl:=Eachin decls
					stmts.Push( New VarDeclStmtExpr( Cast<VarDecl>(decl),decl.srcpos,decl.endpos ) )
				Next
			Case "end","endif","wend","next","until","forever","else","elseif","setter","getter","case","default","catch"
				Exit
			Default
				Try
					Repeat
						stmts.Push( ParseSimpleStmt() )
					Until Not CParse( ";" )
					ParseEol()
				Catch ex:ParseEx
					SkipToNextLine()
				End
			End
		Wend
		
		Return stmts.ToArray()
	End
	
	Method ParseSimpleStmts:StmtExpr[]()
	
		Local stmts:=New Stack<StmtExpr>
		
		Try
			Repeat
				stmts.Push( ParseSimpleStmt() )
			Until Not CParse( ";" )
		Catch ex:ParseEx
			SkipToEol()
		End
		
		Return stmts.ToArray()
	End
	
	Method ParseIf:IfStmtExpr()
	
		Local srcpos:=SrcPos
		Local cond:Expr
		Local block:Bool
		
		Try
			Parse( "if" )
			
			cond=ParseExpr()
			
			block=CParseEol()
			
			If Not block CParse( "then" )
			
		Catch ex:ParseEx
		
			SkipToNextLine()
			
			If Not block Return New IfStmtExpr( cond,Null,Null,srcpos,EndPos )

		End
		
		Local stmts:=ParseStmts( block )
		Local expr:=New IfStmtExpr( cond,stmts,Null,srcpos,EndPos )
		Local pred:=expr
		
		While Toke="elseif" Or Toke="else"
		
			Local srcpos:=SrcPos
			Local toke:=Parse()
			Local cond:Expr

			If toke="else" And CParse( "if" ) toke="elseif"

			Try
				If toke="elseif"
					cond=ParseExpr()
					If block ParseEol() Else CParse( "then" )
				Else
					If block ParseEol()
				Endif
			
			Catch ex:ParseEx
			
				SkipToNextLine()
				If Not block Return expr
			
			End
			
			Local stmts:=ParseStmts( block )
			
			Local expr:=New IfStmtExpr( cond,stmts,Null,srcpos,EndPos )
			pred.succ=expr
			pred=expr
			
			If toke="else" Exit
		Wend
		
		Try
			If block
				If CParse( "end" ) CParse( "if" ) Else Parse( "endif" )
			Endif
			
			ParseEol()
			
		Catch ex:ParseEx

			SkipToNextLine()
		End
		
		pred.endpos=EndPos
		
		Return expr
	End
	
	Method ParseWhile:WhileStmtExpr()
	
		Local srcpos:=SrcPos
		Local cond:Expr
		
		Try
			Parse( "while" )
			cond=ParseExpr()
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Local stmts:=ParseStmts( True )
		
		Try
			If CParse( "end" ) Then CParse( "while" ) Else Parse( "wend" )
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Return New WhileStmtExpr( cond,stmts,srcpos,EndPos )
	End
	
	Method ParseRepeat:RepeatStmtExpr()
	
		Local srcpos:=SrcPos
		Local cond:Expr
		Local block:=False
		
		Try
			Parse( "repeat" )
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Local stmts:=ParseStmts( True )
		
		Try
			If CParse( "until" ) 
				cond=ParseExpr()
			Else If Not CParse( "forever" )
				Error( "Expecting 'until' or 'forever'" )
			Endif
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Return New RepeatStmtExpr( stmts,cond,srcpos,EndPos )
	End
	
	Method ParseFor:ForStmtExpr()
	
		Local srcpos:=SrcPos
		
		Local varIdent:String
		Local varType:TypeExpr
		Local varExpr:Expr
		Local kind:String
		Local init:Expr
		Local cond:Expr
		Local incr:Expr
		
		Try
			Parse( "for" )
			
			If CParse( "local" )
			
				varIdent=ParseIdent()
				
				If CParse( ":" )
				
					varType=ParseType()
					
					Parse( "=" )
				Else
				
					Parse( ":=" )
				Endif
			Else
			
				varExpr=ParsePostfixExpr()
				
				Parse( "=" )
			Endif
			
			If CParse( "eachin" )
			
				init=ParseExpr()
				kind="eachin"
			
			Else
			
				init=ParseExpr()
				
				If Toke<>"to" And Toke<>"until" Error( "Expecting 'To' or 'Until'" )
				
				kind=Toke
				Bump()
				
				cond=ParseExpr()
				
				If CParse( "step" ) incr=ParseExpr()
			
			Endif
			
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
			
		End
		
		Local stmts:=ParseStmts( True )
		
		Try
			If CParse( "end" ) CParse( "for" ) Else Parse( "next" )
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Return New ForStmtExpr( varIdent,varType,varExpr,kind,init,cond,incr,stmts,srcpos,EndPos )
	
	End
	
	Method ParseSelect:SelectStmtExpr()
	
		Local srcpos:=SrcPos
		Local expr:Expr
		
		Try
			Parse( "select" )
			
			expr=ParseExpr()
			
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Local cases:=New Stack<CaseExpr>
		
		While CParse( "case" )

			Local exprs:=New Stack<Expr>

			Try
			
				Repeat
					exprs.Push( ParseExpr() )
				Until Not CParse( "," )
				
				CParseEol()

			Catch ex:ParseEx
			
				SkipToNextLine()
			End
			
			Local stmts:=ParseStmts( True )
			
			cases.Push( New CaseExpr( exprs.ToArray(),stmts ) )
		Wend
		
		If CParse( "default" )
		
			CParseEol()
		
			Local stmts:=ParseStmts( True )
			
			cases.Push( New CaseExpr( Null,stmts ) )
		Endif
		
		Try
			Parse( "end" )
			CParse( "select" )
			ParseEol()
		Catch ex:ParseEx
			SkipToNextLine()
		End
		
		Return New SelectStmtExpr( expr,cases.ToArray(),srcpos,EndPos )
	
	End
	
	Method ParseTry:TryStmtExpr()
	
		Local srcpos:=SrcPos
	
		Try
		
			Parse( "try" ) 
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Local stmts:=ParseStmts( True )
		
		Local catches:=New Stack<CatchStmtExpr>
		
		While Toke="catch"
		
			Local srcpos:=SrcPos
			
			Bump()
			
			Local varIdent:String
			Local varType:TypeExpr
			
			Try
				varIdent=ParseIdent()
				Parse( ":" )
				varType=ParseType()
				
				ParseEol()
				
			Catch ex:ParseEx
			
				SkipToNextLine()
			End
			
			Local stmts:=ParseStmts( True )
			
			catches.Push( New CatchStmtExpr( varIdent,varType,stmts ) )
		Wend
		
		Try
		
			Parse( "end" )
			CParse( "try" )
			ParseEol()
			
		Catch ex:ParseEx
		
			SkipToNextLine()
		End
		
		Return New TryStmtExpr( stmts,catches.ToArray(),srcpos,EndPos )
	End
	
	'THROWS!
	Method ParseSimpleStmt:StmtExpr()
	
		Local srcpos:=SrcPos

		Select Toke
		Case "print"
			Bump()
			Local expr:=ParseExpr()
			Return New PrintStmtExpr( expr,srcpos,EndPos )
		Case "return"
			Bump()
			Local expr:Expr
			If TokeType And TokeType<>TOKE_EOL And Toke<>";" And Toke<>"else"
				expr=ParseExpr()
			Endif
			Return New ReturnStmtExpr( expr,srcpos,EndPos )
		Case "throw"
			Bump()
			Local expr:=ParseExpr()
			Return New ThrowStmtExpr( expr,srcpos,EndPos )
		Case "continue"
			Bump()
			Return New ContinueStmtExpr( srcpos,EndPos )
		Case "exit"
			Bump()
			Return New ExitStmtExpr( srcpos,EndPos )
		End

		Return ParseExprStmt()
	End
	
	'THROWS!
	Method ParseExprStmt:StmtExpr()
		
		Local srcpos:=SrcPos
		Local expr:=ParsePostfixExpr()
		
		Select Toke
		Case "=","*=","/=","+=","-=","&=","|=","~~="
			Local op:=Parse()
			Local rhs:=ParseExpr()
			Return New AssignStmtExpr( op,expr,rhs,srcpos,EndPos )
		End
		
		'Ok, ugly, but look for Blah.New() here...
		'
		Local iexpr:=Cast<InvokeExpr>( expr )
		If iexpr
			Local mexpr:=Cast<MemberExpr>( iexpr.expr )
			If mexpr And mexpr.ident="new" Return New InvokeNewStmtExpr( mexpr.expr,iexpr.args,srcpos,EndPos )
		Endif
		
		Return New EvalStmtExpr( expr,srcpos,EndPos )
	End
	
	'THROWS!
	Method ParseGenArgs:String[]()
	
		If Not CParse( "<" ) Return Null
		
		Local args:=New StringStack
		Repeat
			args.Push( ParseIdent() )
		Until Not CParse( "," )
	
		Parse( ">" )
		
		Return args.ToArray()
	End
	
	Method IsTypeIdent:Bool( ident:String )
		Select ident
		Case "void","bool","byte","ubyte","short","ushort","int","uint","long","ulong","float","double","string","object"
			Return True
		End
		Return False
	End
	
	'THROWS!
	Method ParseTypes:TypeExpr[]()
		Local types:=New Stack<TypeExpr>
		Repeat
			types.Push( ParseType() )
		Until Not CParse( "," )
		Return types.ToArray()
	End
	
	'THROWS!
	Method ParseFuncType:FuncTypeExpr( retType:TypeExpr )
	
		Parse( "(" )
		
		Local params:=New Stack<VarDecl>
		
		If Not CParse( ")" )
		
			Repeat

				Local decl:=New VarDecl
				decl.srcpos=SrcPos
				decl.kind="param"
				decl.flags=DECL_PUBLIC
				
				Local ident:=CParseIdent()
				
				If ident
					If CParse( ":" )
						decl.ident=ident
						decl.idscope=_idscope
						decl.type=ParseType()
						If CParse( "=" ) decl.init=ParseExpr()
					Else
						decl.type=ParseType( New IdentTypeExpr( ident,decl.srcpos,EndPos ) )
					Endif
				Else
					decl.type=ParseType()
				Endif
				
				decl.endpos=EndPos
				
				params.Push( decl )
				
			Until Not CParse( "," )
			
			Parse( ")" )
			
		Endif
		
		Return New FuncTypeExpr( retType,params.ToArray(),retType.srcpos,EndPos )
	End
	
	'THROWS!
	Method ParseIdentType:IdentTypeExpr()
	
		Local srcpos:=SrcPos
		
		Local ident:=CParseIdent()
		If Not ident And IsTypeIdent( Toke ) ident=Parse()
		If Not ident Error( "Expecting type identifier" )
		Return New IdentTypeExpr( ident,srcpos,EndPos )
	End

	'THROWS!	
	Method ParseBaseType:TypeExpr( identType:IdentTypeExpr=Null )
	
		Local type:TypeExpr=identType
		
		If Not type type=ParseIdentType()
		Local srcpos:=type.srcpos
		
		Repeat
			If Toke="."
				Bump()
				Local ident:=ParseIdent()
				type=New MemberTypeExpr( type,ident,srcpos,EndPos )
			Else If Toke="<"
				Bump()
				Local args:=New Stack<TypeExpr>
				Repeat
					args.Push( ParseType() )
				Until Not CParse( "," )
				Parse( ">" )
				type=New GenericTypeExpr( type,args.ToArray(),srcpos,EndPos )
			Else
				Exit
			Endif
		Forever
		
		While CParse( "ptr" )
			type=New PointerTypeExpr( type,srcpos,EndPos )
		Wend
		
		Return type
	End
	
	'THROWS!
	Method ParseType:TypeExpr( identType:IdentTypeExpr=Null )
	
		Local type:=ParseBaseType( identType )
		Local srcpos:=type.srcpos
		
		Repeat
			Select Toke
			Case "["
				Bump()
				Local rank:=1
				While CParse( "," )
					rank+=1
				Wend
				Parse( "]" )
				type=New ArrayTypeExpr( type,rank,srcpos,EndPos )
			Case "("
				type=ParseFuncType( type )
			Default
				Exit
			End
		Forever
		
		Return type
	End

	'THROWS! Some ugly stunt parsing to handle operator New.
	Method ParseNewType:TypeExpr()
	
		Local srcpos:=SrcPos
		Local type:=ParseBaseType()
		
		Repeat
			Select Toke
			Case "["
				BeginTryParse()
				Bump()
				Local rank:=1
				While CParse( "," )
					rank+=1
				Wend
				If Not CParse( "]" )
					TryParseFailed()
					Exit
				Endif
				EndTryParse()
				type=New ArrayTypeExpr( type,rank,srcpos,EndPos )
			Case "("
				BeginTryParse()
				Try
					Local ftype:=ParseFuncType( type )
					If Toke<>"[" And Toke<>"("
						TryParseFailed()
						Return type
					Endif
					EndTryParse()
					type=ftype
				Catch ex:TryParseEx
					TryParseFailed()
					Exit
				End
			Default
				Exit
			End
		Forever
		
		Return type
	End

	'THROWS!
	Method ParsePrimaryExpr:Expr()
	
		Local srcpos:=SrcPos
	
		Select Toke
		Case "("
			Bump()
			Local expr:=ParseExpr()
			Parse( ")" )
			Return expr
'		Case "["
'			Bump()
'			Local exprs:=ParseExprs()
'			Parse( "]" )
'			Return New ArrayLiteralExpr( exprs,srcpos,EndPos )
		Case "self"
			Bump()
			Return New SelfExpr( srcpos,EndPos )
		Case "super"
			Bump()
			Return New SuperExpr( srcpos,EndPos )
		Case "null"
			Bump()
			Return New NullExpr( srcpos,EndPos )
		Case "new"
		
			Bump()
			Local type:=ParseNewType()
			
			If CParse( "[" )
				Local sizes:=ParseExprs()
				Parse( "]" )
				Return New NewArrayExpr( New ArrayTypeExpr( type,1,srcpos,EndPos ),sizes,Null,srcpos,EndPos )
			Endif
			
			If Toke="("
				Local atype:=Cast<ArrayTypeExpr>( type )
				If atype
					Bump()
					Local inits:=ParseExprs()
					Parse( ")" )
					Return New NewArrayExpr( atype,Null,inits,srcpos,EndPos )
				Endif
				Local args:=ParseInvokeArgs()
				Return New NewObjectExpr( type,args,srcpos,EndPos )
			End
			
			Return New NewObjectExpr( type,Null,srcpos,EndPos )
			
		Case "lambda"
		
			Local decl:=ParseFunc( DECL_PUBLIC )
			Return New LambdaExpr( decl,srcpos,EndPos )
			
		Case "cast"
		
			Bump()
			Parse( "<" )
			Local type:=ParseType()
			Parse( ">" )
			Parse( "(" )
			Local expr:=ParseExpr()
			Parse( ")" )
			Return New CastExpr( type,expr,srcpos,EndPos )
			
		Case "true","false"
		
			Local value:=Parse()
			
			Return New LiteralExpr( value,TOKE_KEYWORD,Null,srcpos,EndPos )
		End
		
		Select TokeType
		Case TOKE_KEYWORD
		
			If IsTypeIdent( Toke )
			
				Local ident:=Parse()
				
				If Toke="ptr" Or Toke="("
					Local type:=ParseBaseType( New IdentTypeExpr( ident,srcpos,EndPos ) )
					
					Parse( "(" )
					Local expr:=ParseExpr()
					Parse( ")" )
					Return New CastExpr( type,expr,srcpos,EndPos )
				Endif
				
				Return New IdentExpr( ident,srcpos,EndPos )
				
			Endif
			
		Case TOKE_IDENT
		
			Return New IdentExpr( ParseIdent(),srcpos,EndPos )
			
		Case TOKE_INTLIT,TOKE_FLOATLIT
		
			Local toke:=Toke
			Local tokeType:=TokeType
			Local typeExpr:TypeExpr

			Bump()
			If CParse( ":" ) typeExpr=ParseType()
			
			Return New LiteralExpr( toke,tokeType,typeExpr,srcpos,EndPos )
			
		Case TOKE_STRINGLIT

			Local toke:=Toke
			Local tokeType:=TokeType
			Local typeExpr:TypeExpr

			Bump()
		
			Return New LiteralExpr( toke,tokeType,typeExpr,srcpos,EndPos )
			
		End
		
		Error( "Expecting expression but encountered '"+Toke+"'" )
		Return Null
	End
	
	'THROWS!
	Method ParsePostfixExpr:Expr()
	
		Local expr:=ParsePrimaryExpr()
		
		While Toke
			Local srcpos:=SrcPos
			
			Select Toke
			Case "."
				Bump()
				Local ident:=CParseIdent()
				If Not ident And Toke="new" ident=Parse()
				If Not ident Error( "Expecting member identifier" )
				expr=New MemberExpr( expr,ident,srcpos,EndPos )
			Case "->"
				Bump()
				Local ident:=ParseIdent()
				Local zero:=New LiteralExpr( "0",TOKE_INTLIT,Null,srcpos,EndPos )
				expr=New IndexExpr( expr,New Expr[]( zero ),srcpos,EndPos )
				expr=New MemberExpr( expr,ident,srcpos,EndPos )
			Case "["
				Bump()
				Local args:=ParseExprs()
				Parse( "]" )
				expr=New IndexExpr( expr,args,srcpos,EndPos )
			Case "("
				Local args:=ParseInvokeArgs()
				expr=New InvokeExpr( expr,args,srcpos,EndPos )
			Case "<"
				BeginTryParse()
				Local args:=New Stack<TypeExpr>
				Try
					Bump()
					Repeat
						args.Push( ParseType() )
					Until Not CParse( "," )
					Parse( ">" )
				Catch ex:TryParseEx
					TryParseFailed()
					Exit
				End
				EndTryParse()
				expr=New GenericExpr( expr,args.ToArray(),srcpos,EndPos )
			Default
				Exit
			End
		Wend
		
		Return expr
	End
	
	'THROWS!
	Method ParsePrefixExpr:Expr()
		Local srcpos:=SrcPos
		Select Toke
		Case "varptr"
			Bump()
			Return New VarptrExpr( ParsePrefixExpr(),srcpos,EndPos )
		Case "+","-","~~","not"
			Local op:=Parse()
			Return New UnaryopExpr( op,ParsePrefixExpr(),srcpos,EndPos )
		End
		Return ParsePostfixExpr()
	End

	'THROWS!
	Method ParseMuldivExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParsePrefixExpr()
		Repeat
			Select Toke
			Case "*","/","mod"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParsePrefixExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseAddsubExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseMuldivExpr()
		Repeat
			Select Toke
			Case "+","-"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseMuldivExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseShiftExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseAddsubExpr()
		Repeat
			Select Toke
			Case "shl","shr"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseAddsubExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	
	End
	
	'THROWS!
	Method ParseBitandExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:Expr=ParseShiftExpr()
		Repeat
			Select Toke
			Case "&","~~"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseShiftExpr(),srcpos,EndPos )
			Default
				Exit
			End Select
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseBitorExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:Expr=ParseBitandExpr()
		Repeat
			Select Toke
			Case "|"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseBitandExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseOrderExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseBitorExpr()
		Repeat
			Select Toke
			Case "<=>"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseBitorExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
		
	'THROWS!
	Method ParseCompareExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseOrderExpr()
		Repeat
			Select Toke
			Case "<",">","<=",">="
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseOrderExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseExtendsExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseCompareExpr()
		Repeat
			Select Toke
			Case "extends","implements"
				Local op:=Parse()
				expr=New ExtendsExpr( op,expr,ParseType(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseEqualsExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:=ParseExtendsExpr()
		Repeat
			Select Toke
			Case "=","<>"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseExtendsExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseAndExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:Expr=ParseEqualsExpr()
		Repeat
			Select Toke
			Case "and"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseEqualsExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	'THROWS!
	Method ParseOrExpr:Expr()
		Local srcpos:=SrcPos
		Local expr:Expr=ParseAndExpr()
		Repeat
			Select Toke
			Case "or"
				Local op:=Parse()
				expr=New BinaryopExpr( op,expr,ParseAndExpr(),srcpos,EndPos )
			Default
				Exit
			End
		Forever
		Return expr
	End
	
	Method ParseIfThenElseExpr:Expr()
	
		Local srcpos:=SrcPos

		Local expr:Expr=ParseOrExpr()
		If Not CParse( "?" ) Return expr
		
		Local thenExpr:=ParseIfThenElseExpr()

		Parse( "else" )

		Local elseExpr:=ParseOrExpr()

		Return New IfThenElseExpr( expr,thenExpr,elseExpr,srcpos,EndPos )
	End
		
	'THROWS!
	Method ParseExpr:Expr()
		Return ParseIfThenElseExpr()
	End
	
	'THROWS!
	Method ParseExprs:Expr[]()
	
		Local exprs:=New Stack<Expr>
		
		Repeat
			exprs.Push( ParseExpr() )
		Until Not CParse( "," )
		
		Return exprs.ToArray()
	End

	'THROWS!	
	Method ParseInvokeArgs:Expr[]()
	
		Local exprs:=New Stack<Expr>
		
		Parse( "(" )
		
		If Not CParse( ")" )
			Repeat
				If Toke=")"
					exprs.Push( Null )
					Exit
				Else If Toke=","
					exprs.Push( Null )
				Else
					exprs.Push( ParseExpr() )
				Endif
			Until Not CParse( "," )
			
			Parse( ")" )
		Endif
		
		Return exprs.ToArray()
	End
	
	Method EatEols()
		While TokeType=TOKE_EOL
			Bump()
		Wend
	End
	
	Method SkipToEol()
		While TokeType And TokeType<>TOKE_EOL
			Bump()
		Wend
	End
	
	Method SkipToNextLine()
		SkipToEol()
		EatEols()
	End
	
	'THROWS!
	Method ParseEol()
		If TokeType<>TOKE_EOL Error( "Expecting end of line" )
		EatEols()
	End
	
	Method CParseEol:Bool()
		If TokeType<>TOKE_EOL Return False
		EatEols()
		Return True
	End
	
	'THROWS!
	Method ParseIdent:String()
		If CParse( "@" ) And TokeType Return "@"+Parse()
		If TokeType<>TOKE_IDENT Error( "Expecting identifier" )
		Local ident:=Toke
		Bump()
		Return ident
	End
	
	'THROWS!
	Method ParseTypeIdent:String()
		Select Toke
		Case "bool","byte","short","int","long","ubyte","ushort","uint","ulong","float","double","string","object"
			Return Parse()
		End
		Return ParseIdent()
	End
	
	'THROWS!
	Method ParseDottedIdent:String()
		Local ident:=ParseIdent()

		While CParse( "." )
			ident+="."+ParseIdent()
		Wend
		
		Return ident
	End

	Method CParseIdent:String()
		If TokeType<>TOKE_IDENT Return ""
		Local ident:=Toke
		Bump()
		Return ident
	End
	
	'THROWS!
	Method ParseString:String()
		If TokeType<>TOKE_STRINGLIT Error( "Expecting string literal" )
		Local str:=Toke.Slice( 1,-1 )
		Bump()
		Return str
	End
	
	'THROWS!	
	Method Parse( toke:String )
		If Toke<>toke Error( "Expecting '"+toke+"' but encountered '"+Toke+"'" )
		Bump()
	End

	Method CParse:Bool( toke:String )
		If Toke<>toke Return False
		Bump()
		Return True
	End

	Method BeginTryParse()
		_stateStack.Push( _toker.State )
	End
	
	Method TryParseFailed()
		Local state:=_stateStack.Pop()
		_toker.State=state
	End
	
	Method EndTryParse()
		_stateStack.Pop()
	End
	
	Method Parse:String()
		Local toke:=Toke
		Bump()
		Return toke
	End

	Method Docs:String()
		If Not _docs.Length Return ""
		Local docs:=_docs.Join( "~n" )
		_docs.Clear()
		Return docs
	End
	
	Method Bump:String()
	
		If Not _fdecl Return _toker.Bump()
	
		Local ptoke:=Toke
		
		Repeat
		
			_toker.Bump()
			
			If _toker.TokeType=TOKE_PREPROC
			
				PreProcess( _toker.Toke )
				
				Continue
				
			Else If _ccnest<>_ifnest
			
				Local pos:=_toker.LinePos
			
				While _toker.TokeType And _toker.TokeType<>TOKE_EOL
					_toker.Bump()
				Wend
				
				If _doccing _docs.Push( _toker.Text.Slice( pos,_toker.TokePos ) )

				Continue
				
			Else
			
				If _toker.TokeType=TOKE_EOL And (ptoke="(" Or ptoke="[" Or ptoke="," ) Continue
				
			Endif
			
			Exit
		
		Forever
		
		Return _toker.Toke
	End
	
	Property Toke:String()
		Return _toker.Toke
	End
	
	Property TokeType:Int()
		Return _toker.TokeType
	End
	
	Property SrcPos:Int()
		Return _toker.SrcPos
	End
	
	Property EndPos:Int()
		Return _toker.EndPos
	End
	
	Method Error( msg:String )
	
		If Not _stateStack.Empty Throw New TryParseEx
	
		Throw New ParseEx( msg,_fdecl.path,SrcPos )
	End
	
	Field _fdecl:FileDecl
	Field _toker:Toker
	Field _idscope:String
	Field _stateStack:=New Stack<Toker>
	Field _errors:=New Stack<ParseEx>
	
	'***** Messy Preprocessor - FIXME! *****
	
	Field _ppsyms:StringMap<String>
	Field _ccnest:Int
	Field _ifnest:Int
	Field _docs:=New StringStack
	Field _doccing:Bool
	Field _imports:=New StringStack
	
	Method IsBool:Bool( v:String )
		Return v="true" Or v="false"
	End
	
	Method ToBool:String( v:String )
		If v="false" Or v="~q~q" Return "false"
		Return "true"
	End
	
	Method EvalError()
	
		Error( "Failed to evaluate preprocessor expression" )
	End
		
	Method EvalPrimary:String()
	
		Select TokeType
		Case TOKE_IDENT
			Local id:=Parse()
			Local t:=_ppsyms[id]
			If Not t t="false"
			Return t
		Case TOKE_STRINGLIT
			Return Parse()
		End
		
		EvalError()
		Return Null
	End
	
	Method EvalUnary:String()
	
		If Toke="not"
			Local t:=ToBool( EvalPrimary() )
			If t="true" Return "false" Else Return "true"
		Endif
		
		Return EvalPrimary()
	End
	
	Method EvalCompare:String()
	
		Local t:=EvalUnary()
		Repeat
			Select Toke
			Case "=","<>"
				Local op:=Parse()
				Local v:=EvalUnary()
				If IsBool( t ) Or IsBool( v )
					t=ToBool( t )
					v=ToBool( v )
				Endif
				Select op
				Case "="
					If t=v t="true" Else t="false"
				Case "<>"
					If t<>v t="true" Else t="false"
				End
			Default
				Exit
			End
		Forever
		Return t
	End
	
	Method Eval:String()
	
		Return EvalCompare()
	End
	
	Method EvalBool:Bool()
	
		Return ToBool( Eval() )="true"
	End
	
	Method PreProcess( text:String )
	
		Local p:=New Parser( text.Slice( 1 ),_ppsyms )
	
		Try
		
			Select p.Toke
			Case "if"
				
				If _ccnest=_ifnest
				
					p.Bump()
					If p.EvalBool() _ccnest+=1
					
				Endif
			
				_ifnest+=1
				
			Case "else","elseif"
			
				If _ccnest=_ifnest
				
					_ccnest|=$10000
					
				Else If _ccnest=_ifnest-1
			
					Local t:=True

					If p.CParse( "else" )
						If p.CParse( "if" ) t=p.EvalBool()
					Else 
						p.Bump()
						t=p.EvalBool()
					Endif
					
					If t _ccnest+=1
					
				Endif
			
			Case "end","endif"
			
				If p.CParse( "end" )
					p.CParse( "if" )
				Else
					p.Bump()
				End
				
				_doccing=False
				
				_ccnest&=~$10000

				If _ccnest=_ifnest _ccnest-=1
				
				_ifnest-=1
			
			Case "rem"
			
				If p.Bump()="monkeydoc" And _ccnest=_ifnest
					Local qhelp:=p._toker.Text.Slice( p._toker.TokePos+9 ).Trim()
					_ccnest|=$10000
					_doccing=True
					_docs.Clear()
					_docs.Push( qhelp )
				Endif
				
				_ifnest+=1
			
			Case "import"
			
				If _ccnest=_ifnest 
					p.Bump()
					Local path:=p.ParseString()
					_imports.Push( path )
				Endif
				
			Case "print"
			
				If _ccnest=_ifnest
					p.Bump()				
					Print p.Eval()
				Endif
				
			End
		Catch ex:ParseEx
		End
		
	End
	
End
