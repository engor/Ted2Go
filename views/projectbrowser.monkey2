
Namespace ted2go


Class ProjectBrowser Extends FileBrowser

	
	Method New( rootPath:String )
		
		Super.New( rootPath )
		
		RootNode.Text=StripDir( rootPath )+" ("+rootPath+")"
		RootNode.Icon=ThemeImages.Get( "project/package.png" )
		
		NodeExpanded+=Lambda( node:TreeView.Node )
			
			If node = RootNode And node.Expanded Then Refresh( False )
		End
		
		NodeDoubleClicked+=Lambda( node:TreeView.Node )
			
			node.Expanded=Not node.Expanded
			
			If node = RootNode And node.Expanded Then Refresh( True ) ' TRUE - need to refresh icons
		End
	End
	
	Method Refresh( update:Bool=True )
		
		If update Then Update()
		
		Local jarr:=GetFilterItems()
		If Not jarr Return
		
		For Local i:=Eachin jarr
			Local filter:=i.ToString()
			Local type:=FilterType.Equals
			If filter.StartsWith( "*" )
				type|=FilterType.Starts
				filter=filter.Slice( 1 )
			Endif
			If filter.EndsWith( "*" )
				type|=FilterType.Ends
				filter=filter.Slice( 0,filter.Length-1 )
			Endif
			Filter( filter,type )
		Next
		
	End
	
	
	Private
	
	Field _filters:Stack<JsonValue>
	Field _fileTime:Long
	
	Method Filter( filter:String,type:FilterType)
	
		Local list:=RootNode.Children
		If Not list Return
		
		For Local i:=Eachin list
			FilterNode( i,filter,type )
		Next
	End
	
	Method FilterNode( node:TreeView.Node,filter:String,type:FilterType)
		
		Local ok:=False
		Select type
		Case FilterType.Equals
			ok = (node.Text = filter)
			
		Case FilterType.Starts
			ok = node.Text.StartsWith( filter )
			
		Case FilterType.Ends
			ok = node.Text.EndsWith( filter )
			
		Case FilterType.Both
			ok = node.Text.Find( filter )<>-1
			
		End
		
		If ok
			node.Parent.RemoveChild( node )
			Return
		Endif
		
		Local list:=node.Children
		If Not list Return
		
		For Local i:=Eachin list
			FilterNode( i,filter,type )
		Next
	End
	
	Method GetFilterItems:Stack<JsonValue>()
		
		Local path:=RootPath+"/project.json"
		If GetFileType( path ) <> FileType.File Return _filters
		
		Local t:=GetFileTime( path )
		If t=_fileTime Return _filters
		
		_fileTime=t
		
		Local json:=JsonObject.Load( path )
		If json.Contains( "exclude" )
			_filters=json["exclude"].ToArray()
		Endif
		
		Return _filters
	End
	
	Enum FilterType
		Equals=0,
		Starts=1,
		Ends=2,
		Both=3
	End
	
End
