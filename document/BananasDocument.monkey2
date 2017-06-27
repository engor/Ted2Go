
Namespace ted2go


Class BananasDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		_list=New ListView
		_view=New ScrollableView
		
		_table=New TableView( 3,1 )
		_table.Style=App.Theme.GetStyle( "BananasView" )
		_table.Layout="float"
		_view.ContentView=_table
	End


	Protected
	
	Method OnLoad:Bool() Override
	
		Parse()
		CreateFilterPanel()
		ShowElements()
		
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
	Field _table:TableView
	Field _view:ScrollableView
	Field _items:=New Stack<Item>
	Field _views:=New Stack<View>
	Field _cols:Int,_rows:Int
	Field _tags:=New StringStack
	Field _filteredTags:=New StringStack
	
	
	Struct Item
		
		Field title:String
		Field author:String
		Field descr:String
		Field previewPath:String
		Field sourcePath:String
		Field homepage:String
		Field modified:String
		Field version:String
		Field tags:String
		
	End
	
	
	Method CreateFilterPanel()
		
		_tags.Sort()
		
		Local panel:=New DockingView
		For Local tag:=Eachin _tags
			Local action:=New Action( tag )
			Local button:=New PushButton( action )
			action.Triggered+=Lambda()
				Local contains:=_filteredTags.Contains( tag )
				If contains Then _filteredTags.Remove( tag ) Else _filteredTags.Add( tag )
				ShowElements()
			End
			panel.AddView( button,"left" )
		Next
		_view.AddView( panel,"bottom" )
	End
	
	Method OnFilterChanged()
		
		ShowElements()
	End
	
	Method ShowElements()
		
		_table.RemoveAllViews()
		
		Local count:=GetVisibleCount()
		
		Local cols:=_table.Columns
		Local rows:=count/cols + 1
		
		_table.Rows=rows
		
		Local r:=0,c:=0,i:=0
		For Local k:=0 Until _items.Length
			
			If Not IsItemVisible( _items[k] ) Continue
			r=i/cols
			c=i Mod cols
			i+=1
			_table[c,r]=_views[k]
			
		Next
		
	End
	
	Method GetVisibleCount:Int()
		
		Local count:=0
		For Local i:=Eachin _items
			If IsItemVisible( i ) Then count+=1
		Next
		Return count
	End
	
	Method IsItemVisible:Bool( item:Item )
		
		For Local tag:=Eachin _filteredTags
			if item.tags.Contains( tag ) Return True
		Next
		Return False
	End
	
	Method Parse()
		
		'Local json:=stringio.LoadString( Path )
		
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
		
		'Local json:=JsonObject.Load( Path )
		'Local arr:=json.GetArray( "bananas" )
		
		'For Local i:=Eachin arr
			'Print "parse: "+file
			Try 
				Local folder:=ExtractDir( file )
				
				Local jsonData:=JsonObject.Load( file ).Data
				'Local jsonData:=i.ToObject()
				
				Local title:=Json_GetString( jsonData,"title","" )
				Local author:=Json_GetString( jsonData,"author","(unknown)" )
				Local descr:=Json_GetString( jsonData,"description","" )
				Local preview:=Json_GetString( jsonData,"preview","" )
				Local source:=Json_GetString( jsonData,"mainFile","" )
				Local homepage:=Json_GetString( jsonData,"homepage","" )
				Local modified:=Json_GetString( jsonData,"modified","" )
				Local version:=Json_GetString( jsonData,"version","" )
				Local tags:=ProcessTags( Json_GetString( jsonData,"tags","" ) )
				
				If Not author Then author="---"
				author="by "+author
				
				If GetFileType( preview ) <> FileType.File
					preview=folder+preview
				Endif
				If GetFileType( source ) <> FileType.File
					source=folder+source
				Endif
				
				Local i:=New Item
				i.title=title
				i.author=author
				i.descr=descr
				i.previewPath=preview
				i.sourcePath=source
				i.homepage=homepage
				i.modified=modified
				i.version=version
				i.tags=tags
				
				_items.Add( i )
				
				Local v:=CreateBananaView( i )
				_views.Add( v )
				
				_list.AddItem( title )
				
			Catch ex:Throwable
				
			End
			
		Next
		
	End
	
	Method CreateBananaView:View( item:Item )
		
		Local dock:=New DockingView
		dock.Style=App.Theme.GetStyle( "BananasView" )
		
		' preview
		Local img:=Image.Load( item.previewPath )
		AdjustImageScale( img,_cellWidth,_cellHeight )
		Local lab:=New Label( "",img )
		dock.AddView( lab,"top" )
		
		' title and open button
		Local titleDock:=New DockingView
		Local btn:=New Button( "Open" )
		btn.Clicked+=Lambda()
			MainWindow.OpenDocument( item.sourcePath,True )
		End
		titleDock.ContentView=New Label( item.title)
		titleDock.AddView( btn,"right" )
		dock.AddView( titleDock,"top" )
		
		' description
		dock.AddView( New Label( item.descr ),"top" )
		
		' authors
		dock.AddView( New Label( item.author ),"top" )
		
		' version and modified
		Local vers:=item.version
		If vers Then vers="v"+vers
		If item.modified
			If vers Then vers+=" at "
			vers+=item.modified
		Endif
		If vers Then dock.AddView( New Label( vers ),"top" )
		
		'tags
		If item.tags Then dock.AddView( New Label( item.tags ),"top" )
		
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
	
	Method ProcessTags:String( tagsStr:String )
		
		Local arr:=tagsStr.Split( "," )
		tagsStr=""
		For Local i:=0 Until arr.Length
			
			Local t:="#"+arr[i].Trim()
			
			tagsStr+=t+" "
			'
			If Not _tags.Contains( t )
				_tags.Add( t )
				_filteredTags.Add( t )
			Endif
		Next
		
		Return tagsStr
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
