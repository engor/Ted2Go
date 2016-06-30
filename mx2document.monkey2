
Namespace ted2

Global Mx2Keywords:=New StringMap<String>

Private

Function InitKeywords()
	Local kws:=""

	kws+="Namespace;Using;Import;Extern;"
	kws+="Public;Private;Protected;Friend;"
	kws+="Void;Bool;Byte;UByte;Short;UShort;Int;UInt;Long;ULong;Float;Double;String;Object;Continue;Exit;"
	kws+="New;Self;Super;Eachin;True;False;Null;Where;"
	kws+="Alias;Const;Local;Global;Field;Method;Function;Property;Getter;Setter;Operator;Lambda;"
	kws+="Enum;Class;Interface;Struct;Extends;Implements;Virtual;Override;Abstract;Final;Inline;"
	kws+="Var;Varptr;Ptr;"
	kws+="Not;Mod;And;Or;Shl;Shr;End;"
	kws+="If;Then;Else;Elseif;Endif;"
	kws+="While;Wend;"
	kws+="Repeat;Until;Forever;"
	kws+="For;To;Step;Next;"
	kws+="Select;Case;Default;"
	kws+="Try;Catch;Throw;Throwable;"
	kws+="Return;Print;Static;Cast"
	
	For Local kw:=Eachin kws.Split( ";" )
		Mx2Keywords[kw.ToLower()]=kw
	Next
End

Public

Class Mx2Error

	Field path:String
	Field line:Int
	Field msg:String
	Field removed:Bool
	
	Method New( path:String,line:Int,msg:String )
		Self.path=path
		Self.line=line
		Self.msg=msg
	End

	Operator<=>:Int( err:Mx2Error )
		If line<err.line Return -1
		If line>err.line Return 1
		Return 0
	End
	
End

Class Mx2TextView Extends TextView

	Method New( mx2Doc:Mx2Document )
		
		_mx2Doc=mx2Doc
		
		Document=_mx2Doc.TextDocument
		
		GutterWidth=64
		
		Local _editorColors:=New Color[8]
		
		Select Theme.Name
		Case "light"
			_editorColors[COLOR_IDENT]=New Color( .1,.1,.1 )
			_editorColors[COLOR_KEYWORD]=New Color( 0,0,1 )
			_editorColors[COLOR_STRING]=New Color( 0,.5,0 )
			_editorColors[COLOR_NUMBER]=New Color( 0,0,.5 )
			_editorColors[COLOR_COMMENT]=New Color( 0,.5,.5 )
			_editorColors[COLOR_PREPROC]=New Color( .8,.65,0 )
			_editorColors[COLOR_OTHER]=New Color( .1,.1,.1 )
		Default
			_editorColors[COLOR_IDENT]=New Color( 1,1,1 )
			_editorColors[COLOR_KEYWORD]=New Color( 1,1,0 )
			_editorColors[COLOR_STRING]=New Color( 0,1,.5 )
			_editorColors[COLOR_NUMBER]=New Color( 0,1,.5 )
			_editorColors[COLOR_COMMENT]=New Color( 0,1,1 )
			_editorColors[COLOR_PREPROC]=New Color( 1,.75,0 )
			_editorColors[COLOR_OTHER]=New Color( 1,1,1 )
		End
		
		TextColors=_editorColors
		CursorColor=New Color( 0,.5,1 )
		SelectionColor=New Color( .4,.4,.4 )
	End
	
	Protected
	
	Method OnValidateStyle() Override
	
		Super.OnValidateStyle()
		
'		GutterWidth=RenderStyle.DefaultFont.TextWidth( "999999 " )
	End
	
	Method OnRender( canvas:Canvas ) Override
	
		Local color:=canvas.Color
	
		Local clip:Recti
		clip.min.x=-Frame.min.x
		clip.min.y=-Frame.min.y
		clip.max.x=clip.min.x+GutterWidth
		clip.max.y=clip.min.y+ClipRect.Height
		
		If _mx2Doc._errors.Length
		
			canvas.Color=New Color( .5,0,0 )
			
			For Local err:=Eachin _mx2Doc._errors
				canvas.DrawRect( 0,err.line*LineHeight,Width,LineHeight )
			Next
			
		Endif
		
		If _mx2Doc._debugLine<>-1

			Local line:=_mx2Doc._debugLine
			If line<0 Or line>=Document.LineCount Return
			
			canvas.Color=New Color( .5,.5,0 )
			canvas.DrawRect( 0,line*LineHeight,Width,LineHeight )
			
		Endif
		
		canvas.Color=color
		
		Super.OnRender( canvas )
		
		'OK, VERY ugly! Draw gutter stuff...
		
		Local viewport:=clip
		viewport.min+=RenderStyle.Bounds.min
		canvas.Viewport=viewport
		canvas.Color=RenderStyle.BackgroundColor
		canvas.DrawRect( 0,0,viewport.Width,viewport.Height )
		
		canvas.Viewport=Rect
		
		Local line0:=clip.Top/LineHeight
		Local line1:=(clip.Bottom-1)/LineHeight+1
		
		canvas.Color=Color.Grey

		For Local i:=line0 Until line1
			canvas.DrawText( String( i+1 ),clip.X+GutterWidth-8,i*LineHeight,1,0 )
		Next
		
	End
	
	Private
	
	Field _mx2Doc:Mx2Document
	
	Method Capitalize( typing:Bool )
	
		Local cursor:=Cursor
		
		Local state:=Document.LineState( Document.FindLine( cursor ) )
		If state<>-1 Return
		
		Local text:=Text
		Local start:=cursor
		While start And IsIdent( text[start-1] )
			start-=1
		Wend
		While start<text.Length And IsDigit( text[start] )
			start+=1
		Wend
		
		If start<text.Length 
			Local color:=Document.Colors[start]
			If color<>COLOR_KEYWORD Return'color<>COLOR_IDENT Return
		Endif
		
		Local ident:=text.Slice( start,cursor )
		If Not ident Return
		
		Local kw:=Mx2Keywords[ident.ToLower()]
		If kw And kw<>ident Document.ReplaceText( Cursor-ident.Length,Cursor,kw )
		
	End
	
	Method OnKeyEvent( event:KeyEvent ) Override
	
		Select event.Type
		Case EventType.KeyDown
		
			Select event.Key
			Case Key.Tab,Key.Enter
				Capitalize( True )
			Case Key.Up,Key.Down
				Capitalize( False )
			End
		
		Case EventType.KeyChar
		
			If Not IsIdent( event.Text[0] )
				Capitalize( True )
			Endif
		End

		Super.OnKeyEvent( event )

	End

End

Class Mx2Document Extends Ted2Document

	Method New( path:String )
		Super.New( path )
	
		InitKeywords()
		
		_textDoc=New TextDocument
		
		_textDoc.TextChanged=Lambda()
			Dirty=True
		End
		
		_textDoc.TextHighlighter=Mx2TextHighlighter
		
		_textDoc.LinesModified=Lambda( first:Int,removed:Int,inserted:Int )
			Local put:=0
			For Local get:=0 Until _errors.Length
				Local err:=_errors[get]
				If err.line>=first
					If err.line<first+removed 
						err.removed=True
						Continue
					Endif
					err.line+=(inserted-removed)
				Endif
				_errors[put]=err
				put+=1
			Next
			_errors.Resize( put )
		End

	
		_textView=New Mx2TextView( Self )
		
	End
	
	Property TextDocument:TextDocument()
	
		Return _textDoc
	End
	
	Property DebugLine:Int()
	
		Return _debugLine
	
	Setter( debugLine:Int )
		If debugLine=_debugLine Return
		
		_debugLine=debugLine
		If _debugLine=-1 Return

		Local scroller:=Cast<ScrollView>( _textView.Container )
		If Not scroller Return
		
		Local h:=_textView.LineHeight
		Local y:=_debugLine*h
		
		scroller.EnsureVisible( New Recti( 0,y,1,y+scroller.ContentClipRect.Height/3 ) )
	End
	
	Property Errors:Stack<Mx2Error>()
	
		Return _errors
	End
	
	Private

	Field _textDoc:TextDocument
	Field _errors:=New Stack<Mx2Error>
	Field _debugLine:Int=-1

	Field _textView:TextView
	
	Method OnLoad:Bool() Override
	
		Local text:=stringio.LoadString( Path )
		
		_textDoc.Text=text
		
		Return True
	End
	
	Method OnSave:Bool() Override
	
		Local text:=_textDoc.Text
		
		Return stringio.SaveString( text,Path )
	
	End
	
	Method OnCreateView:View() Override
	
		Return _textView
	End
	
End

