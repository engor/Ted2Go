
Namespace std.resource

Class Resource

	Field OnDiscarded:Void()
	
	Property Discarded:Bool()
	
		Return _discarded
	End
	
	Method Discard()
	
		If _discarded Or _refs Return
		
		_discarded=True
	
		OnDiscard()
		
		OnDiscarded()
	End
	
	Protected
	
	Method OnDiscard() Virtual
	End
	
	Function OpenResource:Resource( slug:String )
	
		Return _open[slug]
	End
	
	Function AddResource( slug:String,r:Resource )
	
		If _open.Contains( slug ) Return
	
		_open[slug]=r
		
		If r r._refs+=1
	End
	
	Private
	
	Field _refs:Int
	
	Field _discarded:=False
	
	Global _open:=New StringMap<Resource>
	
End
