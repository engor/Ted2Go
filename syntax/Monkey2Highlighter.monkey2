
Namespace ted2go


Class Monkey2Highlighter Extends HighlighterPlugin

	Property Name:String() Override
		Return "Monkey2Highlighter"
	End

	
	Private
	
	Global _instance:=New Monkey2Highlighter
	
	Method New()
		Super.New()
		_types=New String[]( ".monkey2",".json" )
		_hl=New Highlighter
		_hl.Painter=HL
	End
	
	Method HL:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )

        If _keywords = Null Then _keywords=KeywordsManager.Get( GetMainFileType() )

		Local i0:=sol
		
		Local icolor:=0
		Local istart:=sol
		Local preproc:=False
	
		'comment nest
		'
		Local cnest:=state & 255
		If cnest=255 cnest=-1
		
		'block string flag
		'	
		Local blkstr:=(state & 256)=0
		
		If cnest<>-1 
			icolor=Highlighter.COLOR_COMMENT
		Else If blkstr
			icolor=Highlighter.COLOR_STRING
		Endif
		
		While i0<eol
		
			Local start:=i0
			Local chr:=text[i0]
			i0+=1
			
			If IsSpace( chr ) Continue
			
			If blkstr
				If chr=34 blkstr=False
				Continue
			Endif
			
			If chr=35 And istart=sol
				preproc=True
				If cnest=-1 icolor=Highlighter.COLOR_PREPROC
				Continue
			Endif
			
			If preproc And (IsAlpha( chr ) Or chr=95)
	
				While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
					i0+=1
				Wend
				
				Local id:=text.Slice( start,i0 )
				
				Select id.ToLower()
				Case "rem"
					cnest+=1
					icolor=Highlighter.COLOR_COMMENT
				Case "end"
					If cnest<>-1
						cnest-=1
						icolor=Highlighter.COLOR_COMMENT
					Endif
				End
				
				Exit
			
			Endif
			
			If cnest<>-1 Or preproc Exit
			
			Local color:=icolor
			
			If chr=39
			
				i0=eol
				
				color=Highlighter.COLOR_COMMENT
				
			Else If chr=34
			
				While i0<eol And text[i0]<>34
					i0+=1
				Wend
				If i0<eol
					i0+=1
				Else
					blkstr=True
				Endif
				
				color=Highlighter.COLOR_STRING
				
			Else If IsAlpha( chr ) Or chr=95
	
				While i0<eol And (IsAlpha( text[i0] ) Or IsDigit( text[i0] )  Or text[i0]=95)
					i0+=1
				Wend
				
				Local id:=text.Slice( start,i0 )
				
				If preproc And istart=sol
				
					Select id.ToLower()
					Case "rem"
						cnest+=1
					Case "end"
						cnest=Max( cnest-1,-1 )
					End
					
					icolor=Highlighter.COLOR_COMMENT
					
					Exit
				Else
				
					color=Highlighter.COLOR_IDENT
					
					If _keywords.Contains( id ) Then color=Highlighter.COLOR_KEYWORD
				
				Endif
				
			Else If IsDigit( chr )
			
				While i0<eol And IsDigit( text[i0] )
					i0+=1
				Wend
				
				color=Highlighter.COLOR_NUMBER
				
			Else If chr=36 And i0<eol And IsHexDigit( text[i0] )
			
				i0+=1
				While i0<eol And IsHexDigit( text[i0] )
					i0+=1
				Wend
				
				color=Highlighter.COLOR_NUMBER
				
			Else
				
				color=Highlighter.COLOR_NONE
				
			Endif
			
			If color=icolor Continue
			
			For Local i:=istart Until start
				colors[i]=icolor
			Next
			
			icolor=color
			istart=start
		
		Wend
		
		For Local i:=istart Until eol
			colors[i]=icolor
		Next
		
		state=cnest & 255
		
		If Not blkstr state|=256
		
		Return state
	End
	
End

