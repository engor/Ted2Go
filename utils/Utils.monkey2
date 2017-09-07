
Namespace ted2go


Function IsLowercacedFirstChar:Bool(s:String)
	
	If Not s Return False
	Local s1:=s.Slice( 0,1 )
	Return s1 = s1.ToLower()
End


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
	
	Function GetIndentBeforePos:String( line:String,pos:Int )
	
		Local n:=pos-1
		
		While n >= 0
		
			If line[n] = 46 'dot
				' dot is valid full-ident part
			ElseIf Not (IsIdent( line[n] ) Or line[n] = 35) '35 => #
				Exit
			Endif
		
			n-=1
		Wend
		n+=1
		Local ident:=(n < pos) ? line.Slice( n,pos ) Else ""
		
		Return ident
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
	
	Function GetAllFiles( rootDir:String,filterExts:String[],target:Stack<String>,idleAppEachN:Int=-1 )
		
		GetAllFilesInternal( rootDir,filterExts,target,idleAppEachN )
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
	
	Function PrintLog<T>( list:List<T>,prefix:String="" )
	
		For Local i:=Eachin list
			Print prefix+""+i
		End
	End
	
	
	Private
	
	Method New()
	End
	
	Function GetAllFilesInternal( dir:String,filterExts:String[],target:Stack<String>,idleAppEachN:Int=-1 )
		
		Local files:=LoadDir( dir )
		Local ii:=0
		For Local f:=Eachin files
			If idleAppEachN>0 And ii Mod idleAppEachN = 0 Then App.WaitIdle()
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

Function FileExists:Bool( path:String )
	
	Return GetFileType( path )=FileType.File
End

Function DirectoryExists:Bool( path:String )
	
	Return GetFileType( path )=FileType.Directory
End

Function FormatTime:String( millis:Long,format:String="{min} m {sec} s" )
	
	millis/=1000
	Local mins:=millis/60
	Local secs:=millis Mod 60
	
	Local s:=format.Replace( "{min}",""+mins )
	s=s.Replace( "{sec}",""+secs )
	
	Return s
End

Function ShowMessage( title:String,msg:String,okButton:String="  OK  " )

	Dialog.Run( title,New Label( msg ),New String[](okButton),0,0 )
End

Function IsIdentStr:Bool( str:String,skipDots:Bool=True )
	
	If Not str Return False
	
	If IsDigit( str[0] ) Return False
	
	If str[0]=Chars.DOT Or str[str.Length-1]=Chars.DOT Return False
	
	For Local c:=Eachin str
		If c=Chars.DOT
			If Not skipDots Return False
		Else
			If Not IsIdent( c ) Return False
		Endif
	Next
	
	Return True
End
