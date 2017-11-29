
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

Function TODO( message:String )
	
	Print "Not implemented yet: '"+message+"'"
	DebugStop()
	MainWindow.GainFocus()
End

Function DoInNotMainFiber( work:Void() )
	
	If Fiber.Current()=Fiber.Main()
		New Fiber( work )
	Else
		work()
	End
End

Function GetOrCreate<T>:T( map:StringMap<T>,key:String )
	
	Local item:=map[key]
	If Not item
		item=New T
		map[key]=item
	Endif
	Return item
End

'Function SplitToCombinations:String[]( str:String,splitter:String="." )
'	
'	
'End


Class Stack<T> Extension
	
	Method AddUnique( value:T )
		
		If Not Self.Contains( value ) Then Self.Add( value )
	End
	
	Operator+=( item:T )
		
		Self.Add( item )
	End
	
	Operator-=( item:T )
	
		Self.Remove( item )
	End
	
	Operator+=( items:T[] )
	
		Self.AddAll( items )
	End
	
End


Struct Recti Extension
	
	Method MoveTo( x:Int,y:Int )
		
		Local size:=Self.Size
		Self.Origin=New Vec2i( x,y )
		Self.Size=size
	End
	
	Method MoveBy( dx:Int,dy:Int )
	
		Local size:=Self.Size
		Self.Origin=Self.Origin+New Vec2i( dx,dy )
		Self.Size=size
	End
End


Function TypeName<T>:String( obj:T ) Where T Extends Object
	
	Return obj ? String.FromCString( obj.typeName() ) Else Null
End

Function FindViewInHierarchy<T>:T( view:View ) Where T Extends View
	
	While view
		Local r:=Cast<T>( view )
		If r Return r
		view=view.Parent
	Wend
	Return Null
End

Function StripEnding:String( text:String,ends:String )
	
	Return text.EndsWith( ends ) ? text.Slice( 0,text.Length-ends.Length ) Else text
End

Function StripStarting:String( text:String,starts:String )
	
	Return text.StartsWith( starts ) ? text.Slice( starts.Length ) Else text
End

#Rem monkeydocs Return ident and position in line where ident starts
#End
Function GetIndentBeforePos_Mx2:Tuple2<String,Int>( line:String,pos:Int,withDots:Bool )
	
	Local n:=pos-1
	
	While n >= 0
	
		Local more:=(line[n]=Chars.MORE_BRACKET)
	
		If line[n] = Chars.DOT Or more ' . | ?. | ->
			If Not withDots Exit
			If more
				If n>0 And line[n-1]<>"-"[0] Exit
				n-=1 ' skip '-'
			Else
				If n>0 And line[n-1]="?"[0] Then n-=1 ' skip '?'
			Endif
		ElseIf Not (IsIdent( line[n] ) Or line[n] = Chars.GRID) ' #
			Exit
		Endif
	
		n-=1
	Wend
	n+=1
	
	Local s:=""
	Local starts:=-1
	If n < pos
		starts=n
		s=line.Slice( n,pos ).Replace( "?.","." ).Replace( "->","." )
	Endif
	Return New Tuple2<String,Int>( s,starts )
End

Function IsPosInsideOfQuotes_Mx2:Bool( text:String,pos:Int )

	Local i:=0
	Local n:=text.Length
	If pos=0 Return False
	Local quoteCounter:=0
	While i < n
		Local c:=text[i]
		If i = pos
			If quoteCounter Mod 2 = 0 'not inside of string
				Return False
			Else 'inside
				Return True
			Endif 
		Endif
		If c = Chars.DOUBLE_QUOTE
			quoteCounter+=1
		Endif
		i+=1
	Wend
	Return (quoteCounter Mod 2 <> 0)
End
