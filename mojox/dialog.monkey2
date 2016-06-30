
Namespace mojox

Class DialogTitle Extends Label

	Field Dragged:Void( v:Vec2i )

	Method New( text:String="" )
		Super.New( text )
'		Layout="fill"
		Style=Style.GetStyle( "mojo.DialogTitle" )
	End
	
	Private
	
	Field _org:Vec2i
	Field _drag:Bool
	Field _hover:Bool
	
	Method OnMouseEvent( event:MouseEvent ) Override
	
		Select event.Type
		Case EventType.MouseDown
			_drag=True
			_org=event.Location
		Case EventType.MouseUp
			_drag=False
		Case EventType.MouseEnter
			_hover=True
		Case EventType.MouseLeave
			_hover=False
		Case EventType.MouseMove
			If _drag Dragged( event.Location-_org )
		End
		
		If _drag
			StyleState="active"
		Else If _hover
			StyleState="hover"
		Else
			StyleState=""
		Endif
		
	End

End

Class Dialog Extends View

	Field Opened:Void()
	Field Closed:Void()

	Method New()
		Layout="float"
		Style=Style.GetStyle( "mojo.Dialog" )
		Gravity=New Vec2f( 0,0 )
		Visible=False
		
		_title=New DialogTitle
		_title.Layout="fill"
		_title.Style=Style.GetStyle( "mojo.DialogTitle" )
		_title.Dragged=Lambda( vec:Vec2i )
			Offset+=vec
		End
		
		_content=New DockingView
		_content.Style=Style.GetStyle( "mojo.DialogContent" )
		
		_actions=New DockingView
		_actions.Style=Style.GetStyle( "mojo.DialogActions" )
		_actions.Layout="float"
		
		_docker=New DockingView

		_docker.AddView( _title,"top" )
		_docker.ContentView=_content
		_docker.AddView( _actions,"bottom" )
		
		AddChild( _docker )
	End
	
	Method New( title:String )
		Self.New()
		
		Title=title
	End

	Property Title:String()
	
		Return _title.Text
	
	Setter( title:String )
	
		_title.Text=title
	End
	
	Property ContentView:View()
	
		Return _content.ContentView
	
	Setter( contentView:View )
	
		_content.ContentView=contentView
	End
	
	Method AddAction( action:Action )

		Local button:=New Button( action )

		_actions.AddView( button,"left" )
	End
	
	Method AddAction:Action( label:String,icon:Image=Null )
	
		Local action:=New Action( label,icon )
		AddAction( action )
		Return action
	End
	
	Method Open()
	
		Visible=True
	
		_window=App.ActiveWindow
		
		Measure()
		
		Offset=(_window.Rect.Size-MeasuredSize)/New Vec2i( 2,3 )
		
		_window.AddChild( Self )

		Visible=True
		
		Opened()
	End
	
	Method Close()
	
		_window.RemoveChild( Self )
		
		_window=Null
	
		Visible=False
		
		Closed()
	End
	
	Private
	
	Field _title:DialogTitle
	Field _content:DockingView
	Field _actions:DockingView
	Field _docker:DockingView
	Field _window:Window
	
	Method OnMeasure:Vec2i() Override
	
		Return _docker.LayoutSize
	End
	
End

Class TextDialog Extends Dialog

	Method New( title:String="",text:String="" )
		Super.New( title )
		
		_label=New Label( text )
		
		ContentView=_label
	End
	
	Property Text:String()
	
		Return _label.Text
	
	Setter( text:String )
		
		_label.Text=text
		
	End
	
	Function Run:Int( title:String,text:String,buttons:String[] )
	
		Local dialog:=New TextDialog( title,text )
		
		Local result:=New Future<Int>
		
		For Local i:=0 Until buttons.Length
		
			dialog.AddAction( buttons[i] ).Triggered=Lambda()
			
				result.Set( i )
			End
		Next
		
		dialog.Open()
		
		App.BeginModal( dialog )
		
		Local r:=result.Get()
		
		App.EndModal()
		
		dialog.Close()
		
		Return r
	End
	
	Private
	
	Field _label:Label
	
End
