
Namespace std

Class Generator<T>

	Property HasNext:Bool()
	
		Return _hasNext
	End
	
	Method GetNext:T()
	
		Local value:=_next
		
		std.fiber.ResumeFiber( _fiber )
		
		Return value
	End
	
	Protected
	
	Method Start( entry:Void() )
	
		_fiber=std.fiber.StartFiber( Lambda()
		
			_hasNext=True
		
			entry()
			
			_hasNext=False
			
		End )
		
	End
	
	Method Yield( value:T )
	
		_next=value
		
		std.fiber.SuspendCurrentFiber()
	End
	
	Private
	
	Field _fiber:Int
	Field _hasNext:Bool
	Field _next:T
	
End

