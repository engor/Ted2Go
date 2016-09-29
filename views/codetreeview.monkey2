
Namespace ted2go



Class CodeTreeView Extends TreeView

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

