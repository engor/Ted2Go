
Namespace ted2go


Class CodeTreeView Extends TreeViewExt
	
	Field SortByType:=True
	Field ShowInherited:=False
	
	
	Method New()
		
		_expander=New TreeViewExpander( Self )
	End
	
	Method Fill( fileType:String,path:String,expandIfOnlyOneItem:Bool=True )
	
		_expander.Store()
		
		Local stack:=New Stack<TreeView.Node>
		Local parser:=ParsersManager.Get( fileType )
		Local node:=RootNode
		
		RootNodeVisible=False
		node.Expanded=True
		node.RemoveAllChildren()
		
		Local list:=parser.ItemsMap[path]
		If list = Null Return
		
		' sorting
		SortItems( list )
		
		For Local i:=Eachin list
			AddTreeItem( i,node,parser )
		Next
		
		If expandIfOnlyOneItem And RootNode.NumChildren=1
			RootNode.Children[0].Expanded=True
		Endif
	End
	
	Method SelectByScope( scope:CodeItem )
	
		Local node:=FindNode( RootNode,scope )
		If Not node Return
		
		Selected=node
	End
	
	
	Private
	
	Field _expander:TreeViewExpander
	
	
	Method FindNode:TreeView.Node( treeNode:TreeView.Node,item:CodeItem )
	
		Local node:=Cast<CodeTreeNode>(treeNode)
		
		If node And node.CodeItem = item Return node
	
		Local list:=treeNode.Children
		If Not list Return Null
		
		For Local i:=Eachin list
			Local n:=FindNode( i,item )
			If n Return n
		Next
	
		Return Null
	End
	
	Method AddTreeItem( item:CodeItem,node:TreeView.Node,parser:ICodeParser )
	
		Local n:=New CodeTreeNode( item,node )
		
		' restore expand state
		_expander.RestoreNode( n )
		
		If item.Children = Null And Not ShowInherited Return
		
		Local list:=New List<CodeItem>
		
		If item.Children<>Null Then list.AddAll( item.Children )
		
		Local inherRoot:CodeItem=Null
		
		' sorting only root class members
		If item.IsLikeClass
				
			SortItems( list )
			
			If ShowInherited
				Local lst:=New List<CodeItem>
				GetInherited( item,parser,lst )
				If lst<>Null And Not lst.Empty
					inherRoot=New CodeItem( "[ Inherited members ]" )
					inherRoot.Children=lst
					inherRoot.KindStr="inherited"
					list.AddFirst( inherRoot )
					'For Local i:=Eachin lst
					'	Local children:=i.Children
					'	
					'Next
				Endif
			Endif
		End
		
		If list.Empty Return
		
		Local added:=New StringStack
		For Local i:=Eachin list
			If i.Kind = CodeItemKind.Param_ Continue
			Local txt:=i.Text
			If added.Contains( txt ) Continue
			added.Add( txt )
			AddTreeItem( i,n,parser )
		End
		
	End
	
	Method SortItems( list:List<CodeItem> )
	
		If SortByType
			CodeItemsSorter.SortByType( list,False,True )
		Else
			CodeItemsSorter.SortByPosition( list )
		End
	End
	
	Method GetInherited:List<CodeItem>( item:CodeItem,parser:ICodeParser,result:List<CodeItem> )
	
		If item.SuperTypesStr=Null Return Null
	
		For Local t:=Eachin item.SuperTypesStr
			Local sup:=parser.GetItem( t )
			If Not sup Continue
			If sup.Children<>Null
				Local it:=New CodeItem( t )
				it.KindStr=sup.KindStr
				it.Children=sup.Children
				result.Add( it )
				'Local list:=New List<CodeItem>
				'For Local child:=Eachin sup.Children
					' grab some properties
					'it=New CodeItem( child.Ident)
					'it.KindStr=child.KindStr
					'it.Type=child.Type
					'it.FilePath=child.FilePath
					'it.ScopeStartPos=child.ScopeStartPos
					
				'Next
			Endif
			If sup.IsLikeClass Then GetInherited( sup,parser,result )
		Next
		Return result
	End
End


Class CodeTreeNode Extends TreeView.Node

	Method New( item:CodeItem,node:TreeView.Node )
		Super.New( item.Text,node )
		_code=item
		Icon=CodeItemIcons.GetIcon( item )
		
	End
	
	Property CodeItem:CodeItem()
		Return _code
	End
	
	
	Private
	
	Field _code:CodeItem
	
End


Class TreeViewExpander
	
	Method New( tree:TreeView )
		
		_tree=tree
	End
	
	Method Store()
	
		_expands.Clear()
		StoreNode( _tree.RootNode )
	End
	
	Method Restore()
	
		RestoreNode( _tree.RootNode )
	End
	
	Method RestoreNode( node:TreeView.Node )
	
		Local key:=GetNodePath( node )
		node.Expanded=_expands[key]
		
		If node.Children = Null Return
		
		For Local i:=Eachin node.Children
			RestoreNode( i )
		Next
	End
	
	Private
	
	Field _tree:TreeView
	Field _expands:=New StringMap<Bool>
	
	Method GetNodePath:String( node:TreeView.Node )
	
		Local s:=node.Text
		Local i:=node.Parent
		While i <> Null
			s=i.Text+"\"+s
			i=i.Parent
		Wend
		Return s
	End
	
	Method StoreNode( node:TreeView.Node )
	
		If Not node.Expanded Return
	
		Local key:=GetNodePath( node )
		_expands[key]=node.Expanded
	
		If node.Children = Null Return
	
		For Local i:=Eachin node.Children
			StoreNode( i )
		Next
	End
	
End

