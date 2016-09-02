
Namespace ted2

Class FindDialog Extends Dialog

	Method New( actions:FindActions )
	
		_findField=New TextField
		
		_replaceField=New TextField
		
		_findField.Entered+=Lambda()
			actions.findNext.Trigger()
		End

		_findField.Tabbed+=_replaceField.MakeKeyView

		_replaceField.Tabbed+=_findField.MakeKeyView
		
		_caseSensitive=New CheckButton( "Case sensitive" )
		_caseSensitive.Layout="float"
		
'		_escapedText=New CheckButton( "Escaped text" )
		
		Local find:=New DockingView
		find.AddView( New Label( "Find" ),"left",80,False )
		find.ContentView=_findField
		
		Local replace:=New DockingView
		replace.AddView( New Label( "Replace" ),"left",80,False )
		replace.ContentView=_replaceField
		
		_docker=New DockingView
		_docker.AddView( find,"top" )
		_docker.AddView( replace,"top" )
		_docker.AddView( _caseSensitive,"top" )
'		_docker.AddView( _escapedText,"top" )
		_docker.AddView( New Label( " " ),"top" )
		
		Title="Find/Replace"
		
		MaxSize=New Vec2i( 512,0 )
		
		ContentView=_docker
		
		AddAction( actions.findNext )
		AddAction( actions.findPrevious )
		AddAction( actions.replace )
		AddAction( actions.replaceAll )
		
		Local close:=AddAction( "Close" )
		SetKeyAction( Key.Escape,close )
		close.Triggered=Close
		
		_findField.Activated+=_findField.MakeKeyView
		
		Deactivated+=MainWindow.UpdateKeyView
	End
	
	Property FindText:String()
	
		Return _findField.Text
	End
	
	Property ReplaceText:String()
	
		Return _replaceField.Text
	End
	
	Property CaseSensitive:Bool()
	
		Return _caseSensitive.Checked
	End
	
	Private
	
	Field _findField:TextField
	Field _replaceField:TextField
	Field _caseSensitive:CheckButton
	Field _escapedText:CheckButton

	Field _docker:DockingView

End
