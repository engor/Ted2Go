
Namespace ted2

Function EnumModules:String[]()

	Local mods:=New StringStack
	
	For Local line:=Eachin stringio.LoadString( "modules/modules.txt" ).Split( "~n" )
	
		Local i:=line.Find( "'" )
		If i<>-1 line=line.Slice( 0,i )
		
		line=line.Trim()
		If line mods.Push( line )
		
	Next
	
	Return mods.ToArray()
End

Class HelpView Extends DockingView

	Field PageClicked:Void( url:String )

	Method New()
	
		_findField=New TextField
		_findField.TabHit=Lambda()
		
			If _findField.Document.Text<>_matchText Or Not _matches.Length Return
			
			_matchId=(_matchId+1) Mod _matches.Length
			Go( _matches[_matchId] )

		End
		_findField.Document.TextChanged=Lambda()
			UpdateMatches( _findField.Text )
			If _matches.Length Go( _matches[0] )
		End
		
		Local findBar:=New DockingView
	
		findBar.AddView( New Label( "Find:" ),"left" )
		findBar.ContentView=_findField
		
		_helpTree=New HelpTree
		
		_helpTree.NodeClicked=Lambda( tnode:TreeView.Node,event:MouseEvent )
		
			Local node:=Cast<HelpTree.Node>( tnode )
			If Not node Return
			
			Go( node.Page )
		End
		
		_htmlView=New HtmlView

		_htmlView.AnchorClicked=Lambda( url:String )
		
			'dodgy work around for mx2 docs!
			If url.StartsWith( "javascript:void('" ) And url.EndsWith( "')" )
				Local page:=url.Slice( url.Find( "'" )+1,url.FindLast( "'" ) )
				Go( page )
				Return
			Endif

			_htmlView.Go( url )
		End
		
		AddView( findBar,"top" )
		
		AddView( _helpTree,"top",128 )
		
		ContentView=New ScrollView( _htmlView )
	End
	
	Property HelpTree:HelpTree()
		Return _helpTree
	End
	
	Property HtmlView:HtmlView()
		Return _htmlView
	End
	
	Method Go( page:String )
		Local url:="modules/"+page.Replace( ":","/docs/__PAGES__/" ).Replace( ".","-" )+".html"
		_htmlView.Go( RealPath( url ) )
	End
	
	Method UpdateMatches( text:String )

		_matchId=0
		_matchText=text
		_matches.Clear()

		For Local page:=Eachin _helpTree.Index
			If page.Contains( text ) _matches.Push( page )
		Next

		_matches.Sort()
		
		_helpTree.Matches.RemoveAllChildren()
		For Local page:=Eachin _matches
			New HelpTree.Node( page,_helpTree.Matches,_helpTree )
		Next
	End
	
	Private
	
	Field _findField:TextField
	Field _helpTree:HelpTree
	Field _htmlView:HtmlView
	Field _scroller:ScrollView
	
	Field _matchId:Int
	Field _matchText:String
	Field _matches:=New StringStack
End

Class HelpTree Extends TreeView

	Class Node Extends TreeView.Node
	
		Method New( page:String,parent:TreeView.Node,tree:HelpTree )
			Super.New( page,parent )
			
			_page=page
		End
	
		Method New( obj:JsonObject,parent:TreeView.Node,tree:HelpTree )
			Super.New( "",parent )
		
			Label=obj["text"].ToString()
			
			If obj.Contains( "data" )
				Local data:=obj["data"].ToObject()
				Local page:=data["page"].ToString()
				tree._index.Add( page )
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
		
		Private
		
		Field _page:String
	
	End
	
	Method New()
	
		RootNodeVisible=False
		RootNode.Expanded=True
		
		_matches=New TreeView.Node( "Matches",RootNode )
		_modules=New TreeView.Node( "Modules",RootNode )
	
		For Local modname:=Eachin EnumModules()
		
			Local index:="modules/"+modname+"/docs/__PAGES__/index.js"

			Local obj:=JsonObject.Load( index )
			If Not obj
				Print "Error! file="+index
				Continue
			Endif
			
			New Node( obj,_modules,Self )
		Next
		
	End
	
	Property Matches:TreeView.Node()
		Return _matches
	End
	
	Property Modules:TreeView.Node()
		Return _modules
	End
	
	Property Index:StringStack()
		Return _index
	End
	
	Private
	
	Field _matches:TreeView.Node
	Field _modules:TreeView.Node
	
	Field _index:=New StringStack
	
End
