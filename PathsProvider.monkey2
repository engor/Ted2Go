
Namespace ted2go


Class PathsProvider
	
	Const MX2_TMP:=".mx2"
	
	Function GetActiveMainFilePath:String( checkCurrentDoc:Bool=True,showNoMainFileAlert:Bool=False )
		
		If _customBuildProject
			If showNoMainFileAlert Then ProjectView.CheckMainFilePath( _customBuildProject,True )
			Return _customBuildProject.MainFilePath
		Endif
		
		Local lockedDoc:=docsManager().LockedDocument
		Local path:=lockedDoc?.Path
		If Not path
			If checkCurrentDoc
				path=docsManager().CurrentDocument?.Path
			Endif
			Local proj:=projView().ActiveProject
			If proj
				If showNoMainFileAlert Then ProjectView.CheckMainFilePath( proj,True )
				If proj.MainFilePath
					path=proj.MainFilePath
				Endif
			Endif
		Endif
		
		If Not CodeParsing.IsFileBuildable( path )
			'If showNoMainFileAlert Then Alert( "Unsupported file format - "+ExtractExt( path )+"!~nFile must have .monkey2 extension to be buildable.","Build error" )
			path=""
		Endif
		
'		Print "locked: "+_docsManager.LockedDocument?.Path
'		Print "active: "+_projectView.ActiveProject?.MainFilePath
'		Print "current: "+_docsManager.CurrentDocument?.Path
		
		Return path
	End
	
	Function GetMainFileOfDocument:String( path:String )
		
		'Print "GetFilePathToParse: "+path
		
		' is it a module file?
		'
		Local modsDir:=Prefs.MonkeyRootPath+"modules/"
		' excluding of tests dirs
		'
		If path.StartsWith( modsDir ) And path.Find( "/tests/")=-1
			Local i1:=modsDir.Length
			Local i2:=path.Find( "/",i1+1 )
			If i2<>-1
				Local modName:=path.Slice( i1,i2 )
				' main file of a module
				'
				Return modsDir+modName+"/"+modName+".monkey2"
			Endif
		Else
			' priority for locked file
			'
			Local lockedPath:=docsManager().LockedDocument?.Path
			If lockedPath
				If ExtractDir( path ).Contains( ExtractDir( lockedPath ) )
					' will parse locked file coz 'path' is under 'locked' folder
					Return lockedPath
				Endif
			Endif
			' check as a part of project
			'
			Local proj:=ProjectView.FindProject( path )
			If proj
				Local showNote:=True
				If proj.MainFilePath
					Return proj.MainFilePath
				Endif
				If showNote Then ProjectView.CheckMainFilePath( proj,False )
			Endif
		Endif
		
		' as is
		Return path
	End
	
	Function SetCustomBuildProject( proj:Monkey2Project )
	
		_customBuildProject=proj
	End
	
	Function GetGeninfoPath:String( filePath:String )
		
		Return ExtractDir( filePath )+MX2_TMP+"/"+StripDir( StripExt( filePath ) )+".geninfo"
	End
	
	Function GetTempFilePathForParsing:String( srcPath:String )
		
		Local dir:=ExtractDir( srcPath )+MX2_TMP+"/"
		CreateDir( dir )
		Local name:=StripDir( srcPath )
		
		Return dir+name
	End
	
	
	Private
	
	Global _customBuildProject:Monkey2Project
	
	Function GetActiveProject:Monkey2Project()
	
		If _customBuildProject Return _customBuildProject
	
		Return projView().ActiveProject
	End
	
	Function projView:ProjectView()
		
		Global _projView:ProjectView
		If Not _projView Then _projView=Di.Resolve<ProjectView>()
		
		Return _projView
	End
	
	Function docsManager:DocumentManager()
		
		Global _docsManager:DocumentManager
		If Not _docsManager
			' dirty but better than MainWindow.DocsManager
			_docsManager=Di.Resolve<DocumentManager>()
		Endif
		
		Return _docsManager
	End
End
