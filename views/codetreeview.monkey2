
Namespace ted2go



Class CodeTreeView Extends TreeViewExt
	
	Method Fill(fileType:String, path:String)
	
		StoreTreeExpands()
		
		Local stack := New Stack<TreeView.Node>
		Local parser := ParsersManager.Get(fileType)
		Local node := RootNode
		
		RootNodeVisible = False
		node.Expanded = True
		node.RemoveAllChildren()
		
		Local list := parser.ItemsMap[path]
		If list = Null Return
		
		For Local i := Eachin list
			AddTreeItem(i, node, parser)
		Next
		
	End
	
	
	Private
	
	Field _expands := New StringMap<Bool>
	Method StoreTreeExpands()
	
		_expands.Clear()
		StoreNodeExpand( RootNode )
		
	End
	
	Method StoreNodeExpand(node:TreeView.Node)
		
		If Not node.Expanded Return
		
		Local key := GetNodePath(node)
		_expands[key] = node.Expanded
		
		If node.Children = Null Return
		
		For Local i := Eachin node.Children
			StoreNodeExpand(i)
		Next
		
	End
	
	Method RestoreNodeExpand(node:TreeView.Node)
	
		Local key := GetNodePath(node)
		node.Expanded = _expands[key]
		
	End
	
	Method GetNodePath:String(node:TreeView.Node)
	
		Local s := node.Text
		Local i := node.Parent
		While i <> Null
			s = i.Text+"\"+s
			i = i.Parent
		Wend
		Return s
		
	End
		
	Method AddTreeItem(item:ICodeItem, node:TreeView.Node, parser:ICodeParser)
	
		parser.RefineRawType(item) 'refine all visible items
		
		Local n := New CodeTreeNode(item, node)
		
		' restore expand state
		RestoreNodeExpand(n)
		
		If item.Children = Null Return
		
		For Local i := Eachin item.Children
			AddTreeItem(i, n, parser)
		End
		
	End
	
End


Class CodeTreeNode Extends TreeView.Node

	Method New(item:ICodeItem, node:TreeView.Node)
		Super.New(item.Text, node)
		_code = item
		Icon = CodeItemIcons.GetIcon(item)
		
	End
	
	Property CodeItem:ICodeItem()
		Return _code
	End
	
	
	Private
	
	Field _code:ICodeItem
	
End

