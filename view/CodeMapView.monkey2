
Namespace ted2go

#Rem Каждая вторая новость или запись на тематических форумах, посвященных продукции Apple, каким-то образом затрагивает iPhone 8, хотя до его анонса еще практически целых три месяца. Между тем, как выяснилось сегодня, американская корпорация даже не начала его разработку, а все потому, что весь мир очень сильно ошибался насчет этого флагманского смартфона.
#End
Class CodeMapView Extends CodeTextView
	
	Const WIDTH:=160
	Field scale:Float=0.33
	
	Method New( sourceView:CodeTextView )
	
		Super.New()
	
		Style=GetStyle( "CodeMapView" )
		ContentView.Style=GetStyle( "CodeMapContent" )
		
		_codeView=sourceView
	
		ReadOnly=True
		ScrollBarsVisible=False
	
		Text=_codeView.Text
		_codeView.TextChanged+=Lambda()
	
			Text=_codeView.Text
		End
	
		_selColor=App.Theme.GetColor( "codemap-selection" )
		App.ThemeChanged+=Lambda()
			_selColor=App.Theme.GetColor( "codemap-selection" )
		End
	
		GrabParams()
		_codeView.VisualUpdated+=Lambda()
			GrabParams()
		End
	End
	
	
	Protected
	
	Method OnMeasure:Vec2i() Override
	
		Local size:=Super.OnMeasure()
		Local ww:=WIDTH*App.Theme.Scale.x
		size.X=ww
		Return size
	End
	
	Property OwnerScrollY:Float()
		
		Return _codeView.Scroll.y
	
	Setter( value:Float )
		
		Local sc:=_codeView.Scroll
		sc.Y=Int(value)
		_codeView.Scroll=sc
	End
	
	Method OnContentMouseEvent( event:MouseEvent ) Override
		
		Local posY0:=Float(event.TransformToView(Self).Location.Y+RenderRect.Top)
		Local posY:=Max( Float(0.0),posY0-BubbleHeight*.5 )
		
		Select event.Type
			
			Case EventType.MouseDown
				
				_clickedMouseY=posY
				_clickedScrollY=OwnerScrollY
				
				Local top:=OwnerScrollY*(scale-ScrollKoef)
				Local inside := posY0>=top And posY0<=top+BubbleHeight
				_dragging=inside
				If Not inside Then ScrollTo( posY )
				
			Case EventType.MouseMove
				
				If _dragging
					Local dy:=(posY-_clickedMouseY)
					Local percent:=dy/(VisibleHeight-BubbleHeight)
					Local dy2:=_maxOwnerScroll*percent
					Local yy:=_clickedScrollY+dy2
					OwnerScrollY=yy
				Endif
				
			Case EventType.MouseUp
				
				_dragging=False

				
			Case EventType.MouseWheel
				
				_codeView.OnContentMouseEvent( event )
				_codeView.OnContentMouseEvent( event )
				_codeView.OnContentMouseEvent( event )
				_codeView.OnContentMouseEvent( event ) '4 times faster
			
		End
		
		event.Eat()
	End
	
	Method ScrollTo( posY:Float )
		
		Local scrl:=_codeView.Scroll
		Local percent:=posY/(VisibleHeight-BubbleHeight)
		Local yy:=_maxOwnerScroll*percent
		scrl.Y=yy
		_codeView.Scroll=scrl
		
	End
	
	Method OnMouseEvent( event:MouseEvent ) Override
		
		event.Eat()
	End
	
	Method OnRender( canvas:Canvas ) Override
		
		Super.OnRender( canvas )
		
		' selection overlay
		Local visRect:=_codeView.VisibleRect
		Local ww:=Rect.Width
		Local hh:Float=visRect.Height*scale
		
		Local yy:Float=_codeView.Scroll.y*(scale-ScrollKoef)
		
		Local a:=canvas.Alpha
		canvas.Alpha=_selColor.a
		canvas.Color=_selColor
		canvas.DrawRect( 0,yy,ww,hh )
		canvas.Alpha=a
		
	End
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		Local yy:Float=_codeView.Scroll.y
		
		canvas.PushMatrix()
		
		canvas.Translate( 0,-yy*ScrollKoef )
		canvas.Scale( scale,scale )
		
		Local times:=Int(OwnerContentHeight/VisibleHeight)+1
		Local sc:=_codeView.Scroll
		Local sc2:=New Vec2i
		Local dy:=VisibleHeight+_codeView.LineHeight
		Local whiteSpaces:=_codeView.ShowWhiteSpaces
		_codeView.ShowWhiteSpaces=False
		Local top:=-yy*ScrollKoef
		For Local k:=0 Until times
			
			' check visibility area
			If top+VisibleHeight*scale < 0
				top+=dy*scale
				sc2.Y=sc2.y+dy
				Continue
			Endif
			If top>VisibleHeight
				Exit
			Endif
			top+=dy*scale
			
			_codeView.Scroll=sc2
			_codeView.OnRenderContent( canvas )
			sc2.Y=sc2.y+dy
		Next
		_codeView.Scroll=sc
		_codeView.ShowWhiteSpaces=whiteSpaces
		
		canvas.PopMatrix()
		
	End
	
	Property ScrollKoef:Float()
		
		Local hh:=_codeView.ContentView.Frame.Height
		_maxSelfScroll=Max( Float(0.0),hh*scale-VisibleHeight )
		_maxOwnerScroll=Max( 0,hh-_codeView.Height )
		
		Return _maxOwnerScroll > 0 ? _maxSelfScroll/_maxOwnerScroll Else 1.0
	End
	
	Property OwnerContentHeight:Float()
	
		Return _codeView.ContentView.Frame.Height
	End
	
	Property BubbleHeight:Float()
	
		Return _codeView.VisibleRect.Height*scale
	End
	
	Property VisibleHeight:Float()
	
		Return _codeView.VisibleRect.Height
	End
	
	
	Private
	
	Field _codeView:CodeTextView
	Field _maxOwnerScroll:Float=1.0
	Field _maxSelfScroll:Float=1.0
	Field _selColor:Color
	Field _clickedMouseY:Float
	Field _clickedScrollY:Float
	Field _dragging:=False
	
	Method GrabParams()
		
		Formatter=_codeView.Formatter
		Keywords=_codeView.Keywords
		Highlighter=_codeView.Highlighter
		Document.TextHighlighter=Highlighter.Painter
	End
	
End
