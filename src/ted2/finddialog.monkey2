
Namespace ted2

Class FindDialog Extends Dialog

	Method New()
	
		_findField=New TextField
		
		_replaceField=New TextField
		
		_findField.EnterHit=MainWindow.OnFindNext
		_findField.TabHit=Lambda()
			_replaceField.MakeKeyView()
			_replaceField.SelectAll()
		End

		_replaceField.EnterHit=MainWindow.OnFindNext
		_replaceField.TabHit=Lambda()
			_findField.MakeKeyView()
			_findField.SelectAll()
		End
		
		_caseSensitive=New Button( "Case sensitive: " )
		_caseSensitive.Checkable=True
		
		_escapedText=New Button( "Escaped text: ")
		_escapedText.Checkable=True
		
		Local find:=New DockingView
		find.AddView( New Label( "Find:" ),"left",80,False )
		find.ContentView=_findField
		
		Local replace:=New DockingView
		replace.AddView( New Label( "Replace:" ),"left",80,False )
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
		
		AddAction( MainWindow._findNext )
		
		AddAction( MainWindow._findPrevious )
		
		AddAction( MainWindow._findReplace )
		
		AddAction( MainWindow._findReplaceAll )
		
		AddAction( "Close" ).Triggered=Lambda()
			Close()
			MainWindow.UpdateKeyView()
		End

		Opened=Lambda()
			_findField.MakeKeyView()
			_findField.SelectAll()
		End

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
	Field _caseSensitive:Button
	Field _escapedText:Button

	Field _docker:DockingView

End
