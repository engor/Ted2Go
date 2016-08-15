
Namespace mojox

#rem monkeydoc The HtmlView class.
#end
Class HtmlView Extends ScrollableView

	#rem monkeydoc Invoked when an anchor is clicked.
	#end
	Field AnchorClicked:Void( url:String )

	#rem monkeydoc Creates a new HtmlView.
	#end
	Method New()
		Layout="fill"
		
		Style=GetStyle( "HtmlView" )
		
		_context=New litehtml.context
		_context.load_master_stylesheet( stringio.LoadString( "theme::htmlview_master_css.css" ) )

		_container=New document_container( Self )
		
		_baseUrl=filesystem.CurrentDir()
		
		AnchorClicked=Go
	End
	
	#rem monkeydoc Base URL.
	
	This is used as the root directory for relative anchors in the page.
	
	#end
	Property BaseUrl:String()
		Return _baseUrl
	Setter( baseUrl:String )
		If Not baseUrl.EndsWith( "/" ) baseUrl+="/"
		_baseUrl=baseUrl
	End
	
	#rem monkeydoc HTML source.
	#end
	Property HtmlSource:String()
		Return _source
	Setter( htmlSource:String )
		_source=htmlSource
		_document=New litehtml.document( _source,_container,_context )
		_layoutSize=New Vec2i( 0,0 )
		_renderSize=New Vec2i( 0,0 )
		RequestRender()
	End
	
	#rem monkeydoc Goto a url.
	#end
	Method Go( url:String )
	
		If url.Contains( "#" )
			Return
		Endif
		
		Local root:=ExtractRootDir( url )
		
		If root="http://" Or root="https://"
			requesters.OpenUrl( url )
			Return
		Endif
		
		If Not root
			url=BaseUrl+url
		Endif
		
		Local src:=stringio.LoadString( url )
		
		If ExtractExt( url )=".md"
			src=hoedown.MarkdownToHtml( src )
			Local wrapper:=stringio.LoadString( "theme::markdown_wrapper.html" )
			src=wrapper.Replace( "${CONTENT}",src )
		End
		
		BaseUrl=ExtractDir( url )
		
		HtmlSource=src
	End
	
	Private
	
	Field _context:litehtml.context
	Field _container:litehtml.document_container
	Field _anchorClicked:String
	
	Field _baseUrl:String
	Field _source:String
	Field _document:litehtml.document
	Field _layoutSize:Vec2i
	Field _renderSize:Vec2i

	Method OnMeasureContent2:Vec2i( size:Vec2i ) Override
	
		If Not _document Return New Vec2i( 0,0 )
		
		If size.x=_layoutSize.x Return _renderSize
		
		_layoutSize=size
		
		_document.render( size.x )
		
		_renderSize=New Vec2i( _document.width(),_document.height() )
		
		Return _renderSize
	End
	
	Method OnRenderContent( canvas:Canvas ) Override
	
		If Not _document Return
		
		Local clip:litehtml.position
		
		clip.x=canvas.Scissor.X
		clip.y=canvas.Scissor.Y
		clip.width=canvas.Scissor.Width
		clip.height=canvas.Scissor.Height

		_document.draw( canvas,0,0,Varptr clip )
	End

	Method OnContentMouseEvent( event:MouseEvent ) Override
	
		If Not _document Return
	
		Local x:=event.Location.X
		Local y:=event.Location.Y
		
		_anchorClicked=""
		
		Select event.Type
		Case EventType.MouseDown
		
			_document.on_lbutton_down( x,y,x,y )
			
		Case EventType.MouseMove
		
			_document.on_mouse_over( x,y,x,y )
			
		Case EventType.MouseUp
		
			_document.on_lbutton_up( x,y,x,y )
			
			_document.on_mouse_leave()
			
		Case EventType.MouseWheel

			Return
		End
		
		event.Eat()
		
		RequestRender()	'Not ideal, but necessary for link highlighting...
		
		If _anchorClicked AnchorClicked( _anchorClicked )
	End
	
End

Class document_container Extends litehtml.document_container

	Field _view:HtmlView
	
	Global _fontScale:=1
	Global _imageCache:=New StringMap<Image>
	
	Method New( view:HtmlView )
	
		_view=view
	End
	
	Method set_color( canvas:Canvas,color:litehtml.web_color )
	
		canvas.Color=New Color( color.red/255.0,color.green/255.0,color.blue/255.0,1 )
	End
	
	Method make_url:String( href:String )
		Return _view._baseUrl+href
	End

	Method create_font:Object( faceName:String,size:Int,weight:Int,style:litehtml.font_style,decoration:UInt,fm:litehtml.font_metrics Ptr ) Override
	
		Local font:Font
		
		If faceName.Contains( "monospace" )
			font=Font.Open( "font::DejaVuSansMono.ttf",size )
		Else
			font=Font.Open( "font::DejaVuSans.ttf",size )
		Endif
		
		Local height:=size

		fm[0].height=height
		fm[0].ascent=height
		fm[0].descent=0
		fm[0].x_height=height
		fm[0].draw_spaces=True
		
		Return font
	End

	Method delete_font( font:Object ) Override
	End
	
	Method text_width:Int( text:String,hfont:Object ) Override
	
		Local font:=Cast<Font>( hfont )
		
		Return font.TextWidth( text ) * _fontScale
	End
	
	Method draw_text( hdc:Object,text:String,hfont:Object,color:litehtml.web_color Ptr,pos:litehtml.position Ptr ) Override
	
		Local canvas:=Cast<Canvas>( hdc )
		
		Local font:=Cast<Font>( hfont )
		
		canvas.Font=font

		set_color( canvas,color[0] )
		
		canvas.DrawText( text,pos[0].x,pos[0].y )
		
		Return
#rem		
		canvas.PushMatrix()
		canvas.Translate( pos[0].x,pos[0].y )
		canvas.Scale( _fontScale,1 )
		canvas.DrawText( text,0,0 )
		canvas.PopMatrix()
#end
	End
	
	Method pt_to_px:Int( pt:Int ) Override
		Return 0
	End
	
	Method get_default_font_size:Int() Override
		Return 16
	End
	
	Method get_default_font_name:String() Override
		Return "mojo"
	End
	
	Method draw_list_marker( hdc:Object,marker:litehtml.list_marker Ptr ) Override
	
		If marker[0].marker_type=litehtml.list_style_type_none Return
	
		Local canvas:=Cast<Canvas>( hdc )
	
		set_color( canvas,marker[0].color )
		
		Select marker[0].marker_type
		Case litehtml.list_style_type_disc
			canvas.DrawOval( marker[0].pos.x,marker[0].pos.y,marker[0].pos.width,marker[0].pos.height )
		Default
			canvas.DrawRect( marker[0].pos.x,marker[0].pos.y,marker[0].pos.width,marker[0].pos.height )
		End
	End
	
	Method load_image( src:String,baseurl:String,redraw_on_ready:Bool ) Override
		If _imageCache.Contains( src ) Return
		Local image:=Image.Load( make_url( src ) )
		_imageCache.Set( src,image )
	End
	
	Method get_image_size( src:String,baseurl:String,sz:litehtml.size Ptr ) Override
		Local image:=_imageCache.Get( src )
		If Not image Return
		sz[0].width=image.Width
		sz[0].height=image.Height
	End

	Method draw_background( hdc:Object,img_src:String,img_baseurl:String,bg:litehtml.background_paint Ptr ) Override
	
		Local canvas:=Cast<Canvas>( hdc )
		
		Local image:=_imageCache.Get( img_src )
		If image
			canvas.Color=Color.White
			canvas.DrawImage( image,bg[0].position_x,bg[0].position_y )
			Return
		Endif

		set_color( canvas,bg[0].color )
		
'		canvas.DrawRect( bg[0].clip_box.x,bg[0].clip_box.y,bg[0].clip_box.width,bg[0].clip_box.height )
		canvas.DrawRect( bg[0].border_box.x,bg[0].border_box.y,bg[0].border_box.width,bg[0].border_box.height )

	End
	
	Method draw_border( canvas:Canvas,border:litehtml.border,x:Int,y:Int,w:Int,h:Int )

		If border.style<>litehtml.border_style_solid Or border.width<1 Return
		
		set_color( canvas,border.color )
		
		canvas.DrawRect( x,y,w,h )
	End
	
	Method draw_borders( hdc:Object,borders:litehtml.borders Ptr,pos:litehtml.position Ptr,root:Bool ) Override
	
		Local canvas:=Cast<Canvas>( hdc )
		
		Local x:=pos[0].x,y:=pos[0].y
		
		Local w:=pos[0].width,h:=pos[0].height
		
		draw_border( canvas,borders[0].left,x,y,1,h )
		
		draw_border( canvas,borders[0].top,x,y,w,1 )
		
		draw_border( canvas,borders[0].right,x+w-1,y,1,h )
		
		draw_border( canvas,borders[0].bottom,x,y+h-1,w,1 )
	End

	Method set_caption( caption:String ) Override
	End
	
	Method set_base_url( baseurl:String ) Override
	End
	
	Method on_anchor_click( url:String ) Override
		_view._anchorClicked=url
	End
		
	Method set_cursor( cursor:String ) Override
	End
	
	Method import_css:String( url:String,baseurl:String ) Override
		Local css:=stringio.LoadString( make_url( url ) )
		Return css
	End
	
	Method set_clip( pos:litehtml.position Ptr,radiuses:litehtml.border_radiuses Ptr ) Override
	End
	
	Method del_clip() Override
	End
	
	Method get_client_rect( client:litehtml.position Ptr ) Override
'		If _view._rendering Print "get client rect"
		client[0].x=0
		client[0].y=0
		client[0].width=_view._layoutSize.x
		client[0].height=_view._layoutSize.y
	End
	
	Method get_media_features( media:litehtml.media_features Ptr ) Override
'		If _view._rendering Print "get media features"
		media[0].type=litehtml.media_type_screen
		media[0].width=_view._layoutSize.x
		media[0].height=_view._layoutSize.y
		media[0].device_width=1920
		media[0].device_height=1080
		media[0].color=8
		media[0].color_index=0
		media[0].monochrome=0
		media[0].resolution=96
	End
	
	Method get_language:String() Override
		Return ""
	End
	
	Method get_culture:String() Override
		Return ""
	End
	
End
