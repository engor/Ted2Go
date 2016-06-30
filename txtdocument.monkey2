
Namespace ted2

Class TxtTextView Extends TextView

	Method New( doc:TxtDocument )

		_doc=doc
		
		Document=_doc.TextDocument
		
		GutterWidth=64
		CursorColor=New Color( 0,.5,1 )
		SelectionColor=New Color( .4,.4,.4 )
	End
	
	Protected
	
	Method OnRender( canvas:Canvas ) Override
	
		Super.OnRender( canvas )

		'OK, VERY ugly! Draw gutter...
		
		Local clip:Recti
		clip.min.x=-Frame.min.x
		clip.min.y=-Frame.min.y
		clip.max.x=clip.min.x+GutterWidth
		clip.max.y=clip.min.y+ClipRect.Height
		
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
	
	Field _doc:TxtDocument
	
End

Class TxtDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )

		_textDoc=New TextDocument
		
		_textDoc.TextChanged=Lambda()
			Dirty=True
		End
		
		_textView=New TxtTextView( Self )
	End
	
	Property TextDocument:TextDocument()
	
		Return _textDoc
	End
	
	Protected
	
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
	
	Private
	
	Field _textDoc:TextDocument
	Field _textView:TxtTextView
	
End

