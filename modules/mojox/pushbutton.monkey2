
Namespace mojox

#rem monkeydoc The PushButton class.
#end
Class PushButton Extends Button

	#rem monkeydoc Creates a new push button.
	#end
	Method New( text:String="",icon:Image=Null )
		Super.New( text,icon )
		
		Init()
	End
	
	Method New( action:Action )
		Super.New( action )
		
		Init()
	End
	
	Private
	
	Method Init()

		Style=GetStyle( "PushButton" )
		PushButtonMode=True
	End

End
