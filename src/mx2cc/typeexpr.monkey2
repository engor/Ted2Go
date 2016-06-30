
Namespace mx2

Function SemantTypes:Type[]( exprs:TypeExpr[],scope:Scope )
	Local types:=New Type[exprs.Length]
	For Local i:=0 Until types.Length
		types[i]=exprs[i].Semant( scope )
	Next
	Return types
End

Class TypeExpr Extends PNode

	Method New( srcpos:Int,endpos:Int )
		Self.srcpos=srcpos
		Self.endpos=endpos
	End
	
	Method OnSemant:Type( scope:Scope ) Virtual
		SemantError( "TypeExpr.Semant()" )
		Return Null
	End
	
	Method Semant:Type( scope:Scope,generic:Bool=False )
	
		Try
		
			PNode.semanting.Push( Self )
			
			Local type:=OnSemant( scope )
			
			Local ctype:=TCast<ClassType>( type )
			If ctype
				If generic
'					If Not ctype.types Or ctype.instanceOf Throw New SemantEx( "Type '"+ctype.ToString()+"' is not generic" )
				Else
					If ctype.types And Not ctype.instanceOf Throw New SemantEx( "Type '"+ctype.ToString()+" is generic" )
				Endif
			Endif
			
			PNode.semanting.Pop()
			Return type
		
		Catch ex:SemantEx
		
			PNode.semanting.Pop()
			Throw ex
		End

		Return Null
	End
	
End

Class IdentTypeExpr Extends TypeExpr

	Field ident:String
	
	Method New( ident:String,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.ident=ident
	End
	
	Method ToString:String() Override
		Select ident
		Case "void","bool","byte","short","int","long","ubyte","ushort","uint","ulong","float","double","string","object"
			Return ident.Capitalize()
		End
		Return ident
	End
	
	Method OnSemant:Type( scope:Scope ) Override
	
		Local type:=scope.FindType( ident )
		If Not type Throw New TypeIdentEx( ident )
		
		Return type
	End
	
End

Class FuncTypeExpr Extends TypeExpr

	Field retType:TypeExpr
	Field params:VarDecl[]

	Method New( retType:TypeExpr,params:VarDecl[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.retType=retType
		Self.params=params
	End

	Method ToString:String() Override
		Local str:=""
		If retType str=retType.ToString()
		Return str+"("+Join( params )+")"
	End

	Method OnSemant:Type( scope:Scope ) Override

		Local retType:=Self.retType.Semant( scope )
		
		Local argTypes:=New Type[params.Length]
		For Local i:=0 Until argTypes.Length
			argTypes[i]=params[i].type.Semant( scope )
		Next
		
		Return New FuncType( retType,argTypes )
	End
	
End

Class MemberTypeExpr Extends TypeExpr

	Field type:TypeExpr
	Field ident:String
	
	Method New( type:TypeExpr,ident:String,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.type=type
		Self.ident=ident
	End
	
	Method ToString:String() Override
		Return type.ToString()+"."+ident
	End
	
	Method OnSemant:Type( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope )
		
		type=type.FindType( ident )
		If Not type Throw New TypeIdentEx( ident )
		
		Return type
	End
	
End

Class ArrayTypeExpr Extends TypeExpr

	Field type:TypeExpr
	Field rank:Int
	
	Method New( type:TypeExpr,rank:Int,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.type=type
		Self.rank=rank
	End
	
	Method ToString:String() Override
		Return type.ToString()+"[,,,,,,,,,,,".Slice( 0,rank )+"]"
	End
	
	Method OnSemant:Type( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope )
		
		Return New ArrayType( type,rank )
	End

End

Class GenericTypeExpr Extends TypeExpr

	Field type:TypeExpr
	Field args:TypeExpr[]
	
	Method New( type:TypeExpr,args:TypeExpr[],srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		Self.type=type
		Self.args=args
	End
	
	Method ToString:String() Override
		Return type.ToString()+"<"+Join( args )+">"
	End
	
	Method OnSemant:Type( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope,True )
		
		Local args:=New Type[Self.args.Length]
		For Local i:=0 Until args.Length
			args[i]=Self.args[i].Semant( scope )
		Next
		
		Return type.GenInstance( args )
	End

End

Class PointerTypeExpr Extends TypeExpr

	Field type:TypeExpr
	
	Method New( type:TypeExpr,srcpos:Int,endpos:Int )
		Super.New( srcpos,endpos )
		
		Self.type=type
	End
	
	Method ToString:String() Override
		Return type.ToString()+" Ptr"
	End
	
	Method OnSemant:Type( scope:Scope ) Override
	
		Local type:=Self.type.Semant( scope )
		
		Return New PointerType( type )
	End
End
