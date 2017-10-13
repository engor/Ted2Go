
Namespace ted2go


Class ProjectBrowserView Extends FileBrowserExt
	
	Field RequestedDelete:Void( path:String )
	
	Method New( rootPath:String )
		
		Super.New( rootPath )
		
		RootNode.Text=StripDir( rootPath )+" ("+rootPath+")"
		UpdateRootIcon()
		
		NodeExpanded+=Lambda( node:TreeView.Node )
			
			If node.Expanded Then Refresh( node )
		End
		
		NodeDoubleClicked+=Lambda( node:TreeView.Node )
			
			If node.NumChildren=0 Return
			
			node.Expanded=Not node.Expanded
			
			If node.Expanded Then Refresh( node ) ' TRUE - need to refresh icons
			
			RequestRender()
		End
		
		App.Activated+=Lambda()
		
			Refresh()
		End
		
		ApplyFilter( RootNode )
		
	End
	
	Method Refresh()
	
		Refresh( RootNode )
	End
	
	Method Refresh( node:TreeView.Node )
		
		Local n:=Cast<FileBrowserExt.Node>( node )
		If n Then UpdateNode( n )
		
		ApplyFilter( node )
	End
	
	
	Protected
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		If Selected And event.Type=EventType.KeyDown And event.Key=Key.KeyDelete
			
			Local node:=Cast<FileBrowserExt.Node>( Selected )
			RequestedDelete( node.Path )
			event.Eat()
			Return
		Endif
		
		Super.OnKeyEvent( event )
	End
	
	
	Private
	
	Field _filters:=New Stack<TextFilter>
	Field _fileTime:Long
	
	Method ApplyFilter( node:TreeView.Node )
		
		UpdateFilterItems()
		If _filters.Length>0 And node.Expanded
			For Local n:=Eachin node.Children
				Filter( n )
			Next
		Endif
	End
	
	Method Filtered:Bool( text:String )
	
		For Local f:=Eachin _filters
			If f.Filtered( text ) Return True
		Next
		Return False
	End
	
	Method Filter( node:TreeView.Node )
		
		If Filtered( node.Text )
			node.Remove()
			Return
		Endif
		
		If Not node.Expanded Return
		
		For Local n:=Eachin node.Children
			Filter( n )
		Next
	End
	
	Method UpdateFilterItems()
		
		Local path:=RootPath+"/project.json"
		If GetFileType( path ) <> FileType.File Return
		
		Local t:=GetFileTime( path )
		If t=_fileTime Return
		
		_fileTime=t
		
		_filters.Clear()
		
		Local json:=JsonObject.Load( path )
		If json.Contains( "exclude" )
			For Local i:=Eachin json["exclude"].ToArray()
				Local f:=New TextFilter( i.ToString() )
				_filters+=f
			Next
		Endif
	End
	
	Method OnThemeChanged() Override
		
		Super.OnThemeChanged()
		UpdateRootIcon()
		Refresh()
	End
	
	Method UpdateRootIcon()
		If Prefs.MainProjectIcons Then 'Only load icon if settings say so
			RootNode.Icon=ThemeImages.Get( "project/package.png" )
		Else
			RootNode.Icon=Null
		Endif
	End
	
End


Class TextFilter
	
	Enum CheckType
		Equals=0,
		Starts=1,
		Ends=2,
		Both=3
	End
	
	Method New( pattern:String )
		
		If pattern.StartsWith( "*" )
			_type|=CheckType.Ends
			pattern=pattern.Slice( 1 )
		Endif
		If pattern.EndsWith( "*" )
			_type|=CheckType.Starts
			pattern=pattern.Slice( 0,pattern.Length-1 )
		Endif
		_pattern=pattern
	End
	
	Method Filtered:Bool( text:String )
		
		Local skip:=False
		Select _type
			
			Case CheckType.Equals
				skip = (text = _pattern)
				
			Case CheckType.Starts
				skip = text.StartsWith( _pattern )
				
			Case CheckType.Ends
				skip = text.EndsWith( _pattern )
				
			Case CheckType.Both
				skip = (text.Find( _pattern )<>-1)
				
		End
		
		Return skip
	End
	
	Property Pattern:String()
		Return _pattern
	End
	
	Property Type:CheckType()
		Return _type
	End
	
	Private
	
	Field _pattern:String
	Field _type:=CheckType.Equals
	
End
