
Namespace mojox

#Import "assets/checkmark_icons.png@/mojox"
#Import "assets/treenode_expanded.png@/mojox"
#Import "assets/treenode_collapsed.png@/mojox"

Const Theme:=New ThemeInstance

Class ThemeInstance

	Property Name:String()
		Return _name
	End

	Property ClearColor:Color()
		Return _clearColor
	End
	
	Method Load()
	
		_name="dark"
		_fontSize=16
		_monoFontSize=16
		
		Local obj:=JsonObject.Load( "bin/ted2.config.json" )
		If obj
			If obj.Contains( "theme" )
				_name=obj["theme"].ToString()
			Endif
			If obj.Contains( "fontSize" )
				_fontSize=obj["fontSize"].ToNumber()
			Endif
			If obj.Contains( "monoFontSize" )
				_monoFontSize=obj["monoFontSize"].ToNumber()
			Endif
		Endif

		Select _name
		Case "light"
		
			_textColor=New Color( 0,0,0 )
			_disabledColor=New Color( .5,.5,.5 )
			_clearColor=New Color( .8,.8,.8 )
			_contentColor=New Color( .95,.95,.95 )
			_panelColor=New Color( .9,.9,.9 )
			_gutterColor=New Color( .8,.8,.8 )
			_borderColor=New Color( .7,.7,.7 )
			_lineColor=New Color( .95,.95,.95 )
			_knobColor=New Color( .7,.7,.7 )
			_hoverColor=New Color( .6,.6,.6 )
			_activeColor=New Color( .5,.5,.5 )

		Default
				
			_textColor=New Color( 1,1,1 )
			_disabledColor=New Color( .5,.5,.5 )
			_clearColor=New Color( .1,.1,.1 )
			_contentColor=New Color( .2,.2,.2 )
			_panelColor=New Color( .25,.25,.25 )
			_gutterColor=New Color( .1,.1,.1 )
			_borderColor=New Color( .1,.1,.1 )
			_lineColor=New Color( .2,.2,.2 )
			_knobColor=New Color( .4,.4,.4 )
			_hoverColor=New Color( .6,.6,.6 )
			_activeColor=New Color( .7,.7,.7 )'1,1,1 )
			
		End
		
		_defaultFont=Font.Open( App.DefaultFontName,_fontSize )
		_defaultMonoFont=Font.Open( App.DefaultMonoFontName,_monoFontSize )

		Local style:Style,state:Style
		
		style=Style.GetStyle( "" )
		style.DefaultColor=_textColor
		style.DefaultFont=_defaultFont

		'Label		
		style=New Style( "mojo.Label" )
		style.DefaultColor=_textColor
		style.Padding=New Recti( -8,-4,8,4 )
		
		'Button
		style=New Style( "mojo.Button",Style.GetStyle( "mojo.Label" ) )
		
		Local icons:=LoadIcons( "asset::mojox/checkmark_icons.png",16 )
		style.SetImage( "checkmark:unchecked",icons[0] )
		style.SetImage( "checkmark:checked",icons[1] )
		
		state=style.AddState( "disabled" )
		state.DefaultColor=_disabledColor
		
		state=style.AddState( "hover" )
		state.BackgroundColor=_hoverColor
		
		state=style.AddState( "active" )
		state.BackgroundColor=_activeColor
		
		'Menu
		style=New Style( "mojo.Menu" )
		style.Padding=New Recti( -2,-2,2,2 )
		style.Border=New Recti( -1,-1,1,1 )
		style.BackgroundColor=_panelColor
		style.BorderColor=_borderColor
		
		'MenuButton
		style=New Style( "mojo.MenuButton",Style.GetStyle( "mojo.Button" ) )
		
		'MenuBar
		style=New Style( "mojo.MenuBar" )
		style.Padding=New Recti( -2,-2,2,2 )
		style.BackgroundColor=_panelColor
		
		'DockingView
		style=New Style( "mojo.DockingView" )
		
		'DockView
		style=New Style( "mojo.DockView" )
		
		'DragKnob
		style=New Style( "mojo.DragKnob" )
		style.Padding=New Recti( -3,-3,3,3 )
		style.BackgroundColor=_knobColor
		
		state=style.AddState( "hover" )
		state.BackgroundColor=_hoverColor
		
		state=style.AddState( "active" )
		state.BackgroundColor=_activeColor
		
		'ScrollView
		style=New Style( "mojo.ScrollView" )
	
		'ScrollBar
		style=New Style( "mojo.ScrollBar" )
		style.BackgroundColor=_gutterColor
		
		'ScrollKnob
		style=New Style( "mojo.ScrollKnob" )
		style.Padding=New Recti( -6,-6,6,6 )
		style.Border=New Recti( -1,-1,1,1 )
		style.BackgroundColor=_knobColor
		
		state=style.AddState( "hover" )
		state.BackgroundColor=_hoverColor
		
		state=style.AddState( "active" )
		state.BackgroundColor=_activeColor
		
		'TabView
		style=New Style( "mojo.TabView" )
		
		'TabButton
		style=New Style( "mojo.TabButton",Style.GetStyle( "mojo.Button" ) )
		style.Border=New Recti( 0,-2,2,0 )
		
		state=style.AddState( "selected" )
		state.BackgroundColor=_contentColor
		
		state=style.AddState( "hover" )
		state.BackgroundColor=_hoverColor
		
		state=style.AddState( "active" )
		state.BackgroundColor=_activeColor
		
		'HtmlView
		style=New Style( "mojo.HtmlView" )

		'TreeView
		style=New Style( "mojo.TreeView" )
		style.SetImage( "node:expanded",Image.Load( "asset::mojox/treenode_expanded.png" ) )
		style.SetImage( "node:collapsed",Image.Load( "asset::mojox/treenode_collapsed.png" ) )
		style.BackgroundColor=_contentColor
		style.DefaultColor=_textColor
		
		'FileBrowser
		style=New Style( "mojo.FileBrowser",Style.GetStyle( "mojo.TreeView" ) )
		
		'TextView
		style=New Style( "mojo.TextView" )
		style.DefaultFont=_defaultMonoFont
		style.Padding=New Recti( -4,-4,4,4 )
		style.BackgroundColor=_contentColor
		style.DefaultColor=_textColor
		
		'Dialog
		style=New Style( "mojo.Dialog" )
		style.Border=New Recti( -1,-1,1,1 )
		style.BackgroundColor=_panelColor
		style.BorderColor=_borderColor
		
		'DialogTitle
		style=New Style( "mojo.DialogTitle",Style.GetStyle( "mojo.Label" ) )
		style.BackgroundColor=_knobColor
		
		style=New Style( "mojo.DialogContent" )
		style.Padding=New Recti( -8,-8,8,4 )
		
		style=New Style( "mojo.DialogActions" )
		style.Padding=New Recti( -8,-4,8,4 )
		
		'ToolBar
		style=New Style( "mojo.ToolBar",Style.GetStyle( "mojo.MenuBar" ) )
		
		style=New Style( "mojo.ToolButton",Style.GetStyle( "mojo.Button" ) )
		
		'Separator
		style=New Style( "mojo.Separator" )
		style.Padding=New Recti( 0,0,1,1 )
		style.Border=New Recti( -8,-8,7,7 )
		style.BackgroundColor=_lineColor
		
		'TextField
		style=New Style( "mojo.TextField",Style.GetStyle( "mojo.TextView" ) )
		style.Padding=New Recti( -2,-2,2,2 )
		style.Margin=New Recti( -2,-2,2,2 )
		
	End
	
	Method LoadIcons:Image[]( path:String,size:Int )
	
		Local pixmap:=Pixmap.Load( path )
		If Not pixmap Return Null
		
		Local n:=pixmap.Width/size
		
		Local icons:=New Image[n]
		
		For Local i:=0 Until n
			icons[i]=New Image( pixmap.Window( i*size,0,size,pixmap.Height ) )
		Next
		
		Return icons
	End

	Private
	
	Field _name:String
	Field _fontSize:Int
	Field _monoFontSize:Int
	
	Field _textColor:Color
	Field _defaultFont:Font
	Field _defaultMonoFont:Font
	
	Field _disabledColor:Color
	Field _clearColor:Color
	Field _contentColor:Color
	Field _panelColor:Color
	Field _gutterColor:Color
	Field _borderColor:Color
	Field _lineColor:Color
	Field _knobColor:Color
	Field _hoverColor:Color
	Field _activeColor:Color
	
End