
Namespace ted2

Class ProjectView Extends ScrollView

	Method New()
	
		_docker=New DockingView
		
		ContentView=_docker
		
		_docker.ContentView=New TreeView
		
	End

	Method OpenProject:Bool( dir:String )
	
		dir=StripSlashes( dir )
		
		If _projects[dir] Return False
		
		If GetFileType( dir )<>FileType.Directory Return False
	
		Local browser:=New FileBrowser( dir )
		
		browser.FileClicked=Lambda( path:String,event:MouseEvent )
		
			Select event.Button
			Case MouseButton.Left
			
				If GetFileType( path )=FileType.File
				
					New Fiber( Lambda()
					
						MainWindow.OpenDocument( path,True )
						MainWindow.SaveState()
						
					End )
					
				Endif
			
			Case MouseButton.Right
			
				#rem Laters...!
				Select GetFileType( path )
				Case FileType.Directory
				
					Local menu:=New Menu( path )
					menu.AddAction( "New file" ).Triggered=Lambda()
						Local file:=MainWindow.RequestFile( "New file","",True,path )
						Print "File="+file
					End
					
					menu.Open( event.Location,browser,Null )
				
				End
				#end
				
			End
		End
		
		browser.RootNode.Label=StripDir( dir )+" ("+dir+")"
		
		_docker.AddView( browser,"top" )
		
		_projects[dir]=browser
		
		Return True
		
	End
	
	Method CloseProject( dir:String )

		dir=StripSlashes( dir )
		
		Local view:=_projects[dir]
		If Not view Return
		
		_docker.RemoveView( view )
		
		_projects.Remove( dir )
	End
	
	Private
	
	Field _docker:=New DockingView
	
	Field _projects:=New StringMap<FileBrowser>
End


