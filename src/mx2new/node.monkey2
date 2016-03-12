
Namespace mx2

Const DEBUG_SEMANTS:=False'True

Class PNode

	Field srcfile:FileDecl
	Field srcpos:Int
	Field endpos:Int
	
	Global parsing:FileDecl
	Global semanting:=New Stack<PNode>
	
	Method New()
		Self.srcfile=parsing
	End
	
	Method New( srcpos:Int,endpos:Int )
		Self.srcfile=parsing
		Self.srcpos=srcpos
		Self.endpos=endpos
	End

	Method ToString:String() Virtual
		If srcfile Return srcfile.path+" ["+(srcpos Shr 12)+"]"
		Return "? ["+(srcpos Shr 12)+"]"
	End

	Method ToDebugString:String() Virtual
		If srcfile Return srcfile.path+" ["+(srcpos Shr 12)+"]"
		Return "? ["+(srcpos Shr 12)+"]"
	End
End

Const SNODE_INIT:=0
Const SNODE_SEMANTING:=1
Const SNODE_SEMANTED:=2

Class SNode

	Field pnode:PNode
	Field semanted:SNode
	Field state:Int
	
	Global semtab:String

	Method Semant:SNode()
	
		If state=SNODE_SEMANTED Or semanted Return semanted
		
		If state=SNODE_SEMANTING Throw New SemantEx( "Cyclic declaration of '"+ToString()+"'" )'"+pnode.ToString()+"'" )
		
		Try
					
			If DEBUG_SEMANTS And pnode
				Print semtab+"Semanting  "+pnode.ToString()
				semtab+="  "
			Endif

			state=SNODE_SEMANTING
			PNode.semanting.Push( pnode )
		
			semanted=OnSemant()

			PNode.semanting.Pop()
			state=SNODE_SEMANTED
			
			If DEBUG_SEMANTS And pnode 
				semtab=semtab.Slice( 0,-2 )
				Print semtab+"Semanted   "+semanted.ToString()
			Endif
			
			Return semanted

		Catch ex:SemantEx
		
			PNode.semanting.Pop()
			state=SNODE_SEMANTED
			
			If DEBUG_SEMANTS And pnode
				semtab=semtab.Slice( 0,-2 )
				Print semtab+"Semant failed for "+pnode.ToString()
			Endif
		
			Throw ex
		End
		
		Return Null
	End
	
	Method OnSemant:SNode() Virtual
		Return Self
	End
	
	Method ToString:String() Virtual
		If pnode Return pnode.ToString()
		Print String.FromCString( typeName() )
		Return "????? SNode.ToString() ?????"
	End
	
	Method ToType:Type() Virtual
		SemantError( "SNode.ToType()" )
		Return Null
	End
	
	Method ToValue:Value( instance:Value ) Virtual
		Print String.FromCString( typeName() )
		SemantError( "SNode.ToValue()" )
		Return Null
	End
	
End
