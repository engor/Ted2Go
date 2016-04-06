
Namespace std.collections

Alias IntMap<V>:Map<Int,V>
Alias FloatMap<V>:Map<Float,V>
Alias StringMap<V>:Map<String,V>

#rem monkeydoc The Map class.
#end
Class Map<K,V>

	#rem monkeydoc The map Node class.
	#end
	Class Node
	
		#rem monkeydoc Gets the key contained in the node.
		
		@return The node's key.
		
		#end
		Property Key:K()
			Return _key
		End
		
		#rem monkeydoc Gets the value contained in the node.
		
		@return The node's value.
		
		#end
		Property Value:V()
			Return _value
		End
	
		Private	
	
		Enum Color
			Red
			Black
		End
	
		Field _key:K
		Field _value:V
		Field _color:Color
		Field _left:Node
		Field _right:Node
		Field _parent:Node
	
		Method New( key:K,value:V,color:Color,parent:Node )
			_key=key
			_value=value
			_color=color
			_parent=parent
		End
		
		Method Count:Int( n:Int )
			If _left n=_left.Count( n )
			If _right n=_right.Count( n )
			Return n+1
		End
	
		Method NextNode:Node()
			If _right
				Local node:=_right
				While node._left
					node=node._left
				Wend
				Return node
			Endif
			Local node:=Self,parent:=_parent
			While parent And node=parent._right
				node=parent
				parent=parent._parent
			Wend
			Return parent
		End
		
		Method PrevNode:Node()
			If _left
				Local node:=_left
				While node._right
					node=node._right
				Wend
				Return node
			Endif
			Local node:=Self,parent:=_parent
			While parent And node=parent._left
				node=parent
				parent=parent._parent
			Wend
			Return parent
		End
		
		Method Copy:Node( parent:Node )
			Local t:=New Node( _key,_value,_color,_parent )
			If _left t._left=_left.Copy( t )
			If _right t._right=_right.Copy( t )
			Return t
		End
	
	End
	
	Struct Iterator
	
		Property Valid:Bool()
			Return _node
		End
		
		Property Current:Node()
			Return _node
		End
		
		Method Bump()
			_node=_node.NextNode()
		End
		
		Private
		
		Field _node:Node
		
		Method New( node:Node )
			_node=node
		End
		
	End
	
	Struct KeyIterator
	
		Property Valid:Bool()
			Return _node
		End
		
		Property Current:K()
			Return _node._key
		End
		
		Method Bump()
			_node=_node.NextNode()
		End
		
		Private
		
		Field _node:Node
		
		Method New( node:Node )
			_node=node
		End
		
	End
	
	Struct ValueIterator
	
		Property Valid:Bool()
			Return _node
		End
		
		Property Current:V()
			Return _node._value
		End
		
		Method Bump()
			_node=_node.NextNode()
		End
		
		Private
		
		Field _node:Node
		
		Method New( node:Node )
			_node=node
		End
		
	End
	
	Struct MapKeys
	
		Method All:KeyIterator()
			Return New KeyIterator( _map.FirstNode() )
		End
		
		Private
		
		Field _map:Map
		
		Method New( map:Map )
			_map=map
		End
		
	End
	
	Struct MapValues
	
		Method All:ValueIterator()
			Return New ValueIterator( _map.FirstNode() )
		End
		
		Private
		
		Field _map:Map
		
		Method New( map:Map )
			_map=map
		End
		
	End
	
	#rem monkeydoc Creates a new empty map.
	#end
	Method New()
	End
	
	#rem monkeydoc Gets a node iterator.
	
	#end
	
	Method All:Iterator()
		Return New Iterator( FirstNode() )
	End
	
	#rem monkeydoc Gets a view of the map's keys.
	
	The returned value can be used with an Eachin loop to iterate over the map's keys.
	
	@return A MapKeys object.

	#end
	Property Keys:MapKeys()
		Return New MapKeys( Self )
	End

	#rem monkeydoc Gets a view of the map's values.
	
	The returned value can be used with an Eachin loop to iterate over the map's values.
	
	@return A MapValues object.
	
	#end	
	Property Values:MapValues()
		Return New MapValues( Self )
	End
	
	#rem monkeydoc Removes all keys from the map.
	#end
	Method Clear()
		_root=Null
	End
	
	#rem monkeydoc Gets the number of keys in the map.
	
	@return The number of keys in the map.
	
	#end
	Method Count:Int()
		If Not _root Return 0
		Return _root.Count( 0 )
	End

	#rem monkeydoc Checks if the map is empty.
	
	@return True if the map is empty.
	
	#end
	Property Empty:Bool()
		Return _root=Null
	End

	#rem monkeydoc Checks if the map contains a given key.
	
	@param key The key to check for.
	
	@return True if the map contains the key.
	
	#end
	Method Contains:Bool( key:K )
		Return FindNode( key )<>Null
	End
	
	#rem monkeydoc Sets the value associated with a key in the map.
	
	If the map does not contain `key`, a new key/value node is added and true is returned.
	
	If the map already contains `key`, its associated value is updated and false is returned.
	
	This operator functions identically to Set.
	
	@param key The key.
	
	@param value The value.
	
	@return True if a new node was added to the map.
	
	#end
	Operator[]=( key:K,value:V )
		Set( key,value )
	End

	#rem monkeydoc Gets the value associated with a key in the map.
	
	@param key The key.
	
	@return The value associated with `key`, or null if `key` is not in the map.
	
	#end
	Operator[]:V( key:K )
		Local node:=FindNode( key )
		If Not node Return Null
		Return node._value
	End
	
	#rem monkeydoc Sets the value associated with a key in the map.
	
	If the map does not contain `key`, a new key/value node is added to the map and true is returned.
	
	If the map already contains `key`, its associated value is updated and false is returned.
	
	@param key The key.
	
	@param value The value.
	
	@return True if a new node was added to the map, false if an existing node was updated.
	
	#end
	Method Set:Bool( key:K,value:V )
		If Not _root
			_root=New Node( key,value,Node.Color.Red,Null )
			Return True
		Endif
	
		Local node:=_root,parent:Node,cmp:Int

		While node
			parent=node
			cmp=key<=>node._key
			If cmp>0
				node=node._right
			Else If cmp<0
				node=node._left
			Else
				node._value=value
				Return False
			Endif
		Wend
		
		node=New Node( key,value,Node.Color.Red,parent )
		
		If cmp>0 parent._right=node Else parent._left=node
		
		InsertFixup( node )
		
		Return True
	End
	
	#rem monkeydoc Adds a new key/value pair to a map.
	
	If the map does not contain `key', a new key/value node is created and true is returned.
	
	If the map already contains `key`, nothing happens and false is returned.
	
	@param key The key.
	
	@param value The value.
	
	@return True if a new node was added to the map, false if the map was not modified.
	
	#end
	Method Add:Bool( key:K,value:V )
		If Not _root
			_root=New Node( key,value,Node.Color.Red,Null )
			Return True
		Endif
	
		Local node:=_root,parent:Node,cmp:Int

		While node
			parent=node
			cmp=key<=>node._key
			If cmp>0
				node=node._right
			Else If cmp<0
				node=node._left
			Else
				Return False
			Endif
		Wend
		
		node=New Node( key,value,Node.Color.Red,parent )
		
		If cmp>0 parent._right=node Else parent._left=node
		
		InsertFixup( node )
		
		Return True
	End
	
	#rem monkeydoc Updates the value associated with a key in the map.

	If the map does not contain `key', nothing happens and false is returned.
	
	If the map already contains `key`, its associated value is updated and true is returned.
	
	@param key The key.
	
	@param value The value.
	
	@return True if the value associated with `key` was updated, false if the map was not modified.
	
	#end
	Method Update:Bool( key:K,value:V )
		Local node:=FindNode( key )
		If Not node Return False
		node._value=value
		Return True
	End
	
	#rem monkeydoc Gets the value associated with a key in the map.
	
	@param key The key.
	
	@return The value associated with the key, or null if the key is not in the map.
	
	#end
	Method Get:V( key:K )
		Local node:=FindNode( key )
		If node Return node._value
		Return Null
	End
	
	#rem monkeydoc Removes a key from the map.
	
	@param key The key to remove.
	
	@return True if the key was removed, or false if the key is not in the map.
	
	#end
	Method Remove:Bool( key:K )
		Local node:=FindNode( key )
		If Not node Return False
		RemoveNode( node )
		Return True
	End
	
	Private
	
	Method FirstNode:Node()
		If Not _root Return Null

		Local node:=_root
		While node._left
			node=node._left
		Wend
		Return node
	End
	
	Method LastNode:Node()
		If Not _root Return Null

		Local node:=_root
		While node._right
			node=node._right
		Wend
		Return node
	End
	
	Method FindNode:Node( key:K )
		Local node:=_root
		While node
			Local cmp:=key<=>node._key
			If cmp>0
				node=node._right
			Else If cmp<0
				node=node._left
			Else
				Return node
			Endif
		Wend
		Return Null
	End
	
	Method RemoveNode( node:Node )
		Local splice:Node,child:Node
		
		If Not node._left
			splice=node
			child=node._right
		Else If Not node._right
			splice=node
			child=node._left
		Else
			splice=node._left
			While splice._right
				splice=splice._right
			Wend
			child=splice._left
			node._key=splice._key
			node._value=splice._value
		Endif
		
		Local parent:=splice._parent
		
		If child
			child._parent=parent
		Endif
		
		If Not parent
			_root=child
			Return
		Endif
		
		If splice=parent._left
			parent._left=child
		Else
			parent._right=child
		Endif
		
		If splice._color=Node.Color.Black 
			DeleteFixup( child,parent )
		Endif
	End
	
	Field _root:Node
	
	Method RotateLeft( node:Node )
		Local child:=node._right
		node._right=child._left
		If child._left
			child._left._parent=node
		Endif
		child._parent=node._parent
		If node._parent
			If node=node._parent._left
				node._parent._left=child
			Else
				node._parent._right=child
			Endif
		Else
			_root=child
		Endif
		child._left=node
		node._parent=child
	End
	
	Method RotateRight( node:Node )
		Local child:=node._left
		node._left=child._right
		If child._right
			child._right._parent=node
		Endif
		child._parent=node._parent
		If node._parent
			If node=node._parent._right
				node._parent._right=child
			Else
				node._parent._left=child
			Endif
		Else
			_root=child
		Endif
		child._right=node
		node._parent=child
	End
	
	Method InsertFixup( node:Node )
		While node._parent And node._parent._color=Node.Color.Red And node._parent._parent
			If node._parent=node._parent._parent._left
				Local uncle:=node._parent._parent._right
				If uncle And uncle._color=Node.Color.Red
					node._parent._color=Node.Color.Black
					uncle._color=Node.Color.Black
					uncle._parent._color=Node.Color.Red
					node=uncle._parent
				Else
					If node=node._parent._right
						node=node._parent
						RotateLeft( node )
					Endif
					node._parent._color=Node.Color.Black
					node._parent._parent._color=Node.Color.Red
					RotateRight( node._parent._parent )
				Endif
			Else
				Local uncle:=node._parent._parent._left
				If uncle And uncle._color=Node.Color.Red
					node._parent._color=Node.Color.Black
					uncle._color=Node.Color.Black
					uncle._parent._color=Node.Color.Red
					node=uncle._parent
				Else
					If node=node._parent._left
						node=node._parent
						RotateRight( node )
					Endif
					node._parent._color=Node.Color.Black
					node._parent._parent._color=Node.Color.Red
					RotateLeft( node._parent._parent )
				Endif
			Endif
		Wend
		_root._color=Node.Color.Black
	End
	
	Method DeleteFixup( node:Node,parent:Node )
	
		While node<>_root And (Not node Or node._color=Node.Color.Black )

			If node=parent._left
			
				Local sib:=parent._right
				
				If sib._color=Node.Color.Red
					sib._color=Node.Color.Black
					parent._color=Node.Color.Red
					RotateLeft( parent )
					sib=parent._right
				Endif
				
				If (Not sib._left Or sib._left._color=Node.Color.Black) And (Not sib._right Or sib._right._color=Node.Color.Black)
					sib._color=Node.Color.Red
					node=parent
					parent=parent._parent
				Else
					If Not sib._right Or sib._right._color=Node.Color.Black
						sib._left._color=Node.Color.Black
						sib._color=Node.Color.Red
						RotateRight( sib )
						sib=parent._right
					Endif
					sib._color=parent._color
					parent._color=Node.Color.Black
					sib._right._color=Node.Color.Black
					RotateLeft( parent )
					node=_root
				Endif
			Else	
				Local sib:=parent._left
				
				If sib._color=Node.Color.Red
					sib._color=Node.Color.Black
					parent._color=Node.Color.Red
					RotateRight( parent )
					sib=parent._left
				Endif
				
				If (Not sib._right Or sib._right._color=Node.Color.Black) And (Not sib._left Or sib._left._color=Node.Color.Black)
					sib._color=Node.Color.Red
					node=parent
					parent=parent._parent
				Else
					If Not sib._left Or sib._left._color=Node.Color.Black
						sib._right._color=Node.Color.Black
						sib._color=Node.Color.Red
						RotateLeft( sib )
						sib=parent._left
					Endif
					sib._color=parent._color
					parent._color=Node.Color.Black
					sib._left._color=Node.Color.Black
					RotateRight( parent )
					node=_root
				Endif
			Endif
		Wend
		If node node._color=Node.Color.Black
	End
	
End

#rem
Class IntMap<T> Extends Map<Int,T>
End

Class FloatMap<T> Extends Map<Float,T>
End

Class StringMap<T> Extends Map<String,T>
End
#end
