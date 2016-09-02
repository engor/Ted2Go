
Namespace ted2go


Class ProjectView Extends ScrollView

	Field openProject:Action
	
	Field ProjectOpened:Void( dir:String )

	Method New( docs:DocumentManager )
	
		_docs=docs
	
		_docker=New DockingView
		
		ContentView=_docker
		
		_docker.ContentView=New TreeView
		
		openProject=New Action( "Open project" )
		openProject.Triggered=OnOpenProject
	End
	
	Property OpenProjects:String[]()
	
		Local projs:=New StringStack
		For Local proj:=Eachin _projects.Keys
			projs.Add( proj )
		Next
		
'		projs.Add( _projects.Keys )	'Should work - FIXME
		
		Return projs.ToArray()
	End
	
	Method OpenProject:Bool( dir:String )
	
		dir=StripSlashes( dir )
		
		If _projects[dir] Return False
		
		If GetFileType( dir )<>FileType.Directory Return False
	
		Local browser:=New FileBrowser( dir )
		
		browser.FileClicked+=Lambda( path:String )
		
			If GetFileType( path )=FileType.File
			
				New Fiber( Lambda()
					_docs.OpenDocument( path,True )
				End )
				
			Endif
			
		End
		
		browser.FileRightClicked+=Lambda( path:String )
		
			Local menu:=New Menu
		
			Select GetFileType( path )
			Case FileType.Directory
			
				menu.AddAction( "New File" ).Triggered=Lambda()
				
					Local file:=RequestString( "New file name:" )
					If Not file Return
					
					Local tpath:=path+"/"+file
					
					If GetFileType( tpath )<>FileType.None
						Alert( "A file or directory already exists at '"+tpath+"'" )
						Return
					End
					
					If Not CreateFile( tpath )
						Alert( "Failed to create file '"+file+"'" )
					Endif
					
					browser.Update()
					Return
				End
		
				menu.AddAction( "New Folder" ).Triggered=Lambda()
				
					Local dir:=RequestString( "New folder name:" )
					If Not dir Return
					
					Local tpath:=path+"/"+dir
					
					If GetFileType( tpath )<>FileType.None
						Alert( "A file or directory already exists at '"+tpath+"'" )
						Return
					End
					
					If Not CreateDir( tpath )
						Alert( "Failed to create folder '"+dir+"'" )
						Return
					Endif
					
					browser.Update()
					Return
				End
				
				menu.AddAction( "Delete" ).Triggered=Lambda()

					If Not RequestOkay( "Really delete folder '"+path+"'?" ) Return
					
					If DeleteDir( path,True )
						browser.Update()
						Return
					Endif
					
					Alert( "Failed to delete folder '"+path+"'" )
				End
				
			Case FileType.File
			
				menu.AddAction( "Open On Desktop" ).Triggered=Lambda()
				
					mojo.requesters.OpenUrl( path )
				End
				
				menu.AddSeparator()
			
				menu.AddAction( "Delete" ).Triggered=Lambda()
				
					If Not RequestOkay( "Really delete file '"+path+"'?" ) return
				
					If DeleteFile( path )
					
						Local doc:=_docs.FindDocument( path )
						
						If doc doc.Close()
					
						browser.Update()
						Return
					Endif
					
					Alert( "Failed to delete file: '"+path+"'" )
				End
			
			Default
			
				Return
			End
			
			menu.Open()
		End
		
		browser.RootNode.Text=StripDir( dir )+" ("+dir+")"
		
		_docker.AddView( browser,"top" )
		
		_projects[dir]=browser
		
		ProjectOpened( dir )

		Return True
	End
	
	Method CloseProject( dir:String )

		dir=StripSlashes( dir )
		
		Local view:=_projects[dir]
		If Not view Return
		
		_docker.RemoveView( view )
		
		_projects.Remove( dir )
	End
	
	Method SaveState( jobj:JsonObject )
	
		Local jarr:=New JsonArray
		For Local it:=Eachin _projects
			jarr.Add( New JsonString( it.Key ) )
		Next
		jobj["openProjects"]=jarr
	End
	
	Method LoadState( jobj:JsonObject )
	
		If jobj.Contains( "openProjects" )
			local arr:=jobj["openProjects"].ToArray()
			For Local dir:=Eachin arr
				OpenProject( dir.ToString() )
			Next
		Endif
		
	End
	
	Private
	
	Field _docs:DocumentManager
	
	Field _docker:=New DockingView
	
	Field _projects:=New StringMap<FileBrowser>

	Method OnOpenProject()
	
		Local dir:=MainWindow.RequestDir( "Select Project Directory...","" )
		If Not dir Return
		
		OpenProject( dir )
	End
	
End
