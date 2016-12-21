
Namespace ted2go


Class FindInFilesDialog Extends DialogExt

	Method New( actions:FindActions,projView:ProjectView )
	
		_findField=New TextField
		
		_findField.Entered+=Lambda()
			actions.findNext.Trigger()
		End
		
		_projList=New ListView
		_filterField=New TextField( "monkey2,txt" )
		
		_caseSensitive=New CheckButton( "Case sensitive" )
		_caseSensitive.Layout="float"
		
		Local table:=New TableView( 2,3 )
		table[0,0]=New Label( "Find" )
		table[1,0]=_findField
		table[0,1]=New Label( "Where" )
		table[1,1]=_projList
		table[0,2]=New Label( "Filter" )
		table[1,2]=_filterField
		
		_docker=New DockingView
		_docker.AddView( table,"top" )
		_docker.AddView( _caseSensitive,"top" )
		_docker.AddView( New Label( " " ),"top" )
		
		Title="Find in files"
		
		MaxSize=New Vec2i( 512,0 )
				
		ContentView=_docker
		
		AddAction( actions.findAllInFiles )
		
		Local close:=AddAction( "Close" )
		SetKeyAction( Key.Escape,close )
		close.Triggered=Hide
		
		_findField.Activated+=_findField.MakeKeyView
		
		Deactivated+=MainWindow.UpdateKeyView
				
		OnShow+=Lambda()
			Local projs:=projView.OpenProjects
			If Not projs Return
			_projList.RemoveAllItems()
			Local sel:ListView.Item=Null
			For Local p:=Eachin projs
				Local it:=_projList.AddItem( p )
				If Not sel Then sel=it
			Next
			_projList.Selected=sel
		End
		
	End
	
	Property FindText:String()
	
		Return _findField.Text
	End
	
	Property FilterText:String()
	
		Return _filterField.Text.Trim()
	End
	
	Property SelectedProject:String()
	
		Return _projList.Selected.Text
	End
	
	Property CaseSensitive:Bool()
	
		Return _caseSensitive.Checked
	End
	
	Method SetInitialText( find:String )
		
		_findField.Text=find
		_findField.SelectAll()
	End
	
	
	Private
	
	Field _findField:TextField
	Field _filterField:TextField
	Field _caseSensitive:CheckButton
	Field _projList:ListView
	Field _docker:DockingView
	
End
