
Namespace ted2

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

Class HelpTree Extends TreeView

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
	
	Property FindField:TextField()
	
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
	
		Return RealPath( "modules/"+page.Replace( ":","/docs/__PAGES__/" ).Replace( ".","-" )+".html" )
	End
	
	Method Update()
	
		RootNode.RemoveAllChildren()

		For Local modname:=Eachin EnumModules()
		
			Local index:="modules/"+modname+"/docs/__PAGES__/index.js"

			Local obj:=JsonObject.Load( index )
			If Not obj Continue
			
			New Node( obj,RootNode,Self )
		Next
		
		NodeClicked+=Lambda( tnode:TreeView.Node )
		
			Local node:=Cast<Node>( tnode )
			If Not node Or Not node.Page Return
			
			PageClicked( node.Page )
		End
		
	End

	Private
	
	Class Node Extends TreeView.Node
	
		Method New( page:String,parent:TreeView.Node,tree:HelpTree )
			Super.New( page,parent )
			
			_page=page
		End
	
		Method New( obj:JsonObject,parent:TreeView.Node,tree:HelpTree )
			Super.New( "",parent )
		
			Text=obj["text"].ToString()
			
			If obj.Contains( "data" )

				Local data:=obj["data"].ToObject()

				Local page:=data["page"].ToString()
				
				tree._index[page.ToLower()]=Self
				
				_page=page
			Endif
			
			If obj.Contains( "children" )
				For Local child:=Eachin obj["children"].ToArray()
					New Node( Cast<JsonObject>( child ),Self,tree )
				Next
			Endif

		End
		
		Property Page:String()
			Return _page
		End
		
		Property Url:String()
			Return _url
		End
		
		Private
		
		Field _page:String
		
		Field _url:String
	End
	
	Method Update( text:String )

		RootNode.CollapseAll()
			
		text=text.ToLower()
			
		_matches.Clear()
			
		Local selected:=New Map<Node,Bool>
			
		For Local it:=Eachin _index
			
			If Not it.Key.Contains( text ) Continue
				
			Local node:=it.Value
				
			_matches.Push( node )
				
			node.Selected=True
				
			selected[node]=True
				
			While node
				node.Expanded=True
				node=Cast<Node>( node.Parent )
			Wend

		Next
						
		For Local node:=Eachin _selected.Keys
			
			If Not selected.Contains( node ) node.Selected=False

		Next
			
		_selected=selected
			
		RootNode.Expanded=True
			
		_matchid=0
			
		If _matches.Length
			
			PageClicked( _matches[0].Page )
			
		Endif
	
	End
	
	Method NextHelp()
	
		If Not _matches Return
	
		_matchid+=1
		If _matchid>=_matches.Length _matchid=0
		
		If _matchid<_matches.Length PageClicked( _matches[_matchid].Page )
	End
	
	Method Init()

		_textField=New TextField
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
		
		_textField.Activated+=_textField.MakeKeyView
		
		Activated+=MainWindow.ShowHelpView
		
		Update()
				
	End
	
	Field _textField:TextField
	
	Field _matchid:Int
		
	Field _matches:=New Stack<Node>
	
	Field _selected:=New Map<Node,Bool>
	
	Field _index:=New Map<String,Node>
	
End
