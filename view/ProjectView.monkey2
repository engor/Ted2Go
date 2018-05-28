
Namespace ted2go


Class ProjectView Extends DockingView

	Field openProjectFolder:Action
	Field openProjectFile:Action
	Field setMainFile:Action
	
	Field ProjectOpened:Void( path:String )
	Field ProjectClosed:Void( path:String )
	Field ActiveProjectChanged:Void( proj:Monkey2Project )
	
	Field RequestedFindInFolder:Void( folder:String )
	Field MainFileChanged:Void( path:String,prevPath:String )
	
	Method New( docs:DocumentManager,builder:IModuleBuilder )
	
		_docs=docs
		_builder=builder
		
		_docker=New DockingView
		
		ContentView=_docker
		
		openProjectFolder=New Action( "Open project folder" )
		openProjectFolder.HotKey=Key.O
		openProjectFolder.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		openProjectFolder.Triggered=OnOpenProjectFolder
		
		openProjectFile=New Action( "Open project file" )
		'openProjectFile.HotKey=Key.O
		'openProjectFile.HotKeyModifiers=Modifier.Menu|Modifier.Shift
		openProjectFile.Triggered=OnOpenProjectFile
		
		setMainFile=New Action( "Set as main file" )
		setMainFile.Triggered=Lambda()
			
			Local doc:=_docs.CurrentCodeDocument
			If doc Then SetMainFile( doc.Path )
		End
		
		InitProjBrowser()
		
'		_docs.LockedDocumentChanged+=Lambda:Void()
'			Local path:=_docs.LockedDocument?.Path
'			If path Then SetActiveProject( path )
'		End
		
		App.Activated+=Lambda()
			
			For Local proj:=Eachin _projects
				proj.Reload()
			Next
		End
		
		ActiveProjectChanged+=Lambda( proj:Monkey2Project )
		
			_projBrowser?.SetActiveProject( proj )
			_projBrowser?.SetMainFile( proj.MainFilePath,True )
		End
		
		MainFileChanged+=Lambda( path:String,prevPath:String )
			
			_projBrowser?.SetMainFile( prevPath,False )
			_projBrowser?.SetMainFile( path,True )
		End
	End
	
	Property SelectedItem:ProjectBrowserView.Node()
	
		Return Cast<ProjectBrowserView.Node>( _projBrowser.Selected )
	End
	
	Property OpenProjects:Stack<Monkey2Project>()
		
		Return _projects
	End
	
	Property OpenProjectsFolders:String[]()
	
		Local folders:=New String[_projects.Length]
		For Local i:=0 Until _projects.Length
			folders[i]=_projects[i].Folder
		Next
	
		Return folders
	End
	
	Property ActiveProject:Monkey2Project()
	
		Return _activeProject
	End
	
	Property SingleClickExpanding:Bool()
	
		Return _projBrowser.SingleClickExpanding
	
	Setter( value:Bool )
		
		_projBrowser.SingleClickExpanding=value
	End
	
	Function FindProject:Monkey2Project( filePath:String )
	
		If Not filePath Return Null
		
		filePath=StripSlashes( filePath )
	
		For Local proj:=Eachin _projects
			If filePath.StartsWith( proj.Folder )
				Return proj
			Endif
		Next
		
		Return Null
	End
	
	Function IsProjectFile:Bool( filePath:String )
	
		Return ExtractExt( filePath )=".mx2proj"
	End
	
	Function ActiveProjectName:String()
	
		Return _activeProject?.Name
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
	
	Method SetActiveProject( path:String )
		
		Local proj:=FindProject( path )
		If proj
			If proj.IsFolderBased
				Local yes:=RequestOkay( "Can't set folder-based project as active.~n~nDo you want create project file for the project?","Projects","Yes","No" )
				If Not yes Return
				Local name:=RequestString( "Project name:","Projects",StripDir( proj.Folder ) ).Trim()
				If Not name
					Alert( "No name was entered, so do nothing.","Projects" )
					Return
				Endif
				If ExtractExt( name )<>".mx2proj"
					name+=".mx2proj"
				Endif
				Local path:=proj.Folder+"/"+name
				Monkey2Project.SaveEmptyProject( path )
				OpenProject( path )
				SetActiveProject( path )
			Endif
			OnActiveProjectChanged( proj )
		Endif
	End
	
	Method SetMainFile( path:String )
	
		Local proj:=FindProject( path )
		If proj
			Local prev:=proj.MainFilePath
			proj.MainFilePath=path
			MainFileChanged( path,prev )
		Endif
	End
	
	Method OpenProject:Bool( path:String )
		
		Local proj:=FindProject( path )
		
		If proj ' silently close it
			_projects-=proj
			_projBrowser.RemoveProject( proj )
		Endif
		
		proj=New Monkey2Project( path )
		
		_projects+=proj
		
		_projBrowser.AddProject( proj )
		
		ProjectOpened( proj.Path )
		
		Return True
	End
	
	Method CloseProject( dir:String )
		
		Local proj:=FindProject( dir )
		If Not proj Return
		
		_projBrowser.RemoveProject( proj )
		
		_projects-=proj
		
		ProjectClosed( dir )
	End
	
	Method SaveState( jobj:JsonObject )
		
		Local j:=New JsonObject
		jobj["projectsExplorer"]=j
		
		Local jarr:=New JsonArray
		For Local p:=Eachin _projects
			jarr.Add( New JsonString( p.Path ) )
		Next
		j["openProjects"]=jarr
		
		_projBrowser.SaveState( j,"expanded" )
		
		Local selPath:=GetNodePath( _projBrowser.Selected )
		j["selected"]=New JsonString( selPath )
		
		If _activeProject Then j["active"]=New JsonString( _activeProject.Path )
	End
	
	Property HasOpenedProjects:Bool()
		
		Return _projects.Length>0
	End
	
	Method LoadState( jobj:JsonObject )
		
		If Not jobj.Contains( "projectsExplorer" ) Return
		
		jobj=new JsonObject( jobj["projectsExplorer"].ToObject() )
		
		_projBrowser.LoadState( jobj,"expanded" )
		
		If jobj.Contains( "openProjects" )
			Local arr:=jobj["openProjects"].ToArray()
			For Local path:=Eachin arr
				OpenProject( path.ToString() )
			Next
			If arr.Length=1
				jobj["active"]=New JsonString( _projects[0].Path )
			Endif
		Endif
		
		Local selPath:=Json_GetString( jobj.Data,"selected","" )
		If selPath Then _projBrowser.SelectByPath( selPath )
		
		Local activePath:=Json_GetString( jobj.Data,"active","" )
		If activePath Then SetActiveProject( activePath )
	End
	
	
	Protected
	
	
	Private
	
	Field _docs:DocumentManager
	Field _docker:=New DockingView
	'Global _projectFolders:=New StringStack
	Global _projects:=New Stack<Monkey2Project>
	Field _builder:IModuleBuilder
	Field _projBrowser:ProjectBrowserView
	Global _activeProject:Monkey2Project
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
				
				If Not RequestOkay( "Really delete file '"+path+"'?" ) Return
				
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
	
	Method OnOpenProjectFolder()
	
		Local dir:=MainWindow.RequestDir( "Select project folder...","" )
		If Not dir Return
	
		OpenProject( dir )
		
		If _projects.Length=1
			OnActiveProjectChanged( _projects[0] )
		Endif
	End
	
	Method OnActiveProjectChanged( proj:Monkey2Project )
		
		_activeProject=proj
		ActiveProjectChanged( _activeProject )
	End
	
	Method OnOpenProjectFile()
	
		Local file:=MainWindow.RequestFile( "Select project file...","",False,"Monkey2 projects:mx2proj" )
		If Not file Return
	
		OpenProject( file )
		
		If _projects.Length=1
			OnActiveProjectChanged( _projects[0] )
		Endif
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
		_docker.ContentView=browser
		
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
			Local fileType:=GetFileType( path )
			
			menu.AddAction( "Open on Desktop" ).Triggered=Lambda()
				
				Local p:=(fileType=FileType.File) ? ExtractDir( path ) Else path
				requesters.OpenUrl( p )
			End
			menu.AddAction( "Copy path" ).Triggered=Lambda()
				
				App.ClipboardText=path
			End
			
			menu.AddSeparator()
			
			
			Select fileType
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
				
				menu.AddAction( "New file" ).Triggered=Lambda()
					
					Local file:=RequestString( "New file name:","New file",".monkey2" )
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
				
				menu.AddSeparator()
				
				menu.AddAction( "Rename folder" ).Triggered=Lambda()
				
					Local oldName:=StripDir( path )
					Local name:=RequestString( "Enter new name:","Ranaming '"+oldName+"'",oldName )
					If Not name Or name=oldName Return
					
					Local i:=path.Slice( 0,path.Length-1 ).FindLast( "/" )
					If i<>-1
						
						Local newPath:=path.Slice( 0,i+1 )+name
						
						If DirectoryExists( newPath )
							Alert( "Folder already exists! Path: '"+newPath+"'" )
							Return
						Endif
						
						Local ok:=(libc.rename( path,newPath )=0)
						If ok
							browser.Refresh( node.Parent )
							Return
						Endif
					
						Alert( "Failed to rename folder: '"+path+"'" )
					Endif
				End
				
				menu.AddAction( "Delete" ).Triggered=Lambda()
					
					DeleteItem( browser,path,node )
				End
				
				menu.AddSeparator()
				
				If browser.IsProjectNode( node ) ' root node
					
					menu.AddAction( "Set as active project" ).Triggered=Lambda()
					
						SetActiveProject( path )
					End
					
					menu.AddAction( "Close project" ).Triggered=Lambda()
					
						If Not RequestOkay( "Really close project?" ) Return
					
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
				
			
			Case FileType.File
				
				menu.AddAction( "Set as main file" ).Triggered=Lambda()
				
					SetMainFile( path )
				End
				menu.AddSeparator()
				
				menu.AddAction( "Rename file" ).Triggered=Lambda()
					
					Local oldName:=StripDir( path )
					Local name:=RequestString( "Enter new name:","Ranaming '"+oldName+"'",oldName )
					If Not name Or name=oldName Return
					
					Local newPath:=ExtractDir( path )+name
					
					If FileExists( newPath )
						Alert( "File already exists! Path: '"+newPath+"'" )
						Return
					Endif
					
					Local ok:=(libc.rename( path,newPath )=0)
					If ok
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
			
			' collapse all
			'
			If isFolder
				
				menu.AddSeparator()
				
				menu.AddAction( "Collapse all" ).Triggered=Lambda()
				
					_projBrowser.CollapseAll( node )
				End
			Endif
				
			menu.Open()
		End
		
	End
	
End


Class Monkey2Project
	
	Function SaveEmptyProject( path:String )
		
		Local jobj:=New JsonObject
		jobj["mainFile"]=New JsonString
		jobj["excluded"]=New JsonArray
		
		SaveString( jobj.ToJson(),path )
	End
	
	Method New( path:String )
		
		_path=path
		
		If GetFileType( path )=FileType.File
			_data=JsonObject.Load( path )
			_modified=GetFileTime( path )
			path=ExtractDir( path )
		Else
			_data=New JsonObject
			_isFolderBased=True
		Endif
		
		_folder=StripSlashes( path )
	End
	
	Property MainFile:String()
		Return _data.GetString( "mainFile" )
	End
	
	Property MainFilePath:String()
		Local main:=MainFile
		Return main ? Folder+"/"+main Else ""
	Setter( value:String )
		_data.SetString( "mainFile",value.Replace(Folder+"/","" ) )
		OnChanged()
	End
	
	Property Folder:String()
		Return _folder
	End
	
	Property Name:String()
		Return StripDir( _folder )
	End
	
	Property IsFolderBased:Bool()
		Return _isFolderBased
	End
	
	Property Path:String()
		Return _path
	End
	
	Property Modified:Int()
		Return _modified
	End
	
	Property Excluded:String[]()
		
		If _modified=0 Return New String[0]
		If _modified=_excludedTime Return _excluded
		
		Local jarr:=_data.GetArray( "excluded" )
		If Not jarr Or jarr.Empty Return New String[0]
		
		_excluded=New String[jarr.Length]
		For Local i:=0 Until jarr.Length
			_excluded[i]=jarr[i].ToString()
		Next
		
		Return _excluded
	End
	
	Method Save()
		
		If Not _isFolderBased Then SaveString( _data.ToJson(),_path )
	End
	
	Method Reload()
	
		If _isFolderBased Return
		
		Local t:=GetFileTime( _path )
		If t>_modified
			_data=JsonObject.Load( _path )
			_modified=t
		Endif
	End
	
	Private
	
	Field _path:String,_folder:String
	Field _data:JsonObject
	Field _isFolderBased:Bool
	Field _modified:Int
	Field _excluded:String[],_excludedTime:Int
	
	Method OnChanged()
		
		Save()
	End
	
End
