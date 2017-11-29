
Namespace ted2go


Function IsBananasShowcaseAvailable:Bool()
	
	Return GetFileType( Prefs.MonkeyRootPath+"bananas/ted2go-showcase/all.bananas" )=FileType.File
End

Class BananasDocument Extends Ted2Document

	Method New( path:String )
		Super.New( path )
		
		Local scrollView:=New ScrollableViewExt
		scrollView.Style=App.Theme.GetStyle( "BananasView" )
		_view=scrollView
		
		_table=New TableView( 3,1 )
		_table.Layout="float"
		_table.Gravity=New Vec2f( 0.5,0 )
		scrollView.ContentView=_table
		
		_filterPanel=New ToolBarExt
		Local sbox:=New ScrollViewTabs( _filterPanel )
		sbox.ScrollBarsVisible=False
		
		scrollView.AddView( sbox,"bottom" )
		
		Local lab:=New Label( "Bananas Showcase" )
		lab.Style=App.Theme.GetStyle( "BananasTitle" )
		lab.Gravity=New Vec2f( 0.5,0 )
		lab.Layout="float"
		scrollView.AddView( lab,"top" )
		
		_list=New ListView
		Local st:=_list.Style.Copy()
		st.Padding=New Recti( -6,-6,6,6 )
		_list.Style=st
		_list.ItemDoubleClicked+=Lambda( item:ListView.Item )
			
			OpenItem( FindItem( item.Text ) )
		End
	End


	Protected
	
	Method OnLoad:Bool() Override
	
		Reset()
		Parse()
		ShowElements()
		UpdateFilterPanel()
		
		Return True
	End
	
	Method OnCreateBrowser:View() Override
	
		Return _list
	End
	
	Method OnCreateView:View() Override
		
		Return _view
	End
	
	
	Private
	
	Const EMPTY_TAG:="#"
	Const MAX_WIDTH:=256
	Const MAX_HEIGHT:=196
	Field _list:ListView
	Field _table:TableView
	Field _view:View
	Field _items:=New Stack<Item>
	Field _views:=New Stack<View>
	Field _cols:Int,_rows:Int
	Field _tags:=New StringStack
	Field _filterTags:=New StringStack
	Field _filterViews:=New Stack<ToolButtonExt>
	Field _filterPanel:ToolBarExt
	
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
	
	
	Method Reset()
		
		_items.Clear()
		_views.Clear()
		_tags.Clear()
		_filterTags.Clear()
		_filterViews.Clear()
	End
	
	Method FindItem:Item( title:String )
		
		For Local i:=Eachin _items
			If i.title = title Return i
		Next
		Return Null
	End
	
	Method OpenItem( item:Item )
		
		If item<>Null Then MainWindow.OpenDocument( item.sourcePath,True )
	End
	
	Method UpdateFilterPanel()
		
		_filterPanel.RemoveAllViews()
		
		Local action:=New Action( "Reset" )
		action.Triggered+=Lambda()
			_filterTags.Clear()
			For Local v:=Eachin _filterViews
				v.IsToggled=False
			Next
			OnFilterChanged()
		End
		Local button:=New ToolButtonExt( action,"Reset filters" )
		_filterPanel.AddView( button,"left" )
		
		For Local tag:=Eachin _tags
			action=New Action( tag )
			button=New ToolButtonExt( action )
			button.ToggleMode=True
			button.Toggled+=Lambda( toggled:Bool )
				If toggled Then _filterTags.Add( tag ) Else _filterTags.Remove( tag )
				OnFilterChanged()
			End
			_filterPanel.AddView( button,"left" )
			_filterViews.Add( button )
		Next
		
	End
	
	Method OnFilterChanged()
		
		ShowElements()
	End
	
	Method ShowElements()
		
		_table.RemoveAllRows()
		_list.RemoveAllItems()
		
		Local count:=GetVisibleCount()
		
		Local cols:=_table.Columns
		Local rows:=count/cols
		If count Mod cols <> 0 Then rows+=1
		
		_table.Rows=rows
		
		Local r:=0,c:=0,i:=0
		For Local k:=0 Until _items.Length
			
			If Not IsItemVisible( _items[k] ) Continue
			
			r=i/cols
			c=i Mod cols
			i+=1
			_table[c,r]=_views[k]
			
			_list.AddItem( _items[k].title )
		Next
		
	End
	
	Method GetVisibleCount:Int()
		
		If _filterTags.Empty Return _items.Length
		
		Local count:=0
		For Local i:=Eachin _items
			If IsItemVisible( i ) Then count+=1
		Next
		Return count
	End
	
	Method IsItemVisible:Bool( item:Item )
		
		If _filterTags.Empty Return True
		
		For Local tag:=Eachin _filterTags
			if item.tags.Contains( tag ) Return True
		Next
		Return False
	End
	
	Method Parse()
		
		ParseFile()
		'ParseFolder()
		
		_tags.Sort()
	End
	
	Method ParseFolder()
		
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
			Try 
				Local folder:=ExtractDir( file )
				
				Local jsonData:=JsonObject.Load( file ).Data
				
				ParseItem( jsonData,folder,folder )
				
			Catch ex:Throwable
				
			End
			
		Next
		
	End
	
	Method ParseFile()
	
		Local json:=JsonObject.Load( Path )
		
		Local arr:=json.GetArray( "bananas" )
		Local bananasFolder:=FixFolder( json.GetString( "bananasFolder" ) )
		Local previewsFolder:=FixFolder( json.GetString( "previewsFolder" ) )
		
		
		For Local i:=Eachin arr
			
			Try 
				Local jsonData:=i.ToObject()
				
				ParseItem( jsonData,bananasFolder,previewsFolder )
				
			Catch ex:Throwable
				
				Print "catch"
			End
			
		Next
	
	End
	
	Method ParseItem:Item( jsonData:StringMap<JsonValue>,bananasFolder:String,previewsFolder:String )
		
		Local title:=Json_GetString( jsonData,"title","" )
		Local author:=Json_GetString( jsonData,"author","(unknown)" )
		Local descr:=Json_GetString( jsonData,"description","" )
		Local preview:=Json_GetString( jsonData,"preview","" )
		Local source:=Json_GetString( jsonData,"mainFile","" )
		Local homepage:=Json_GetString( jsonData,"homepage","" )
		Local modified:=Json_GetString( jsonData,"modified","" )
		Local version:=Json_GetString( jsonData,"version","" )
		Local tags:=ProcessTags( Json_GetString( jsonData,"tags","" ) )
		
		'If Not author Then author="(unknown)"
		If author Then author="by "+author
		
		If GetFileType( preview ) <> FileType.File
			preview=previewsFolder+preview
		Endif
		If GetFileType( source ) <> FileType.File
			source=bananasFolder+source
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
		
		Return i
	End
	
	Method FixFolder:String( folder:String )
		
		If GetFileType( folder )<>FileType.Directory Then folder=AppDir()+folder
		Return folder
	End
	
	Method CreateBananaView:View( item:Item )
		
		Local dock:=New DockingView
		dock.Style=App.Theme.GetStyle( "BananasCard" )
		
		' preview
		Local img:=Image.Load( item.previewPath )
		AdjustImageScale( img,MAX_WIDTH,MAX_HEIGHT )
		Local lab:=New Label( " ",img )
		dock.AddView( lab,"top" )
		
		' title and open button
		Local titleDock:=New DockingView
		Local btn:=New Button( "Open" )
		btn.Style=App.Theme.GetStyle( "BananasButton" )
		btn.Clicked+=Lambda()
			OpenItem( item )
		End
		lab=New Label( item.title)
		lab.Style=App.Theme.GetStyle( "BananasTitle" )
		titleDock.ContentView=lab
		titleDock.AddView( btn,"right" )
		dock.AddView( titleDock,"top" )
		' homepage
		If item.homepage
			btn=New Button( "Web" )
			btn.Style=App.Theme.GetStyle( "BananasButton" )
			btn.Clicked+=Lambda()
				OpenUrl( item.homepage )
			End
			titleDock.AddView( btn,"right" )
		Endif
		
		' description
		Local tv:=New TextView( item.descr )
		tv.Style=App.Theme.GetStyle( "BananasDescription" )
		Local ww:=tv.Style.Font.TextWidth( item.descr )
		Local lines:=1+Max( 1.0, ww/(MAX_WIDTH-40) )
		tv.WordWrap=True
		tv.ReadOnly=True
		Local hh:=Min( 96.0,lines*tv.Style.Font.Height+20)
		tv.MinSize=New Vec2i( 0,hh )
		dock.AddView( tv,"top" )
		
		' authors
		If item.author Then dock.AddView( New Label( item.author ),"top" )
		
		' version and modified
'		Local vers:=item.version
'		If vers Then vers="v"+vers
'		If item.modified
'			If vers Then vers+=" at "
'			vers+=item.modified
'		Endif
'		If vers Then dock.AddView( New Label( vers ),"top" )
		
		'tags
		If item.tags Then dock.AddView( New Label( item.tags ),"top" )
		
		Return dock
	End
	
	Method AdjustImageScale( img:Image,fitWidth:Float,fitHeight:Float )
		
		If Not img Return
		
		Local iw:=img.Width
		Local ih:=img.Height
		Local kw:=fitWidth/iw
		'Local kh:=fitHeight/ih
		'Local k:=Max( kw,kh )
		Local k:=kw
		
		img.Scale=App.Theme.Scale*k
	End
	
	Method ProcessTags:String( tagsStr:String )
		
		Local arr:=tagsStr.Split( "," )
		tagsStr=""
		For Local i:=0 Until arr.Length
			
			Local t:=arr[i].Trim()
			If Not t Continue
			
			t="#"+t
			tagsStr+=t+" "
			'
			If Not( t=EMPTY_TAG Or _tags.Contains( t ) )
				_tags.Add( t )
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
