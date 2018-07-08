
Namespace ted2go


Class PathsProvider
	
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
	
	Function SetCustomBuildProject( proj:Monkey2Project )
	
		_customBuildProject=proj
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
