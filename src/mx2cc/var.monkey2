
Namespace mx2

Class VarDecl Extends Decl

	Field type:TypeExpr
	Field init:Expr
	
	Method ToString:String() Override
	
		Local str:=""
		If kind="param"
			str=ident
		Else
			str=Super.ToString()
		Endif
		
		If type
			If str str+=":"
			str+=type.ToString()
			If init str+="="+init.ToString()
		Else If init
			str+=":="+init.ToString()
		Endif
		
		Return str
	End
	
	Method ToNode:SNode( scope:Scope ) Override
	
		Return New VarValue( Self,scope )
	End

End

Class VarValue Extends Value

	Field vdecl:VarDecl
	Field scope:Scope
	Field transFile:FileDecl
	Field cscope:ClassScope
	
	Field init:Value
	
	Method New( vdecl:VarDecl,scope:Scope )

		Self.pnode=vdecl
		Self.vdecl=vdecl
		Self.scope=scope
		Self.transFile=scope.FindFile().fdecl
		Self.cscope=Cast<ClassScope>( scope )
		
		If vdecl.kind="global" Or vdecl.kind="local" Or vdecl.kind="param" flags|=VALUE_LVALUE|VALUE_ASSIGNABLE
	End
	
	Method New( kind:String,ident:String,init:Value,scope:Scope )

		vdecl=New VarDecl
		vdecl.kind=kind
		vdecl.ident=ident
		
		Self.pnode=vdecl
		Self.type=init.type
		Self.scope=scope
		Self.cscope=Cast<ClassScope>( scope )
		Self.init=init
		
		If vdecl.kind="global" Or vdecl.kind="local" Or vdecl.kind="param" flags|=VALUE_LVALUE|VALUE_ASSIGNABLE
		
		semanted=Self
	End
	
	Property IsField:Bool()
		Return vdecl.kind="field"
	End
	
	Method OnSemant:SNode() Override
	
		If vdecl.type
			type=vdecl.type.Semant( scope )
			If vdecl.init init=vdecl.init.SemantRValue( scope,type )
		Else If vdecl.init
			init=vdecl.init.SemantRValue( scope )
			If TCast<VoidType>( init.type ) Throw New SemantEx( "Variables cannot have 'Void' type" )
			type=init.type
		Else 
			SemantError( "VarValue.OnSemant()" )
		Endif
		
		If Not type.IsGeneric And Not vdecl.IsExtern And Not Cast<Block>( scope )
		
			If vdecl.kind="global" Or vdecl.kind="const"
				transFile.globals.Push( Self )
			Else
				scope.transMembers.Push( Self )
			Endif
			
		Endif
	
		Return Self
	End
	
	Property Name:String()
		Return vdecl.ident+":"+type.Name
	End
	
	Method ToString:String() Override
		Return vdecl.ident
	End
	
	Method ToValue:Value( instance:Value ) Override
	
		If vdecl.kind="field"
		
			If Not instance Throw New SemantEx( "Field '"+vdecl.ident+"' cannot be accessed without an instance" )
		
			If Not instance.type.ExtendsType( cscope.ctype )
				Throw New SemantEx( "Field '"+vdecl.ident+"' cannot be accessed from an instance of a different class" )
			Endif

			Return New MemberVarValue( instance,Self )
			
		Endif
		
		Return Self
	End
	
	Method CheckAccess( tscope:Scope ) Override
		CheckAccess( vdecl,scope,tscope )
	End
	
End

Class MemberVarValue Extends Value

	Field instance:Value
	Field member:VarValue

	Method New( instance:Value,member:VarValue )
		Self.type=member.type
		Self.instance=instance
		Self.member=member
		
		If member.vdecl.kind="field"
			If member.cscope.ctype.IsStruct
				If instance.IsLValue flags|=VALUE_LVALUE
				If instance.IsAssignable flags|=VALUE_ASSIGNABLE
			Else
				flags|=VALUE_LVALUE|VALUE_ASSIGNABLE
			Endif
		Endif
	End
	
	Method ToString:String() Override
		Return instance.ToString()+"."+type.ToString()
	End
	
	Property HasSideEffects:Bool() Override
		Return instance.HasSideEffects
	End
	
	Method CheckAccess( tscope:Scope ) Override
		member.CheckAccess( tscope )
	End

End
