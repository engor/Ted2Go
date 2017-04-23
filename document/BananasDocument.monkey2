
Namespace ted2go


Class BananasDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_list=New ListView
		_view=New ScrollableView
		
		MainWindow.SizeChanged+=Lambda()
			
			ArrangeElements()
		End
	End

	Protected
	
	Method OnLoad:Bool() Override
	
		Parse()
		
		ArrangeElements()
		
		Return True
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _list
	End
	
	Method OnCreateView:View() Override
		
		Return _view
	End
	
	Private
	
	Const _cellWidth:=300
	Const _cellHeight:=200
	Field _list:ListView
	Field _grid:GridView
	Field _view:ScrollableView
	Field _items:=New StringMap<Item>
	Field _cols:Int,_rows:Int
	
	Struct Item
		
		Field title:String
		Field author:String
		Field descr:String
		Field picture:String
		Field source:String
		
	End
	
	
	Method ArrangeElements()
		
		Local cols:=_view.Frame.Size.x/_cellWidth
		If cols=0
			' waiting for layout
			MainWindow.Rendered+=Lambda()
				Print "Rendered"
				ArrangeElements()
			End
			Return
			'cols=1
		Endif
		
		Local rows:=_items.Count()/cols + 1
		
		Print "1: "+cols+","+rows
		
		If _grid And cols=_cols Return
		
		Print "2: "+_cols+","+_rows
		
		_cols=cols
		_rows=rows
		
		If Not _grid
			_grid=New GridView( cols,rows )
			_grid.Style=App.Theme.GetStyle( "BananasView" )
			_grid.Layout="float"
			_view.ContentView=_grid
		Else
			_grid.GridWidth=cols
			_grid.GridHeight=rows
		Endif
		
		'Local dock:=New DockingView
		
		Local r:=0,c:=0,i:=0
		For Local k:=Eachin _items.Keys
			
			Local v:=CreateBananaView( _items[k] )
			r=i/cols
			c=i Mod cols
			i+=1
			_grid.AddView( v,c,r )
			
			'dock.AddView( v,"left" )
		Next
		
		'_view.ContentView=dock
	End
	
	Method Parse()
		
		Local json:=stringio.LoadString( Path )
		
		Local dir:=ExtractDir( Path )
		Local arr:=LoadDir( dir )
		Local files:=New StringStack
		For Local f:=Eachin arr
			If GetFileType( dir+f )<>FileType.Directory Continue
			Local file:=dir+f+"/info.json"
			If GetFileType( file )<>FileType.File Continue
			files.Add( file )
		Next
		
		For Local file:=Eachin files
			
			Local dir:=ExtractDir( file )
			
			Local json:=JsonObject.Load( file )
			Local title:=JsonUtils.FindValue( json,"title" ).ToString()
			Local author:=JsonUtils.FindValue( json,"author" ).ToString()
			Local descr:=JsonUtils.FindValue( json,"description" ).ToString()
			Local picture:=JsonUtils.FindValue( json,"picture" ).ToString()
			Local source:=JsonUtils.FindValue( json,"file" ).ToString()
			
			If Not author Then author="---"
			author="by "+author
			
			picture=dir+picture
			source=dir+source
			
			Local i:=New Item
			i.title=title
			i.author=author
			i.descr=descr
			i.picture=picture
			i.source=source
			
			_items[title]=i
			
			_list.AddItem( title )
		Next
		
	End
	
	Method CreateBananaView:View( item:Item )
		
		Local dock:=New DockingView
		dock.Style=App.Theme.GetStyle( "BananasView" )
		dock.Layout="float"
		
		Local img:=Image.Load( item.picture )
		AdjustImageScale( img,_cellWidth,_cellHeight )
		Local lab:=New Label( "",img )
		dock.AddView( lab,"top" )
		
		Local btn:=New Button( item.title )
		btn.Clicked+=Lambda()
			MainWindow.OpenDocument( item.source,True )
		End
		dock.AddView( btn,"top" )
		dock.AddView( New Label( item.descr ),"top" )
		dock.AddView( New Label( item.author ),"top" )
		
		Return dock
	End
	
	Method AdjustImageScale( img:Image,fitWidth:Float,fitHeight:Float )
		
		If Not img Return
		
		Local iw:=img.Width
		Local ih:=img.Height
		Local kw:=fitWidth/iw
		Local kh:=fitHeight/ih
		Local k:=Max( kw,kh )
		
		img.Scale=App.Theme.Scale*k
	End
	
End


Class BananasDocumentType Extends Ted2DocumentType

	Protected
	
	Method New()
		AddPlugin( Self )
		
		Extensions=New String[]( ".bananas" )
	End
	
	Method OnCreateDocument:Ted2Document( path:String ) Override
	
		Return New BananasDocument( path )
	End
	
	Private
	
	Global _instance:=New BananasDocumentType
	
End
