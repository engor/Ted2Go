
Namespace ted2go


Class PathsProvider
	
	Function GetActiveMainFilePath:String( checkCurrentDoc:Bool=True,showNoMainFileAlert:Bool=False )
		
		If _customBuildProject
			If showNoMainFileAlert Then ProjectView.CheckMainFilePath( _customBuildProject )
			Return _customBuildProject.MainFilePath
		Endif
		
		Local path:=MainWindow.DocsManager.LockedDocument?.Path
		If Not path
			Local proj:=GetActiveProject()
			If proj
				If showNoMainFileAlert Then ProjectView.CheckMainFilePath( proj )
				Return proj.MainFilePath
			Endif
		Endif
		If Not path And checkCurrentDoc Then path=MainWindow.DocsManager.CurrentDocument?.Path
		
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
	
		Return MainWindow.ProjView.ActiveProject
	End
End
