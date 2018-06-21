
Namespace ted2go


Class PathsProvider
	
	Function GetActiveMainFilePath:String( checkCurrentDoc:Bool=True,showNoMainFileAlert:Bool=False )
		
		If _customBuildProject
			If showNoMainFileAlert Then ProjectView.CheckMainFilePath( _customBuildProject )
			Return _customBuildProject.MainFilePath
		Endif
		
		Global _docsManager:DocumentManager
		If Not _docsManager
			' dirty but better than MainWindow.DocsManager
			_docsManager=Di.Resolve<DocumentManager>()
		Endif
		
		Local path:=_docsManager.LockedDocument?.Path
		If Not path
			Local proj:=GetActiveProject()
			If proj
				If showNoMainFileAlert Then ProjectView.CheckMainFilePath( proj )
				Return proj.MainFilePath
			Endif
		Endif
		If Not path And checkCurrentDoc
			path=_docsManager.CurrentDocument?.Path
			If Not CodeParsing.IsFileBuildable( path )
				'If showNoMainFileAlert Then Alert( "Unsupported file format - "+ExtractExt( path )+"!~nFile must have .monkey2 extension to be buildable.","Build error" )
				path=""
			Endif
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
	
		Global _projView:ProjectView
		If Not _projView Then _projView=Di.Resolve<ProjectView>()
		
		Return _projView.ActiveProject
	End
End
