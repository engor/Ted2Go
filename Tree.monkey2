
Namespace ted2go


Class Tree
	
	Class Node
		
		Field Text:String
		Field UserData:Variant
		
		Property Children:Stack<Node>()
			Return _children
		End
		
		Property NumChildren:Int()
			Return Children?.Length
		End
		
		Property Parent:Node()
			Return _parent
		Setter( value:Node )
			If _parent Then _parent-=Self
			_parent=value
			If _parent Then _parent+=Self
		End
		
		Property ParentsHierarchy:Stack<Node>()
			
			Local result:=New Stack<Node>
			Local p:=_parent
			While p
				result.Insert( 0,p )
				p=p.Parent
			Wend
			Return result
		End
		
		Method New( text:String,parent:Node=Null,userData:Variant=Null )
			
			Text=text
			Parent=parent
			UserData=userData
		End
		
		Method GetUserData<T>:T()
			
			Return UserData ? Cast<T>( UserData ) Else Null
		End
		
		Operator +=( child:Node )
			
			If Not _children Then _children=New Stack<Node>
			_children.Add( child )
		End
		
		Operator -=( child:Node )
			
			If Not _children Return
			_children.Remove( child )
		End
		
		Method Clear()
			
			_children?.Clear()
		End
		
		
		Private
		
		Field _parent:Node
		Field _children:Stack<Node>
		
	End
	
	Method New()
		
		_root=New Node( "" )
	End
	
	Property RootNode:Node()
		Return _root
	End
	
	Method Clear()
	
		_root.Clear()
	End
	
	Private
	
	Field _root:Node
	
End
