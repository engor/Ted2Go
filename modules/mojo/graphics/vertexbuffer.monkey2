
Namespace mojo.graphics

#rem monkeydoc @hidden
#end	
Class VertexBuffer

	Method New( capacity:Int )
	
		_capacity=capacity
		
		_data=New Vertex2f[_capacity]
	End
	
	Property Capacity:Int()
	
		Return _capacity
	End

	Property Length:Int()
	
		Return _length
	End
	
	Property Pitch:Int()
	
		Return 28
	End
	
	Method Clear()
	
		_length=0
		_clean=0
	End
	
	Method AddVertices:Vertex2f Ptr( count:Int )
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
			glBindBuffer( GL_ARRAY_BUFFER,_glvbo )
			glBufferData( GL_ARRAY_BUFFER,_capacity * Pitch,Null,GL_DYNAMIC_DRAW )
		Else
			glBindBuffer( GL_ARRAY_BUFFER,_glvbo )
		Endif
		
		glEnableVertexAttribArray( 0 ) ; glVertexAttribPointer( 0,2,GL_FLOAT,False,Pitch,Cast<Void Ptr>( 0 ) )
		glEnableVertexAttribArray( 1 ) ; glVertexAttribPointer( 1,2,GL_FLOAT,False,Pitch,Cast<Void Ptr>( 8 ) )
		glEnableVertexAttribArray( 2 ) ; glVertexAttribPointer( 2,2,GL_FLOAT,False,Pitch,Cast<Void Ptr>( 16 ) )
		glEnableVertexAttribArray( 3 ) ; glVertexAttribPointer( 3,4,GL_UNSIGNED_BYTE,True,Pitch,Cast<Void Ptr>( 24 ) )

	End
	
	Method Validate()
	
		If _clean=_length Return
		
		_clean=_length
		
		'mythical 'orphaning'...
'		glBufferData( GL_ARRAY_BUFFER,_capacity*Pitch,Null,GL_DYNAMIC_DRAW )	

'		glBufferSubData( GL_ARRAY_BUFFER,0,_length*Pitch,_data.Data )

		'lazy - but fastest?
		glBufferData( GL_ARRAY_BUFFER,_length*Pitch,_data.Data,GL_DYNAMIC_DRAW )
	End
		
	Private
	
	Field _capacity:Int
	
	Field _length:Int
	
	Field _clean:Int
	
	Field _data:Vertex2f[]
	
	Field _glvbo:GLuint
	
	Field _seq:Int

End
