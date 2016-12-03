
Namespace ted2go


Enum CodeSortType
	Type,
	Alpha,
	Source
End


Class CodeTreeView Extends TreeViewExt
	
	Field SortType:=CodeSortType.Type
	
	Method Fill( fileType:String,path:String )
	
		StoreTreeExpands()
		
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
		
	End
	
	Method SelectByScope( scope:CodeItem )
	
		Local node:=FindNode( RootNode,scope )
		If Not node Return
		
		Selected=node
	End
	
	
	Private
	
	Field _expands:=New StringMap<Bool>
	
	
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
	
	Method StoreTreeExpands()
	
		_expands.Clear()
		StoreNodeExpand( RootNode )
		
	End
	
	Method StoreNodeExpand( node:TreeView.Node )
		
		If Not node.Expanded Return
		
		Local key:=GetNodePath( node )
		_expands[key]=node.Expanded
		
		If node.Children = Null Return
		
		For Local i:=Eachin node.Children
			StoreNodeExpand( i )
		Next
		
	End
	
	Method RestoreNodeExpand( node:TreeView.Node )
	
		Local key:=GetNodePath( node )
		node.Expanded=_expands[key]
		
	End
	
	Method GetNodePath:String( node:TreeView.Node )
	
		Local s:=node.Text
		Local i:=node.Parent
		While i <> Null
			s=i.Text+"\"+s
			i=i.Parent
		Wend
		Return s
		
	End
		
	Method AddTreeItem( item:CodeItem,node:TreeView.Node,parser:ICodeParser )
	
		'parser.RefineRawType( item ) 'refine all visible items
		
		Local n:=New CodeTreeNode( item,node )
		
		' restore expand state
		RestoreNodeExpand( n )
		
		If item.Children = Null Return
		
		' sorting only root class members
		Select item.Kind
			Case CodeItemKind.Class_,CodeItemKind.Struct_,CodeItemKind.Enum_
				SortItems( item.Children )
		End
		
		For Local i:=Eachin item.Children
			If i.Kind = CodeItemKind.Param_ Continue
			AddTreeItem( i,n,parser )
		End
				
	End
	
	Method SortItems( list:List<CodeItem> )
	
		If SortType <> CodeSortType.Type Return
	
		CodeItemsSorter.SortItems( list )
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
