
Import brl.filesystem
Import brl.process
Import brl.filepath
Import brl.filestream

Global pos:=0
Global tokes:String[]

Function LoadString:String( path:String )
	Local stream:=FileStream.Open( path,"r" )
	If Not stream Return ""
	Local str:=stream.ReadString()
	stream.Close
	Return str
End

Function SaveString:Void( str:String,path:String )
	Local stream:=FileStream.Open( path,"w" )
	stream.WriteString str
	stream.Close
End

Function GetTokes:Void( text:String )

	Local pos:=0
	Local buf:=New StringStack
	
	Repeat
	
		While pos<text.Length And text[pos]<=32
			pos+=1
		Wend
		
		If pos=text.Length 
			.pos=0
			.tokes=buf.ToArray()
			Return
		Endif
		
		Local start:=pos
		Local chr:=text[pos]
		pos+=1
		
		If (chr>=65 And chr<65+26) Or (chr>=97 And chr<97+26) Or chr=95
			While pos<text.Length
				chr=text[pos]
				If (chr>=65 And chr<65+26) Or (chr>=97 And chr<97+26) Or( chr>=48 And chr<58) Or chr=95
					pos+=1
					Continue
				Endif
				Exit
			Wend
		Else If chr>=48 And chr<58
			If pos<text.Length And text[pos]="x"[0]
				pos+=1
				While pos<text.Length
					chr=text[pos]
					If (chr>=48 And chr<58) Or (chr>=65 And chr<70) Or (chr>=97 And chr<102)
						pos+=1
						Continue
					Endif
					Exit
				Wend
			Else
				While pos<text.Length
					chr=text[pos]
					If chr>=48 And chr<58
						pos+=1
						Continue
					Endif
					Exit
				Wend
			Endif
		Endif
		
		buf.Push text[start..pos]
		
	Forever
End

Function Parse:String()
	If pos=tokes.Length Return ""
	Local toke:=tokes[pos]
	pos+=1
	Return toke
End

Function CParse:Bool( toke:String )
	If pos=tokes.Length Or tokes[pos]<>toke Return False
	pos+=1
	Return True
End

Function Parse:Void( toke:String )
	If Not CParse( toke ) DebugStop
End

Function ParseType:String()

	Local isconst:=CParse( "const" )

	Local ty:=Parse()
	
	If ty="void" ty="Void"
	
	If CParse( "*" ) ty+=" Ptr"
	If CParse( "*" ) ty+=" Ptr"
	
	If isconst And ty="GLchar Ptr" ty="String"
	
	Return ty
End

Function Main()

	While FileType( "gles20.h" )=FILETYPE_NONE
		ChangeDir( ".." )
	Wend
	
	Local file:=LoadString( "gles20.h" )
	Local lines:=file.Split( "~n" )
	
	Local consts:=New StringStack
	Local functions:=New StringStack
	
	For Local line:=Eachin lines

		GetTokes( line )
		
		If CParse( "#" ) And CParse( "define" )
		
			Local id:=Parse()
			
			If id.StartsWith( "GL_" )
				Local ty:="Int"
				consts.Push( "Const "+id+":"+ty )
			Endif
			
		Else If CParse( "GL_APICALL" )
		
			Local retTy:=ParseType()
			
			Parse( "GL_APIENTRY" )
			Local id:=Parse()
			Parse( "(" )
			
			Local argTys:=""
			
			If Not CParse( ")" )
				Repeat
					Local ty:=ParseType()
					If ty="Void" Exit
					Local id:=Parse()+"_"
					If argTys argTys+=","
					argTys+=id+":"+ty
				Until Not CParse( "," )
				Parse( ")" )
			Endif
		
			functions.Push( "Function "+id+":"+retTy+"("+argTys+")" )

		Endif
		
	Next
	
	Local gles20:=LoadString( "gles20.monkey2" )
	
	Local i0:Int,i1:Int,i2:Int
	
	i0=gles20.Find( "~n'${CONSTS}" ) ; If i0=-1 DebugStop
	i1=gles20.Find( "~n",i0+1 ) ; If i1=-1 DebugStop
	i2=gles20.Find( "~n'${END}",i1 ) ; If i2=-1 DebugStop
	
	gles20=gles20[..i1+1]+consts.Join( "~n" )+gles20[i2..]
	
	i0=gles20.Find( "~n'${FUNCTIONS}" ) ; If i0=-1 DebugStop
	i1=gles20.Find( "~n",i0+1 ) ; If i1=-1 DebugStop
	i2=gles20.Find( "~n'${END}",i1 ) ; If i2=-1 DebugStop

	gles20=gles20[..i1+1]+functions.Join( "~n" )+gles20[i2..]
	
	SaveString( gles20,"gles20.monkey2" )
	
	Print "Done!"

End