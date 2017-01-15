
Namespace ted2go


Class Utils
	
	Function ArrayContains<T>:Bool( arr:T[],value:T )
		If Not arr Return False
		For Local v:=Eachin arr
			If v = value Return True
		Next
		Return False
	End

	Function ValueAt<T>:T( list:List<T>,index:Int )
		Local k:=0
		For Local i:=Eachin list
			If k = index Return i
			k+=1
		End
		Return Null
	End
	
	Function RepeatInvoke<T>( func:T(),count:Int )
		For Local k:=0 Until count
			func()
		Next
	End
	
	Function GetIndent:Int( line:String )
		Local len:=line.Length,n:=0
		While n < len And line[n] <= 32
			n+=1
		Wend
		Return n
	End
		
	Function GetIndentStr:String( line:String )
		Local n:=GetIndent( line )
		Return  (n > 0) ? line.Slice( 0,n ) Else ""
	End
	
	Function DrawRect( canvas:Canvas,rect:Rectf,fill:Bool )
		If fill
			canvas.DrawRect( rect )
		Else
			canvas.DrawLine( rect.Left,rect.Top,rect.Right,rect.Top )
			canvas.DrawLine( rect.Right,rect.Top,rect.Right,rect.Bottom )
			canvas.DrawLine( rect.Left,rect.Bottom,rect.Right,rect.Bottom )
			canvas.DrawLine( rect.Left,rect.Top,rect.Left,rect.Bottom )
		End
	End
	
	Function RepeatStr:String( str:String,count:Int )
		Local result:=""
		For Local i:=0 Until count
			result+=str
		Next
		Return result
	End
	
	Function GetAllFiles( rootDir:String,filterExts:String[],target:Stack<String> )
		
		GetAllFilesInternal( rootDir,filterExts,target )
	End
	
	#Rem monkeydoc If 'any' is true - check at least one starts, else - check all.
	#End
	Function BatchStartsWith:Bool( text:String,values:String[],any:Bool )
	
		For Local i:=0 Until values.Length
			Local ok:=text.StartsWith( values[i] )
			If ok 
				If any Return True
			Else
				If Not any Return False
			Endif
		Next
		
		Return any ? False Else True
	End
	
	Function BatchContains:Bool( text:String,values:String[],any:Bool )
	
		For Local i:=0 Until values.Length
			Local ok:=text.Contains( values[i] )
			If ok 
				If any Return True
			Else
				If Not any Return False
			Endif
		Next
	
		Return any ? False Else True
	End
	
	#Rem monkeydoc 
	@return arr[2] or null, arr[0] - position of first found match or -1 if not found, arr[1] - index of matched value from values array
	#End
	Function FindAny:Int[]( text:String,values:String[] )
	
		For Local i:=0 Until values.Length
			Local p:=text.Find( values[i] )
			If p<>-1 Return New Int[](p,i)
		Next
		
		Return Null
	End
	
	Private
	
	Method New()
	End
	
	Function GetAllFilesInternal( dir:String,filterExts:String[],target:Stack<String> )
		
		Local files:=LoadDir( dir )
		For Local f:=Eachin files
			f=dir+f
			If GetFileType( f )=FileType.Directory
				GetAllFilesInternal( f+"/",filterExts,target )
			Else
				Local ext:=ExtractExt( f )
				If Not ext Continue
				ext=ext.Slice( 1 ) 'skip dot
				If ArrayContains( filterExts,ext ) Then target.Add( f )
			Endif
		End
	End
	
End
