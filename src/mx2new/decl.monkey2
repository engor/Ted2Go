
Namespace mx2

Const DECL_PUBLIC:=		$000001
Const DECL_PRIVATE:=	$000002
Const DECL_PROTECTED:=	$000004
Const DECL_INTERNAL:=	$000008

Const DECL_VIRTUAL:=	$000100
Const DECL_OVERRIDE:=	$000200
Const DECL_ABSTRACT:=	$000400
Const DECL_FINAL:=		$000800
Const DECL_EXTERN:=		$001000
Const DECL_EXTENSION:=	$002000
Const DECL_DEFAULT:=	$004000

Const DECL_GETTER:=		$010000
Const DECL_SETTER:=		$020000
Const DECL_OPERATOR:=	$040000
Const DECL_IFACEMEMBER:=$080000

Const DECL_ACCESSMASK:=DECL_PUBLIC|DECL_PRIVATE|DECL_PROTECTED|DECL_INTERNAL

Class Decl Extends PNode

	Field kind:String
	Field ident:String
	Field flags:Int
	Field symbol:String
	Field docs:String
	
	Field members:Decl[]
	
	Property IsExtern:Bool()
		Return (flags & DECL_EXTERN)<>0
	End
	
	Property IsPublic:Bool()
		Return (flags & DECL_PUBLIC)<>0
	End
	
	Property IsPrivate:Bool()
		Return (flags & DECL_PRIVATE)<>0
	End

	Property IsProtected:Bool()
		Return (flags & DECL_PROTECTED)<>0
	End
	
	Property IsInternal:Bool()
		Return (flags & DECL_INTERNAL)<>0
	End
	
	Property IsVirtual:Bool()
		Return (flags & DECL_VIRTUAL)<>0
	End
	
	Property IsOverride:Bool()
		Return (flags & DECL_OVERRIDE)<>0
	End
	
	Property IsAbstract:Bool()
		Return (flags & DECL_ABSTRACT)<>0
	End
	
	Property IsFinal:Bool()
		Return (flags & DECL_FINAL)<>0
	End
	
	Property IsGetter:Bool()
		Return (flags & DECL_GETTER)<>0
	End
	
	Property IsSetter:Bool()
		Return (flags & DECL_SETTER)<>0
	End
	
	Property IsOperator:Bool()
		Return (flags & DECL_OPERATOR)<>0
	End
	
	Property IsIfaceMember:Bool()
		Return (flags &DECL_IFACEMEMBER)<>0
	End
	
	Property IsExtension:Bool()
		Return (flags & DECL_EXTENSION)<>0
	End
	
	Property IsDefault:Bool()
		Return (flags & DECL_DEFAULT)<>0
	End
	
	Method ToString:String() Override
		Return kind.Capitalize()+" "+ident
	End
	
	Method Emit( buf:StringStack,spc:String ) Virtual
	
		buf.Push( spc+ToString() )
		
		spc+="  "
		For Local member:=Eachin members
			member.Emit( buf,spc )
		Next
	End
	
	Method ToNode:SNode( scope:Scope ) Virtual
		Return Null
	End

End

Class FileDecl Extends Decl

	Field path:String
	Field nmspace:String
	Field usings:String[]
	Field imports:String[]
	Field errors:ParseEx[]

	Field module:Module	
	Field exhfile:String	
	Field hfile:String
	Field cfile:String
	Field classes:=New Stack<ClassType>
	Field functions:=New Stack<FuncValue>
	Field globals:=New Stack<VarValue>

End
