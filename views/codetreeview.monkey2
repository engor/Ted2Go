
Namespace ted2go


Class CodeTreeView Extends TreeView

End


Class CodeTreeNode Extends TreeView.Node

	Method New(item:ICodeItem, node:TreeView.Node)
		Super.New(item.Ident, node)
		_code = item
	End
	
	Property CodeItem:ICodeItem()
		Return _code
	End
	
	
	Private
	
	Field _code:ICodeItem
	
End
