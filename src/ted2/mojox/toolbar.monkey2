
Namespace mojox

Class ToolButton Extends Button

	Method New( action:Action )
		Super.New( action )
		Style=Style.GetStyle( "mojo.ToolButton" )
	End
	
End

Class ToolBar Extends DockingView

	Method New()
		Layout="fill"
		Style=Style.GetStyle( "mojo.ToolBar" )
	End

	Method AddAction( action:Action )
		Local button:=New ToolButton( action )
		AddView( button,"left",0 )
	End
	
	
	Method AddAction:Action( label:String="",icon:Image=Null )
		Local action:=New Action( label,icon )
		AddAction( action )
		Return action
	End

End
