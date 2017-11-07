
Namespace ted2go


Class ProjectBrowserView Extends TreeViewExt Implements IDraggableHolder
	
	Field RequestedDelete:Void( node:Node )
	Field FileClicked:Void( node:Node )
	Field FileRightClicked:Void( node:Node )
	Field FileDoubleClicked:Void( node:Node )
	
	Method New()
		
		Super.New()
		
		Style=GetStyle( "FileBrowser" )
		
		_rootNode=NewNode( Null )
		RootNode=_rootNode
		RootNode.Expanded=True
		RootNodeVisible=False
		
		NodeClicked+=OnNodeClicked
		NodeRightClicked+=OnNodeRightClicked
		NodeDoubleClicked+=OnNodeDoubleClicked
		
		NodeExpanded+=OnNodeExpanded
		NodeCollapsed+=OnNodeCollapsed
		
		App.Activated+=Lambda()
		
			UpdateAllNodes()
		End
		
		UpdateFileTypeIcons()
		
		If Not _listener Then _listener=New DraggableProjTreeListener
	End
	
	Method Attach( item:Object,eventLocation:Vec2i )
		
		New Fiber( Lambda()
			
			Local node:=Cast<Node>( item )
			Local node2:=FindNodeAtPoint( eventLocation )
			If Not node2 Return
			
			Local destNode:=Cast<Node>( node2 )
			
			Local srcIsFolder:=GetFileType( node.Path )=FileType.Directory
			Local destIsFolder:=GetFileType( destNode.Path )=FileType.Directory
			
			If Not destIsFolder
				node2=node2.Parent ' grab destination folder
				destNode=Cast<Node>( node2 )
				destIsFolder=True
			Endif
			
			If srcIsFolder
				If node2=node Or node.Parent=node2 Return
				' deny to move into child folder
				Local n:=node2.Parent
				While n
					If n=node Return
					n=n.Parent
				Wend
			Else
				If node.Parent=node2 Return
			Endif
			
			Local src:=node.Path
			Local dest:=destNode.Path
			
			If Not dest.EndsWith( "/" ) Then dest+="/"
			Local name:=StripDir( src )
			dest+=name
			
			If Not CheckOverwritingConfirm( dest,name,srcIsFolder ) Return
			
			Local ok:=False
			Local move:=(Keyboard.Modifiers & Modifier.Control)=0
			
			If srcIsFolder
				ok=CopyDir( src,dest )
				If ok And move Then DeleteDir( src,True )
			Else
				ok=CopyFile( src,dest )
				If ok And move Then DeleteFile( src )
			Endif
			If ok
				If move Then node.Remove()
				
				OnDraggedInto( destNode,name )
			Else
				Alert( "Can't move into "+ExtractDir( dest ) )
			Endif
			
		End )
		
	End
	
	Method Detach:View( item:Object )
		
		' don't remove
		Local node:=Cast<Node>( item )
		
		_draggingText=node.Text
		If Not _draggableView
			_draggableView=New Button( "",node.Icon )
			_draggableView.Layout="float"
		Else
			_draggableView.Icon=node.Icon
		Endif
		
		MakeKeyView() 'wonna catch Ctrl-key
		
		Return _draggableView
	End
	
	Method OnDragStarted()
		
		_draggingState=True
	End
	
	Method OnDragEnded()
		
		_draggingState=False
	End
	
	Method OnFileDropped:Bool( path:String )
		
		Local point:=TransformWindowPointToView( Mouse.Location )
		Local node:=Cast<Node>( FindNodeAtPoint( point ) )
		If Not node Return False
		
		If GetFileType( node.Path )=FileType.File
			node=Cast<Node>( node.Parent )
		Endif
		
		Local dest:=node.Path
		If Not dest.EndsWith( "/" ) Then dest+="/"
		Local name:=StripDir( path )
		dest+=name
		
		Local isFolder:=GetFileType( path )=FileType.Directory
		
		If Not CheckOverwritingConfirm( dest,name,isFolder ) Return True ' don't copied but return true
		
		Local ok:=False
		If isFolder
			ok=CopyDir( path,dest )
		Else
			ok=CopyFile( path,dest )
		Endif
		If ok
			OnDraggedInto( node,name )
		Else
			Alert( "Can't copy into "+ExtractDir( dest ) )
		Endif
		
		Return True
	End
	
	Method NewNode:Node( parent:Node )
		
		Return New Node( parent,Self )
	End
	
	Method AddProject( dir:String )
		
		Local node:=NewNode( _rootNode )
		Local s:=StripDir( dir )+" ("+dir+")"
		node.Text=s
		node._path=dir
		UpdateProjIcon( node )
		_expander.Restore( node )
		
		UpdateNode( node )
		ApplyFilter( node )
	End
	
	Method RemoveProject( dir:String )
	
		Local s:=StripDir( dir )+" ("+dir+")"
		Local toRemove:TreeView.Node=Null
		For Local n:=Eachin RootNode.Children
			If n.Text=s
				toRemove=n
				Exit
			Endif
		Next
		If toRemove Then toRemove.Remove()
	End
	
	Method UpdateAllNodes()
	
		Local selPath:=Selected ? GetNodePath( Selected ) Else ""
	
		For Local n:=Eachin _rootNode.Children
			Local nn:=Cast<Node>( n )
			_expander.Restore( nn )
			UpdateNode( nn,True )
			ApplyFilter( nn )
		Next
		
		If selPath Then SelectByPath( selPath )
	
	End
	
	Method IsProjectNode:Bool( node:Node )
		
		Return node.Parent=_rootNode
	End
	
	Method Refresh( node:Node )
	
		UpdateNode( node,True )
		ApplyFilter( node )
		Selected=node
	End
	
	Method Refresh( tnode:TreeView.Node )
		
		Local node:=Cast<Node>( tnode )
		If node Then Refresh( node )
	End
	
	
	Protected
	
	Class Node Extends TreeView.Node Implements IDraggableItem<ProjectBrowserView>
	
		Method New( parent:Node,view:ProjectBrowserView )
			
			Super.New( "",parent )
			_view=view
			_curHolder=view
		End
	
		Property Path:String()
			Return _path
		End
		
		Property Detachable:Bool()
			Return GetNodeDeepLevel( Self )>1
		End
		
		Property PossibleHolders:ProjectBrowserView[]()
			Return _holders
		Setter( value:ProjectBrowserView[] )
			_holders=value
		End
		
		Property CurrentHolder:ProjectBrowserView()
			Return _curHolder
		End
		
		Property View:View()
		
			Return _view
		
		Setter( view:View )
		
			_view=view
		End
		
		Private
	
		Field _path:String
		Field _holders:ProjectBrowserView[]
		Field _curHolder:ProjectBrowserView
		Field _view:View
		
	End
	
	Method GetFileTypeIcon:Image( path:String ) Virtual
	
		Local ext:=ExtractExt( path )
		If Not ext Return Null
	
		Return _fileTypeIcons[ext.ToLower()]
	End
	
	Method OnValidateStyle() Override
	
		Super.OnValidateStyle()
		
		UpdateFileTypeIcons()
	
		_dirIcon=_fileTypeIcons["._dir"]
		_fileIcon=_fileTypeIcons["._file"]
		
		UpdateAllProjIcons()
		
		UpdateAllNodes()
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
		
		If Selected And event.Type=EventType.KeyDown And event.Key=Key.KeyDelete
			
			Local node:=Cast<Node>( Selected )
			RequestedDelete( node )
			event.Eat()
			Return
		Endif
		
		Super.OnKeyEvent( event )
		
		UpdateDraggingState()
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Super.OnContentMouseEvent( event )
		
		UpdateDraggingState()
	End
	
	
	Private
	
	Global _fileTypeIcons:StringMap<Image>
	
	Field _rootNode:Node
	Field _filters:=New StringMap<Stack<TextFilter>>
	Field _filtersFileTimes:=New StringMap<Long>
	
	Field _dirIcon:Image
	Field _fileIcon:Image
	
	Field _draggableView:Button
	Field _draggingState:Bool
	Field _draggingText:String
	
	Global _listener:DraggableProjTreeListener
	
	Method CheckOverwritingConfirm:Bool( destPath:String,name:String,isFolder:Bool )
		
		' confirm overwriting
		Local confirm:=""
		If isFolder And DirectoryExists( destPath )
			confirm="Destination folder already contains '"+name+"' subfolder.~nDo you want to merge files replacing with moved ones?"
		Elseif FileExists( destPath )
			confirm="Destination folder already contains '"+name+"'.~nDo you want to replace existing file with moved one?"
		Endif
		
		If confirm
			Return RequestOkay( confirm,"" )
		Endif
		
		Return True
	End
	
	Method OnDraggedInto( node:Node,name:String )
		
		Local path:=node.Text+"\"+name
		
		node.Expanded=True
		_expander.Store( node )
		Local par:=IsProjectNode( node ) ? node Else node.Parent
		OnNodeExpanded( par ) 'update parent folder
		
		SelectByPathEnds( path )
		
	End
	
	Method UpdateDraggingState()
		
		If _draggingState
			_draggableView.Text=(Keyboard.Modifiers & Modifier.Control = 0) ? _draggingText Else _draggingText+" (copy)"
		Endif
	End
	
	Method FindProjectNode:Node( node:TreeView.Node )
		
		Local result:TreeView.Node
		While node
			result=node
			node=node.Parent
			If node=_rootNode Exit
		Wend
		Return result ? Cast<Node>( result ) Else Null
	End
	
	Method ApplyFilter( node:Node )
		
		Local projNode:=FindProjectNode( node )
		UpdateFilterItems( projNode )
		
		Local list:=_filters[projNode.Text]
		If list And list.Length>0 And node.Expanded
			For Local n:=Eachin node.Children
				Filter( n,list )
			Next
		Endif
	End
	
	Method Filtered:Bool( node:TreeView.Node,filters:Stack<TextFilter> )
	
		Local text:=node.Text
		For Local f:=Eachin filters
			If f.Filtered( text ) Return True
		Next
		Return False
	End
	
	Method Filter( node:TreeView.Node,filters:Stack<TextFilter> )
		
		If Filtered( node,filters )
			node.Remove()
			Return
		Endif
		
		If Not node.Expanded Return
		
		For Local n:=Eachin node.Children
			Filter( n,filters )
		Next
	End
	
	Method UpdateFilterItems( projNode:Node )
		
		Local path:=projNode.Path+"/project.json"
		If GetFileType( path ) <> FileType.File Return
		
		Local projName:=projNode.Text
		
		Local t:=GetFileTime( path )
		If t=_filtersFileTimes[projName] Return
		
		_filtersFileTimes[projName]=t
		
		Local list:=GetOrCreate( _filters,projName )
		list.Clear()
		
		Local json:=JsonObject.Load( path )
		If json.Contains( "exclude" )
			For Local i:=Eachin json["exclude"].ToArray()
				Local f:=New TextFilter( i.ToString() )
				list+=f
			Next
		Endif
	End
	
	Method UpdateProjIcon( node:TreeView.Node )
	
		node.Icon = Prefs.MainProjectIcons ? ThemeImages.Get( "project/package.png" ) Else Null
	End
	
	Method UpdateAllProjIcons()
		
		For Local n:=Eachin RootNode.Children
			UpdateProjIcon( n )
		Next
	End
	
	Method UpdateNode( node:Node,recurse:Bool=True )
		
		Local path:=node._path
		'Print "update node: "+path
		If Not path.EndsWith( "/" ) path+="/"
		Local dir:=filesystem.LoadDir( path )
		
		Local dirs:=New Stack<String>
		Local files:=New Stack<String>
		
		For Local f:=Eachin dir
			
			Local fpath:=path+f
			
			Select GetFileType( fpath )
			Case FileType.Directory
				dirs.Add( f )
			Default
				files.Add( f )
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
				child.RemoveAllChildren()
			Else
				child=NewNode( node )
			Endif
			
			Local fpath:=path+f
			
			child.Text=f
			child._path=fpath
			
			Local icon:Image
			If Prefs.MainProjectIcons 'Only load icon if settings say so
				icon=GetFileTypeIcon( fpath )
			Endif
			
			If i<dirs.Length
				If Not icon And Prefs.MainProjectIcons Then icon=_dirIcon
				child.Icon=icon
				
				_expander.Restore( child )
				
				If child.Expanded Or recurse
					UpdateNode( child,child.Expanded )
				Endif
			Else
				If Not icon And Prefs.MainProjectIcons Then icon=_fileIcon
				child.Icon=icon
				child.RemoveAllChildren()
			Endif
			
			i+=1
		Wend
		
		node.RemoveChildren( i )
		
	End
	
	Method OnNodeClicked( tnode:TreeView.Node )
		
		Local node:=Cast<Node>( tnode )
		If Not node Return
		
		FileClicked( node )
	End
	
	Method OnNodeRightClicked( tnode:TreeView.Node )
		
		Local node:=Cast<Node>( tnode )
		If Not node Return
		
		FileRightClicked( node )
	End
	
	Method OnNodeDoubleClicked( tnode:TreeView.Node )
		
		Local node:=Cast<Node>( tnode )
		If Not node Return
		
		FileDoubleClicked( node )
	End
	
	Method OnNodeExpanded( tnode:TreeView.Node )
	
		Local node:=Cast<Node>( tnode )
		If Not node Return
		
		UpdateNode( node,True )
		ApplyFilter( node )
	End
	
	Method OnNodeCollapsed( tnode:TreeView.Node )
	
	End
	
	Function UpdateFileTypeIcons()
	
		If _fileTypeIcons Return
		
		_fileTypeIcons=New StringMap<Image>
		
		Local dir:="theme::filetype_icons/"
		
		Local types:=stringio.LoadString( dir+"filetypes.txt" ).Split( "~n" )
	
		For Local type:=Eachin types
		
			type=type.Trim()
			If Not type Continue
			
			Local icon:=Image.Load( dir+type )
			If Not icon Continue
			
			icon.Scale=App.Theme.Scale
			
			_fileTypeIcons[ "."+StripExt(type) ]=icon
		Next
		
		App.ThemeChanged+=Lambda()
			For Local image:=Eachin _fileTypeIcons.Values
				image.Scale=App.Theme.Scale
			Next
		End
		
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

Class DraggableProjTreeListener Extends DraggableViewListener<ProjectBrowserView.Node,ProjectBrowserView>
	
	Method GetItem:ProjectBrowserView.Node( eventView:View,eventLocation:Vec2i ) Override
		
		Local projTree:=FindViewInHierarchy<ProjectBrowserView>( eventView )
		
		Return Cast<ProjectBrowserView.Node>( projTree?.FindNodeAtPoint( eventLocation ) )
	End
	
	Method GetHolder:ProjectBrowserView( view:View ) Override
	
		Return Cast<ProjectBrowserView>( view )
	End
	
End
