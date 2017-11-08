
Namespace ted2go

Private

Function EnumModules:String[]()

	Local mods:=New StringStack
	
	For Local f:=Eachin LoadDir( "modules" )
	
		Local dir:="modules/"+f+"/"
		If GetFileType( dir )<>FileType.Directory Continue
		
		Local str:=LoadString( dir+"module.json" )
		If Not str Continue
		
		Local obj:=JsonObject.Parse( str )
		If Not obj Continue
		
		Local jname:=obj["module"]
		If Not jname Or Not Cast<JsonString>( jname ) Continue
		
		mods.Push( jname.ToString() )
	
	Next
	
	Return mods.ToArray()
End

Public

Class HelpTreeView Extends TreeViewExt

	Field PageClicked:Void( page:String )
	
	Method New( htmlView:HtmlView )
		
		htmlView.AnchorClicked=Lambda( url:String )
			
			'dodgy work around for mx2 docs!
			'
			If url.StartsWith( "javascript:void('" ) And url.EndsWith( "')" )
				Local page:=url.Slice( url.Find( "'" )+1,url.FindLast( "'" ) )
				url=PageUrl( page )
				If Not url Return
			Endif
			
			MainWindow.ShowHelp( url )
		End
		
		PageClicked+=Lambda( page:String )
			
			Local url:=PageUrl( page )
			If Not url Return
			
			MainWindow.ShowHelp( url )
		End
		
		Init()
		
	End
	
	Property FindField:TextFieldExt()
		
		Return _textField
	End
	
	Method QuickHelp( text:String )
		
		If text<>_textField.Text
			_textField.Text=text
		Else
			NextHelp()
		End
		
	End
	
	Method PageUrl:String( page:String )
		
		'old doc system
		'Return RealPath( "modules/"+page.Replace( ":","/docs/__PAGES__/" ).Replace( ".","-" )+".html" )
		
		'new doc system
		Return RealPath( "docs/"+page )
	End
	
	Function CreateNodes( obj:JsonObject,parent:Tree.Node,indexer:StringMap<Tree.Node> )
		
		Local text:=obj["text"].ToString()
		Local page:=""
		
		If obj.Contains( "data" )
			Local data:=obj["data"].ToObject()
			page=data["page"].ToString()
		Endif
		
		Local node:=New Tree.Node( text,parent,page )
		indexer[page.ToLower()]=node
		
		If obj.Contains( "children" )
			For Local child:=Eachin obj["children"].ToArray()
				CreateNodes( Cast<JsonObject>( child ),node,indexer )
			Next
		Endif
		
	End
	
	Function FindChild:Node( node:TreeView.Node,text:String )
		
		For Local n:=Eachin node.Children
			If n.Text=text Return Cast<Node>( n )
		Next
		Return Null
	End
	
	Method InsertNode:Node( node:Tree.Node )
		
		Local parent:=RootNode
		Local items:=node.ParentsHierarchy
		items.Add( node )
		
		Local last:Node
		Local len:=items.Length
		For Local i:=1 Until len ' start from 1 to skip root node
			Local item:=items[i]
			Local text:=item.Text
			If i+1<len And items[i+1].Text=text Continue ' skip nested mogo>mojo>... etc
			last=FindChild( parent,text )
			If Not last
				last=New Node( text,parent,item.GetUserData<String>() )
			Endif
			parent=last
		Next
		Return last
	End
	
	Method Update( applyFilter:Bool=False )
		
		_index.Clear()
		_index2.Clear()
		_tree.Clear()
		
		For Local modname:=Eachin EnumModules()
			
			'old doc system
			'Local index:="modules/"+modname+"/docs/__PAGES__/index.js"
			
			'new doc system
			Local index:="docs/modules/"+modname+"/module/index.js"
			
			Local obj:=JsonObject.Load( index )
			If Not obj Continue
			
			CreateNodes( obj,_tree.RootNode,_index )
		Next
		
		FillTree()
		
		If applyFilter Then Update( _textField.Text )
	End
	
	Method RequestFocus()
		
		_textField.MakeKeyView()
	End
	
	
	Private
	
	Class Node Extends TreeView.Node
	
		Method New( text:String,parent:TreeView.Node,page:String )
			
			Super.New( text,parent )
			
			_page=page
		End
		
		Property Page:String()
			Return _page
		End
		
		Private
		
		Field _page:String
		
	End
	
	Method FillTree()
	
		RootNode.RemoveAllChildren()
		
		FillNode( RootNode,_tree.RootNode.Children )
		
	End
	
	Method FillNode( node:TreeView.Node,items:Stack<Tree.Node> )
		
		If Not items Return
		
		For Local item:=Eachin items
			
			Local page:=item.GetUserData<String>()
			
			' hack for the-same-nested 
			If item.NumChildren=1
				Local child:=item.Children[0]
				If child.Text=item.Text.Replace( "-","." )
					item=child
				Endif
			Endif
			
			Local n:=New Node( item.Text,node,page )
			_index2[page.ToLower()]=n
			
			If item.NumChildren
				FillNode( n,item.Children )
			Endif
		Next
		
	End
	
	Method Update( text:String )
		
		'RootNode.RemoveAllChildren()
		RootNode.CollapseAll()
		
		text=text.ToLower()
		
		If _tree.RootNode.NumChildren=0
			New Node( "Click here to rebuild docs!",RootNode,"$$rebuild$$" )
			Return
		Endif
		
		_matches.Clear()
		
		For Local it:=Eachin _index2
			
			'Local node:=it.Value
			Local n:=it.Value
			
			'Local n:=InsertNode( node )
			
			'If Not text Continue
			
			If Not text Or Not it.Key.Contains( text )
				n.Selected=False
				Continue
			Endif
			
			n.Selected=n.Text.ToLower().Contains( text )
			
			If n.Selected
				
				_matches.Push( n )
				
				While n
					n.Expanded=True
					n=Cast<Node>( n.Parent )
				Wend
			Endif
			
		Next
		
		RootNode.Expanded=True
		
		MainWindow.UpdateWindow( False )
		
		_matchid=0
		
		If _matches.Length
			
			PageClicked( _matches[0].Page )
			Selected=_matches[0]
		Endif
		
	End
	
	Method NextHelp()
		
		If _matches.Empty Return
		
		_matchid=(_matchid+1) Mod _matches.Length
		
		PageClicked( _matches[_matchid].Page )
		Selected=_matches[_matchid]
	End
	
	Method Init()
		
		_textField=New TextFieldExt( "#" )
		_textField.Style=GetStyle( "HelpTextField" )
		
		_textField.Entered=Lambda()
		
			NextHelp()
		End
		
		_textField.Document.TextChanged=Lambda()
		
			Local text:=_textField.Text
			
			Update( text )
		End
		
		Local find:=New Label( "Find " )
		find.AddView( _textField )
		
		AddView( find,"top" )
	
		RootNodeVisible=False
		RootNode.Expanded=True
		
		NodeClicked+=Lambda( tnode:TreeView.Node )
		
			Local node:=Cast<Node>( tnode )
			Local page:=node?.Page
			If Not page Return
			
			If page="$$rebuild$$"
				MainWindow.RebuildDocs()
				Return
			Endif
			
			PageClicked( page )
		End
		
		Update()
	End
	
	Field _textField:TextFieldExt
	Field _matchid:Int
	Field _matches:=New Stack<Node>
	Field _index:=New Map<String,Tree.Node>
	Field _index2:=New Map<String,Node>
	Field _tree:=New Tree
	
End
