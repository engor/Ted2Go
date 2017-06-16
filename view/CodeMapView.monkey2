
Namespace ted2go


Class CodeMapView Extends CodeTextView
	Field _owner:CodeDocument
	Field _scale:Float=0.15
	Field _size:Vec2i
	Field _dragging:Bool
	Field _dragOffset:Float
	Field _smoothScroll:Int=-1
	Field _smoothScrollSpeed:Float=0.15
	Field _maxOwnerScroll:Int
	Field _maxSelfScroll:Int
	Field _areaSmoothPos:Float
	Field _areaSmoothSpeed:Float=0.2
	
	Field _lastTime:Double
	Field _delta:Double
	
	Method New( owner:CodeDocument )
		Super.New()
		
		_owner=owner
		
		ReadOnly=True
		ScrollBarsVisible=False
	End
	
	Method OnMeasure:Vec2i() Override
		_size=New Vec2i(_owner.CodeView.Width*_scale, _owner.CodeView.Height/_scale )
		_maxOwnerScroll=_owner.CodeView.ContentView.Frame.Height-_owner.CodeView.Height
		_maxSelfScroll=ContentView.Frame.Height-_size.Y
		Return _size
	End

	Method OnContentMouseEvent( event:MouseEvent ) Override
		Local visRect:=_owner.CodeView.VisibleRect
		
		Local sHeight:Float=Min(_owner.CodeView.ContentView.Height, Self.Height)
		sHeight-=_owner.CodeView.Height
		sHeight*=_scale
		
		Local posY:Float=Float(event.TransformToView(Self).Location.Y+RenderBounds.Top)/sHeight
		
		Select event.Type
			Case EventType.MouseDown
				'Did we click inside the visible area?
				If event.Location.Y>=visRect.Top*_scale And event.Location.Y<=visRect.Bottom*_scale
					'Begin dragging area
					_dragging=True
					_smoothScroll=-1
					_dragOffset=posY
				Else
					'Scroll to clicked area
					_dragging=False
					_smoothScroll=Max((event.Location.Y/_scale)-visRect.Height*0.5,0.0)
				Endif
				
			Case EventType.MouseUp
				_dragging=False
				
			Case EventType.MouseWheel
				_owner.TextView.OnContentMouseEvent( event )
				
			Case EventType.MouseMove
				If _dragging And posY<>_dragOffset
					_owner.CodeView.Scroll=New Vec2i(0, _owner.CodeView.Scroll.Y+_maxOwnerScroll*(posY-_dragOffset))
					_dragOffset=posY
				Endif
		End
		
		event.Eat()
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
		event.Eat()
	End
	
	Method OnRenderContent( canvas:Canvas ) Override
		'Basic delta timing
		Local now:Double=Now()
		_delta=(now-_lastTime)*100.0
		_lastTime=now
		
		'Do smooth scrolling
		If _smoothScroll>=0 Then
			'Always move one pixel
			_owner.CodeView.Scroll=New Vec2i(0,_owner.CodeView.Scroll.Y+Sgn(_smoothScroll-_owner.CodeView.Scroll.Y))
			'Smooth movement
			_owner.CodeView.Scroll=New Vec2i(0,_owner.CodeView.Scroll.Y+(_smoothScroll-_owner.CodeView.Scroll.Y)*(_smoothScrollSpeed*_delta))
			
			'At target
			If _owner.CodeView.Scroll.Y=_smoothScroll Then _smoothScroll=-1
		Endif
		
		'Update our size
		OnMeasure()
		
		'Update stuff from owner
		Text=_owner.TextView.Text
		Formatter=_owner.CodeView.Formatter
		Keywords=_owner.CodeView.Keywords
		Highlighter=_owner.CodeView.Highlighter
		Document.TextHighlighter=_owner.CodeView.Highlighter.Painter
		ShowWhiteSpaces=_owner.CodeView.ShowWhiteSpaces
		WordWrap=_owner.CodeView.WordWrap
		
		Scroll=New Vec2i(0,(Float(_owner.CodeView.Scroll.Y)/Float(_maxOwnerScroll))*_maxSelfScroll)
		ContentView.Offset=New Vec2i(0,-ContentView.Style.Padding.Height+(-Scroll.y*_scale))
		
		Local areaSmoothPosDist:Float=_owner.TextView.VisibleRect.Top-_areaSmoothPos
		If Not _dragging Then
			_areaSmoothPos+=areaSmoothPosDist*(_areaSmoothSpeed*_delta)
		Else
			_areaSmoothPos+=areaSmoothPosDist*((_areaSmoothSpeed*2.0)*_delta)
		Endif
		
		'Render
		canvas.PushMatrix()
		canvas.Scale(_scale,_scale)
		
		canvas.Alpha=0.5
		canvas.Color=App.Theme.GetColor( "textview-selection" )
		canvas.DrawRect(0, _areaSmoothPos, Width/_scale, _owner.TextView.VisibleRect.Height)
		canvas.Alpha=1
		
		Super.OnRenderContent( canvas )
		
		canvas.PopMatrix()
	End
	
	Method OnRenderLine( canvas:Canvas,line:Int ) Override
		Super.OnRenderLine( canvas,line )
	End
End
