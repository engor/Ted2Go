
Namespace mx2.docs

Class MarkdownBuffer

	Alias LinkResolver:String( link:String )

	Method New( linkResolver:LinkResolver=Null )
		_linkResolver=linkResolver
	End
	
	Property Label:String()
		Return _label
	End

	Method Emit( markdown:String )
	
		If Not markdown.Contains( "~n" )
			_buf.Push( ReplaceLinks( markdown ) )
			Return
		Endif
		
		Local lines:=markdown.Split( "~n" )
		
		For Local i:=0 Until lines.Length
		
			Local line:=lines[i].Trim()
			
			If line.StartsWith( "@" )

				Local j:=FindSpc( line )
				Local id:=line.Slice( 1,j )
				line=line.Slice( j ).Trim()
				
				Select id
				Case "label"
				
					_label=line
					
				Case "param"
				
					_params.Push( line )
					
				Case "return"
				
					_return=line
					
				Case "example"
				
					Local indent:=FindChar( lines[i] )
					i+=1
					
					_buf.Push( "```" )
					
					Local buf:=New StringStack
					
					While i<lines.Length
						Local line:=lines[i]
						If line.Trim().StartsWith( "@end" ) Exit
						i+=1
						line=line.Slice( indent )
						If line.StartsWith( "\#" ) line=line.Slice( 1 )
						buf.Push( line )
					Wend
					
					_buf.Push( buf.Join( "~n" ).Trim() )
					
					_buf.Push( "```" )
					
				Case "see"
				
					Continue
				
				Default
				
					Print "MarkdownBuffer: unrecognized '"+lines[i]+"'"
					
				End

				Continue
			Endif
			
			_buf.Push( ReplaceLinks( line ) )
			
		Next
	
	End
	
	Method EmitBr()
	
		_buf.Push( "" )
	End
	
	Method Flush:String()

		If _params.Length	
		
			EmitBr()
			Emit( "| Parameters |    |" )
			Emit( "|:-----------|:---|" )
			
			For Local p:=Eachin _params
			
				Local i:=FindSpc( p )
				Local id:=p.Slice( 0,i )
				p=p.Slice( i ).Trim()
				
				If Not id Or Not p Continue
				
				Emit( "| `"+id+"` | "+p+" |" )
			Next
			
			_params.Clear()
			
		Endif
		
		Local markdown:=_buf.Join( "~n" ).Trim()+"~n"
		
		_buf.Clear()
		
		_return=""
		
		_label=""
		
		Local docs:=hoedown.MarkdownToHtml( markdown )
		
		Return docs
	End
	
	Private
	
	Field _linkResolver:LinkResolver
	Field _buf:=New StringStack
	Field _params:=New StringStack
	Field _return:String
	Field _label:String
	
	Method FindSpc:Int( str:String )
		For Local i:=0 Until str.Length
			If str[i]<=32 Return i
		Next
		Return str.Length
	End

	Method FindChar:Int( str:String )
		For Local i:=0 Until str.Length
			If str[i]>32 Return i
		Next
		Return -1
	End
	
	Method ReplaceLinks:String( line:String )
	
		Repeat
			Local i0:=line.Find( "[[" )
			If i0=-1 Return line
			
			Local i1:=line.Find( "]]",i0+2 )
			If i1=-1 Return line
			
			Local path:=line.Slice( i0+2,i1 )
			Local link:=path
			
			If _linkResolver<>Null
				link=_linkResolver( path )
				If Not link
					Print "Makedocs error: Can't resolve link '"+path+"'"
					link=path
				Endif
			Endif
			
			line=line.Slice( 0,i0 )+link+line.Slice( i1+2 )
		Forever
		
		Return line
	End

End

