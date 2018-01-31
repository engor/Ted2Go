
Namespace ted2go


Class ProjectView Extends ScrollView

	Field openProject:Action
	
	Field ProjectOpened:Void( dir:String )
	Field ProjectClosed:Void( dir:String )
	
	Field RequestedFindInFolder:Void( folder:String )

	Method New( docs:DocumentManager,builder:IModuleBuilder )
	
		_docs=docs
		_builder=builder
		
		_docker=New DockingView
		
		ContentView=_docker
		
		_docker.ContentView=New TreeViewExt
		
		openProject=New Action( "Open project" )
		openProject.HotKey=Key.O
		openProject.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		openProject.Triggered=OnOpenProject
		
		InitProjBrowser()
	End
	
	Property OpenProjects:String[]()
	
		Return _projects.ToArray()
	End
	
	Property SingleClickExpanding:Bool()
	
		Return _projBrowser.SingleClickExpanding
	
	Setter( value:Bool )
		
		_projBrowser.SingleClickExpanding=value
	End
	
	Function FindProjectByFile:String( filePath:String )
		
		If Not filePath Return ""
		
		For Local p:=Eachin _projects
			If filePath.StartsWith( p )
				Return p
			Endif
		End
		Return ""
	End
	
	Method OnFileDropped:Bool( path:String )
		
		Local ok:=_projBrowser.OnFileDropped( path )
		If Not ok
			Local isFolder:=GetFileType( path )=FileType.Directory
			If isFolder
				ok=True
				OpenProject( path )
			Endif
		Endif
		Return ok
	End
	
	Method OpenProject:Bool( dir:String )
	
		dir=StripSlashes( dir )
		
		If _projects.Contains( dir ) Return False
		
		If GetFileType( dir )<>FileType.Directory Return False
		
		_projects+=dir
		
		_projBrowser.AddProject( dir )
		
		ProjectOpened( dir )

		Return True
	End
	
	Method CloseProject( dir:String )

		dir=StripSlashes( dir )
		
		_projBrowser.RemoveProject( dir )
		
		_projects-=dir
		
		ProjectClosed( dir )
	End
	
	Method SaveState( jobj:JsonObject )
		
		Local j:=New JsonObject
		jobj["projectsExplorer"]=j
		
		Local jarr:=New JsonArray
		For Local p:=Eachin _projects
			jarr.Add( New JsonString( p ) )
		Next
		j["openProjects"]=jarr
		
		_projBrowser.SaveState( j,"expanded" )
		
		Local selPath:=GetNodePath( _projBrowser.Selected )
		j["selected"]=New JsonString( selPath )
	End
	
	Method LoadState( jobj:JsonObject )
		
		If Not jobj.Contains( "projectsExplorer" ) Return
		
		jobj=new JsonObject( jobj["projectsExplorer"].ToObject() )
		
		_projBrowser.LoadState( jobj,"expanded" )
		
		If jobj.Contains( "openProjects" )
			local arr:=jobj["openProjects"].ToArray()
			For Local dir:=Eachin arr
				OpenProject( dir.ToString() )
			Next
		Endif
		
		Local selPath:=Json_GetString( jobj.Data,"selected","" )
		If selPath Then _projBrowser.SelectByPath( selPath )
	End
	
	
	Protected
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseWheel ' little faster
			
			Scroll-=New Vec2i( 0,ContentView.RenderStyle.Font.Height*event.Wheel.Y*3 )
			Return
	
		End
	
		Super.OnMouseEvent( event )
	End
	
	
	Private
	
	Field _docs:DocumentManager
	Field _docker:=New DockingView
	Global _projects:=New StringStack
	Field _builder:IModuleBuilder
	Field _projBrowser:ProjectBrowserView
	
	Field _cutPath:String,_copyPath:String
	
	Method OnCut( path:String )
		
		_copyPath=""
		_cutPath=path
	End
	
	Method OnCopy( path:String )
		
		_cutPath=""
		_copyPath=path
	End
	
	Method OnPaste:Bool( path:String )
		
		Local ok:=True
		
		If Not path.EndsWith( "/" ) Then path+="/"
		
		Local cut:=(_cutPath<>"")
		Local srcPath:=cut ? _cutPath Else _copyPath
		
		Local isFolder:=(GetFileType( srcPath )=FileType.Directory)
		
		If isFolder And path.StartsWith( srcPath )
			
			Alert( "Can't paste into the same or nested folder!","Paste element" )
			Return False
		Endif
		
		Local name:=StripDir( srcPath )
		
		Local dest:=path+name
		Local exists:=(GetFileType( dest )<>FileType.None)
		
		If exists
			Local s:=RequestString( "New name:","Element already exists",name )
			If Not s Or s=name Return False
			name=s
			dest=path+name
		Endif
		
		If isFolder
			ok=CopyDir( srcPath,dest )
			If ok And cut Then DeleteDir( srcPath,True )
		Else
			ok=CopyFile( srcPath,dest )
			If ok And cut Then DeleteFile( srcPath )
		Endif
		
		If Not ok Then Alert( "Can't copy~n"+srcPath+"~ninto~n"+dest,"Paste element" )
		
		_cutPath=""
		
		Return ok
	End
	
	Method DeleteItem( browser:ProjectBrowserView,path:String,node:TreeView.Node )
		
		Local nodeToRefresh:=Cast<ProjectBrowserView.Node>( node.Parent )
		
		Local work:=Lambda()
			
			If DirectoryExists( path )
			
				If Not RequestOkay( "Really delete folder '"+path+"'?" ) Return
				
				If DeleteDir( path,True )
					browser.Refresh( nodeToRefresh )
					Return
				Endif
				
				Alert( "Failed to delete folder '"+path+"'" )
				
			Else
				
				If Not RequestOkay( "Really delete file '"+path+"'?" ) Print "1111" ; Return
				
				If DeleteFile( path )
				
					Local doc:=_docs.FindDocument( path )
				
					If doc doc.Close()
				
					browser.Refresh( nodeToRefresh )
					Return
				Endif
				
				Alert( "Failed to delete file: '"+path+"'" )
				
			Endif
			
		End
		
		New Fiber( work )
	End
	
	Method OnOpenProject()
	
		Local dir:=MainWindow.RequestDir( "Select Project Directory...","" )
		If Not dir Return
		
		OpenProject( dir )
	End
	
	Method OnOpenDocument( path:String,makeFocused:Bool,runExec:Bool=True )
		
		If GetFileType( path )<>FileType.File Return
			
		New Fiber( Lambda()
			
			Local ext:=ExtractExt( path )
			Local exe:=(ext=".exe")
			If runExec
				If exe Or ext=".bat" Or ext=".sh"
					Local s:="Do you want to execute this file?"
					If Not exe s+="~nPress 'Cancel' to open file in editor."
					If RequestOkay( s,StripDir( path ) )
						OpenUrl( path )
						Return
					Endif
				Endif
			Endif
			
			If exe Return 'never open .exe
			
			_docs.OpenDocument( path,True )
			
			If Not makeFocused Then Self.MakeKeyView()
			
		End )
	End
	
	' Return True if there is an actual folder deletion
	Method CleanProject:Bool( dir:String )
	
		Local succ:=0,err:=0
		Local items:=LoadDir( dir )
		For Local i:=Eachin items
			i=dir+"/"+i
			If GetFileType(i)=FileType.Directory
				If i.Contains( ".buildv" )
					Local ok:=DeleteDir( i,True )
					If ok Then succ+=1 Else err+=1
				Endif
			Endif
		Next
	
		Local s:= err=0 ? "Project was successfully cleaned." Else "Clean project error! Some files are busy or you have no privileges."
		MainWindow.ShowStatusBarText( s )
		
		Return succ>0
	End
	
	Method CreateFileInternal:Bool( path:String,content:String=Null )
		
		If ExtractExt(path)="" Then path+=".monkey2"
		
		If GetFileType( path )<>FileType.None
			Alert( "A file or directory already exists at '"+path+"'" )
			Return False
		End
		
		If Not CreateFile( path )
			Alert( "Failed to create file '"+StripDir( path )+"'" )
			Return False
		Endif
		
		If content Then SaveString( content,path )
		
		Return True
	End
	
	Method InitProjBrowser()
		
		Local browser:=New ProjectBrowserView()
		browser.SingleClickExpanding=Prefs.MainProjectSingleClickExpanding
		_projBrowser=browser
		_docker.AddView( browser,"top" )
		
		browser.RequestedDelete+=Lambda( node:ProjectBrowserView.Node )
		
			DeleteItem( browser,node.Path,node )
		End
		
		browser.FileClicked+=Lambda( node:ProjectBrowserView.Node )
			
			If browser.SingleClickExpanding Then OnOpenDocument( node.Path,False )
		End
		
		browser.FileDoubleClicked+=Lambda( node:ProjectBrowserView.Node )
			
			If Not browser.SingleClickExpanding Then OnOpenDocument( node.Path,True )
		End
		
		browser.FileRightClicked+=Lambda( node:ProjectBrowserView.Node )
		
			Local menu:=New MenuExt
			Local path:=node.Path
			Local pasteAction:Action
			Local isFolder:=False
			
			Select GetFileType( path )
			Case FileType.Directory
				
				isFolder=True
				
				menu.AddAction( "Find..." ).Triggered=Lambda()
					
					RequestedFindInFolder( path )
				End
				
				menu.AddSeparator()
				
				menu.AddAction( "New class..." ).Triggered=Lambda()
					
					Local d:=New GenerateClassDialog( path )
					d.Generated+=Lambda( filePath:String,fileContent:String )
						
						If CreateFileInternal( filePath,fileContent )
							
							MainWindow.OpenDocument( filePath )
							browser.Refresh( node )
						Endif
					End
					d.ShowModal()
				End
				
				menu.AddSeparator()
				
				menu.AddAction( "New file" ).Triggered=Lambda()
					
					Local file:=RequestString( "New file name:" )
					If Not file Return
					
					Local tpath:=path+"/"+file
					
					CreateFileInternal( tpath )
					
					browser.Refresh( node )
				End
				
				menu.AddAction( "New folder" ).Triggered=Lambda()
					
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
					
					browser.Refresh( node )
				End
				
				menu.AddAction( "Delete" ).Triggered=Lambda()
					
					DeleteItem( browser,path,node )
				End
				
				menu.AddSeparator()
				
				If browser.IsProjectNode( node ) ' root node
					
					menu.AddAction( "Close project" ).Triggered=Lambda()
						
						CloseProject( path )
					End
					
					menu.AddAction( "Clean (delete .buildv)" ).Triggered=Lambda()
						
						If Not RequestOkay( "Really delete all '.buildv' folders?" ) Return
						
						Local changes:=CleanProject( path )
						If changes Then browser.Refresh( node )
					End
				Else
					
					menu.AddAction( "Open as a project" ).Triggered=Lambda()
					
						OpenProject( path )
					End
				Endif
				
				' update / rebuild module
				path=path.Replace( "\","/" )
				Local name := path.Slice( path.FindLast( "/")+1 )
				Local file:=path+"/module.json"
				
				If path.Contains( "/modules/") And GetFileType( file )=FileType.File
					
					menu.AddSeparator()
					
					menu.AddAction( "Update / Rebuild "+name ).Triggered=Lambda()
						
						_builder.BuildModules( name )
					End
					
				Endif
				
				' update all modules
				Local path2:=MainWindow.ModsPath
				If path2.EndsWith( "/" ) Then path2=path2.Slice( 0,path2.Length-1 )
				
				If path = path2
					
					menu.AddSeparator()
					
					menu.AddAction( "Update / Rebuild modules" ).Triggered=Lambda()
						
						_builder.BuildModules()
					End
					
				Endif
				
				' bananas showcase
				If IsBananasShowcaseAvailable()
					path2=Prefs.MonkeyRootPath+"bananas"
					If path = path2
						
						menu.AddSeparator()
						
						menu.AddAction( "Open bananas showcase" ).Triggered=Lambda()
							
							MainWindow.ShowBananasShowcase()
						End
						
					Endif
				Endif
				
				menu.AddSeparator()
				
				menu.AddAction( "Open on Desktop" ).Triggered=Lambda()
					
					requesters.OpenUrl( path )
				End
			
			
			Case FileType.File
				
				menu.AddAction( "Open on Desktop" ).Triggered=Lambda()
					
					requesters.OpenUrl( path )
				End
				
				menu.AddSeparator()
				
				menu.AddAction( "Rename" ).Triggered=Lambda()
					
					Local oldName:=StripDir( path )
					Local name:=RequestString( "Enter new name:","Ranaming '"+oldName+"'",oldName )
					If Not name Or name=oldName Return
					
					Local newPath:=ExtractDir( path )+name
					
					If FileExists( newPath )
						Alert( "File already exists! Path: '"+newPath+"'" )
						Return
					Endif
					
					If CopyFile( path,newPath )
						
						DeleteFile( path )
						
						browser.Refresh( node.Parent )
						Return
					Endif
					
					Alert( "Failed to rename file: '"+path+"'" )
				End
				
				menu.AddSeparator()
				
				menu.AddAction( "Delete" ).Triggered=Lambda()
					
					DeleteItem( browser,path,node )
				End
			
			Default
				
				Return
			End
			
			' cut / copy / paste
			menu.AddSeparator()
			
			menu.AddAction( "Cut" ).Triggered=Lambda()
			
				OnCut( path )
			End
			
			menu.AddAction( "Copy" ).Triggered=Lambda()
			
				OnCopy( path )
			End
			
			pasteAction=menu.AddAction( "Paste" )
			pasteAction.Triggered=Lambda()
				
				New Fiber( Lambda()
					
					Local ok:=OnPaste( path )
					If ok
						Local n:=browser.IsProjectNode( node ) ? node Else node.Parent
						browser.Refresh( n )
					Endif
				End )
				
			End
			pasteAction.Enabled=(_cutPath Or _copyPath) And isFolder
			
			menu.Open()
		End
		
	End
	
End
