
Namespace mojox

#rem monkeydoc The ToolButton class.
#end
Class ToolButton Extends Button

	Method New( action:Action )
		Super.New( action )
		
		Style=GetStyle( "ToolButton" )
		
		PushButtonMode=True
	End
	
End

#rem monkeydoc The ToolBar class.
#end
Class ToolBar Extends DockingView

	#rem monkeydoc Creates a new tool bar.
	#end
	Method New()
		Self.New( std.geom.Axis.X )
	End
	
	Method New( axis:Axis )
		Style=GetStyle( "ToolBar" )
		
		Layout=(axis=Axis.X ? "fill-x" Else "fill-y")

		Gravity=New Vec2f( 0,0 )
		
		_axis=axis
		_add=axis=Axis.X ? "left" Else "top"
	End
	
	#rem monkeydoc Toolbar axis.
	#end
	Property Axis:Axis()
		Return _axis
	End

	#rem monkeydoc Adds a view to the tool bar.
	#end	
	Method AddView( view:View )
		AddView( view,_add )
	End
	
	#rem monkeydoc Adds a separator to the tool bar.
	#end	
	Method AddSeparator()
		AddView( New MenuSeparator )
	End

	#rem monkeydoc Adds an action to the tool bar.
	#end	
	Method AddAction( action:Action )
		Local button:=New ToolButton( action )
		AddView( button,_add )
	End
	
	Method AddAction:Action( label:String,icon:Image=Null )
		Local action:=New Action( label,icon )
		AddAction( action )
		Return action
	End
	
	Private
	
	Field _axis:Axis
	Field _add:String

End
