
Namespace mojo.graphics


#rem monkeydoc @hidden
#end	
Class IndexBuffer

	Method New( capacity:Int )
	
		_capacity=capacity
		
		_data=New UShort[_capacity]
	End
	
	Property Capacity:Int()
	
		Return _capacity
	End

	Property Length:Int()
	
		Return _length
	End
	
	Property Pitch:Int()
	
		Return 2
	End
	
	Method Clear()
	
		_length=0
		_clean=0
	End
	
	Method AddIndices:UShort Ptr( count:Int )
		If _length+count>_capacity Return Null
		
		Local p:=_data.Data+_length
		_length+=count
		
		Return p
	End
	
	'***** INTERNAL *****
	
	Method Bind()
	
		If _seq<>glGraphicsSeq
			_seq=glGraphicsSeq
			_clean=0
			glGenBuffers( 1,Varptr _glvbo )
			glBindBuffer( GL_ELEMENT_ARRAY_BUFFER,_glvbo )
			glBufferData( GL_ELEMENT_ARRAY_BUFFER,_capacity * Pitch,Null,GL_STATIC_DRAW )
		Else
			glBindBuffer( GL_ELEMENT_ARRAY_BUFFER,_glvbo )
		Endif

	End
	
	Method Validate()
	
		If _clean=_length Return
		
		_clean=_length
		
		'mythical 'orphaning'...
'		glBufferData( GL_ELEMENT_ARRAY_BUFFER,_capacity * Pitch,Null,GL_STATIC_DRAW )

'		glBufferSubData( GL_ELEMENT_ARRAY_BUFFER,0,_length*Pitch,_data.Data )

		'lazy - but fastest?
		glBufferData( GL_ELEMENT_ARRAY_BUFFER,_length*Pitch,_data.Data,GL_STATIC_DRAW )
	End
		
	Private
	
	Field _capacity:Int
	
	Field _length:Int
	
	Field _clean:Int
	
	Field _data:UShort[]
	
	Field _glvbo:GLuint
	
	Field _seq:Int

End
