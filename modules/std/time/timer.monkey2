
#If __TARGET__="emscripten"

#Import "timer_emscripten"

#Else

Namespace std.timer

Private

Using std.time
Using std.collections
Using std.fiber

Public

Class Timer

	Method New( hertz:Double,fired:Void() )
	
		New Fiber( Lambda()
		
			Local period:=1/hertz
		
			Local timeout:=Now()+period
	
			While Not _cancelled
			
				Local now:=Now()
			
				Local sleep:=timeout-now
				If sleep>0
					Fiber.Sleep( sleep )
					Continue
				Endif
				
				If Not _suspended fired()

				timeout+=period

			Wend
		
		End )

	End
	
	Property Suspended:Bool()
	
		Return _suspended
	
	Setter( suspended:Bool )
	
		_suspended=suspended
	End
	
	Method Cancel()
	
		_cancelled=True
	End
	
	Private
	
	Field _suspended:Bool
	
	Field _cancelled:Bool
End

#Endif
