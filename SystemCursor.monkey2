
Namespace ted2go

Using sdl2..


#Rem This class incapsulate operations with raw SDL_Cursor.
#End
Class SystemCursor
	
	Enum Kind
		Arrow,Beam,Wait,WaitArrow,Hand,No,CrossHair,
		SizeNWSE,SizeNESW,SizeWE,SizeNS,SizeAll
	End
	
	Function Set( cursor:Kind )
		
		Local c:=_cursors[cursor]
		If Not c
			c=Create( cursor )
			_cursors[cursor]=c
		End
		SDL_SetCursor( c )
	End
	
	Function Store( owner:Object )
		
		_stored[owner]=SDL_GetCursor()
	End
	
	Function Restore( owner:Object )
	
		Local c:=_stored[owner]
		If c
			SDL_SetCursor( c )
			_stored.Remove( owner )
		Endif
	End
	
	
	Private
	
	Global _cursors:=New Map<Kind,SDL_Cursor Ptr>
	Global _stored:=New Map<Object,SDL_Cursor Ptr>
	
	Function Create:SDL_Cursor Ptr( cursor:Kind )
		
		Local cur:SDL_SystemCursor
		Select cursor
			Case Kind.Arrow
				cur=SDL_SYSTEM_CURSOR_ARROW
			Case Kind.Beam
				cur=SDL_SYSTEM_CURSOR_IBEAM
			Case Kind.Wait
				cur=SDL_SYSTEM_CURSOR_WAIT
			Case Kind.CrossHair
				cur=SDL_SYSTEM_CURSOR_CROSSHAIR
			Case Kind.WaitArrow
				cur=SDL_SYSTEM_CURSOR_WAITARROW
			Case Kind.No
				cur=SDL_SYSTEM_CURSOR_NO
			Case Kind.Hand
				cur=SDL_SYSTEM_CURSOR_HAND
			Case Kind.SizeNWSE
				cur=SDL_SYSTEM_CURSOR_SIZENWSE
			Case Kind.SizeNESW
				cur=SDL_SYSTEM_CURSOR_SIZENESW
			Case Kind.SizeWE
				cur=SDL_SYSTEM_CURSOR_SIZEWE
			Case Kind.SizeNS
				cur=SDL_SYSTEM_CURSOR_SIZENS
			Case Kind.SizeAll
				cur=SDL_SYSTEM_CURSOR_SIZEALL
		End
		Return SDL_CreateSystemCursor( cur )
	End
End
