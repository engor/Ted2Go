
Namespace mojox

Class FileBrowser Extends TreeView

	Field FileClicked:Void( path:String,event:MouseEvent )

	Method New( rootPath:String="." )
	
		Style=Style.GetStyle( "mojo.FileBrowser" )
	
		_rootNode=New Node( Null )
		
		RootPath=rootPath

		NodeClicked=OnNodeClicked
		NodeToggled=OnNodeToggled
		
		RootNode=_rootNode
		
		Update()
	End
	
	Property RootPath:String()
	
		Return _rootPath
	
	Setter( path:String )
	
		_rootPath=path
		
		_rootNode._path=path
		_rootNode.Label=_rootPath
	End
	
	Method Update()
	
		UpdateNode( _rootNode,_rootPath,True )
	End

	Private
	
	Class Node Extends TreeView.Node
	
		Method New( parent:Node )
			Super.New( "",parent )
		End
		
		Private
		
		Field _path:String
	
	End
	
	Field _rootNode:Node
	Field _rootPath:String
	
	Method OnNodeClicked( tnode:TreeView.Node,event:MouseEvent )
	
		Local node:=Cast<Node>( tnode )
		If Not node Return
		
		FileClicked( node._path,event )
	End
	
	Method OnNodeToggled( tnode:TreeView.Node,event:MouseEvent )

		Local node:=Cast<Node>( tnode )
		If Not node Return
	
		If node.Expanded
			UpdateNode( node,node._path,True )
		Else
			For Local child:=Eachin node.Children
				child.RemoveAllChildren()
			Next
		Endif
	
		Update()
	End
	
	Method UpdateNode( node:Node,path:String,recurse:Bool )
	
		Local dir:=filesystem.LoadDir( path )
		
		Local dirs:=New Stack<String>
		Local files:=New Stack<String>
		
		For Local f:=Eachin dir
			Local fpath:=path+"/"+f
			Select GetFileType( fpath )
			Case FileType.Directory
				dirs.Push( f )
			Default
				files.Push( f )
			End
		Next
		
		dirs.Sort()
		files.Sort()
		
		Local i:=0,children:=node.Children
		
		While i<dir.Length
		
			Local f:=""
			If i<dirs.Length f=dirs[i] Else f=files[i-dirs.Length]
			
			Local child:Node
			
			If i<children.Length
				child=Cast<Node>( children[i] )
			Else
				child=New Node( node )
			Endif
			
			Local fpath:=path+"/"+f
			
			child.Label=f
			child._path=fpath
			
			If i<dirs.Length
				If child.Expanded Or recurse
					UpdateNode( child,fpath,child.Expanded )
				Endif
			Else
				child.RemoveAllChildren()
			Endif
			
			i+=1
		Wend
		
		node.RemoveChildren( i )
		
	End
	
End
