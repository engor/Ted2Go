
Namespace ted2go


Class CodeListViewItem Extends ListViewItem
	
	Method New( item:CodeItem )

		Super.New( item.Text )
		_item=item
		Icon=CodeItemIcons.GetIcon( item )
	End
		
	Property CodeItem:CodeItem()
		Return _item
	End
	
	
	Private
	
	Field _item:CodeItem
	
End


Class AutocompleteListView Extends ListViewExt
	
	Field word:String 'word to select
	
	Method New( lineHeight:Int,maxLines:Int )
		Super.New( lineHeight,maxLines )
	End
	
	
	Protected
	
	Method DrawItem( item:ListViewItem,canvas:Canvas,x:Float,y:Float,handleX:Float=0,handleY:Float=0 ) Override
		
		canvas.Color=App.Theme.DefaultStyle.TextColor
		
		Local txt:=item.Text
		Local icon:=item.Icon
		If icon <> Null
			canvas.Alpha=.8
			canvas.DrawImage( icon,x-icon.Width*handleX,y-icon.Height*handleY )
			x+=icon.Width+8
			canvas.Alpha=1
		Endif
		If Not word
			canvas.DrawText( txt,x,y,handleX,handleY )
			Return
		Endif
		
		Local fnt:=canvas.Font
		Local clr:Color
		Local ch:=word[0],index:=0,len:=word.Length
		
		For Local i:=0 Until txt.Length
			Local s:=txt.Slice( i,i+1 )
			Local w:=fnt.TextWidth( s )
			If ch<>-1 And s.ToLower()[0]=ch
				index+=1
				ch = index>=len ? -1 Else word[index]
				clr=canvas.Color
				canvas.Color=_selColor
				canvas.DrawRect( x,y-LineHeight*handleY,w,LineHeight )
				canvas.Color=clr
			Endif
			canvas.DrawText( s,x,y,handleX,handleY )
			x+=w
		Next
	End
	
	
	Private
	
	Field _selColor:=New Color( .8,.8,.8,.1 )
	
End


Struct AutocompleteResult
	
	Field ident:String
	Field text:String
	Field item:CodeItem
	Field bySpace:Bool
	
End


Class AutocompleteDialog Extends NoTitleDialog
	
	Field OnChoosen:Void( result:AutocompleteResult )
	
	Method New()
		
		Super.New()
		
		_view=New AutocompleteListView( 20,15 )
		_view.MoveCyclic=True
		
		_view.MaxSize=New Vec2i( 500,20*15 )
		
		ContentView=_view
		
		_keywords=New StringMap<List<ListViewItem>>
		_parsers=New StringMap<ICodeParser>
		
		_view.OnItemChoosen+=Lambda()
			OnItemChoosen( _view.CurrentItem )
		End
		
		App.KeyEventFilter+=Lambda( event:KeyEvent )
			OnKeyFilter( event )
		End
		
		OnHide+=Lambda()
			_disableUsingsFilter=False
		End
		
	End
	
	Property DisableUsingsFilter:Bool()
		Return _disableUsingsFilter
	Setter( value:Bool )
		_fullIdent=""
		_disableUsingsFilter=value
	End
	
	Property LastIdentPart:String()
		Return _lastIdentPart
	End
	
	Property FullIdent:String()
		Return _fullIdent
	End
	
	Method CanShow:Bool( line:String,posInLine:Int,fileType:String )
	
		Local parser:=GetParser( fileType )
		Return parser.CanShowAutocomplete( line,posInLine )
		
	End
	
	Method Show( ident:String,filePath:String,fileType:String,docLine:Int )
		
		Local dotPos:=ident.FindLast( "." )
		
		' using lowerCase for keywords
		Local lastIdent:=(dotPos > 0) ? ident.Slice( dotPos+1 ) Else ident
		Local lastIdentLower:=lastIdent.ToLower()
				
		_view.word=lastIdentLower
		
		Local starts:=(_fullIdent And ident.StartsWith( _fullIdent ))
		
		Local result:=New Stack<ListViewItem>
		
		Local parser:=GetParser( fileType )
		
		Local filter:=_disableUsingsFilter
		
		'-----------------------------
		' some optimization
		'-----------------------------
		'if typed ident starts with previous
		'need to simple filter items
		
		If IsOpened And starts And Not ident.EndsWith(".")
			
			Local items:=_view.Items
			For Local i:=Eachin items
				
				If parser.CheckStartsWith( i.Text,lastIdentLower )
					result.Add( i )
				Endif
				
			Next
			
			' some "copy/paste" code
			_fullIdent=ident
			_lastIdentPart=lastIdentLower
			If IsOpened Then Hide() 'hide to re-layout on open
			
			'nothing to show
			If result.Empty
				Return
			Endif
			
			CodeItemsSorter.SortByIdent( result,lastIdent )
			
			_view.Reset()'reset selIndex
			_view.SetItems( result )
			
			Super.Show()
			
			_disableUsingsFilter=filter
			Return
		End
		
		
		_fullIdent=ident
		_lastIdentPart=lastIdentLower
		
		Local onlyOne:=(dotPos = -1)
		
		'-----------------------------
		' extract items
		'-----------------------------
		
		If Not Prefs.AcKeywordsOnly
		
			Local usings:Stack<String>
			
			If onlyOne And Not _disableUsingsFilter
				
				usings=New Stack<String>
				
				Local locked:=MainWindow.LockedDocument
				local current:=Cast<CodeDocument>(MainWindow.DocsManager.CurrentDocument)
				
				If Not locked Then locked=current
				If locked
					Local info:=parser.UsingsMap[locked.Path]
					If info.nspace Or info.usings
						usings=New StringStack
						If info.nspace Then usings.Add( info.nspace+".." )
						If info.usings Then usings.AddAll( info.usings )
					Endif
				Endif
				
				If current And current <> locked
					Local info:=parser.UsingsMap[current.Path]
					If info.nspace
						Local s:=info.nspace+".."
						If s And Not usings.Contains( s ) Then usings.Add( s )
					Endif
					If info.usings Then usings.AddAll( info.usings )
				Endif
				
			Endif
			
			_listForExtract.Clear()
			parser.GetItemsForAutocomplete( ident,filePath,docLine,_listForExtract,usings )
			
			CodeItemsSorter.SortByType( _listForExtract,True )
		Endif
		
		'-----------------------------
		' extract keywords
		'-----------------------------
		If onlyOne
			Local kw:=GetKeywords( fileType )
			For Local i:=Eachin kw
				If i.Text.ToLower().StartsWith( lastIdentLower )
					result.Add( i )
				Endif
			Next
		Endif
		
		'-----------------------------
		' remove duplicates
		'-----------------------------
		If Not Prefs.AcKeywordsOnly
			For Local i:=Eachin _listForExtract
				Local s:=i.Text
				Local exists:=False
				For Local ii:=Eachin result
					If ii.Text = s
						exists=True
						Exit
					Endif
				Next
				If Not exists
					result.Add( New CodeListViewItem( i ) )
				Endif
			Next
		Endif
		
		' hide to re-layout on open
		If IsOpened Then Hide()
		
		' nothing to show
		If result.Empty
			Return
		Endif
		
		If lastIdent Then CodeItemsSorter.SortByIdent( result,lastIdent )
		
		_view.Reset()'reset selIndex
		_view.SetItems( result )
		
		Super.Show()
		
		_disableUsingsFilter=filter
	End
	
	
	Private
	
	Field _view:AutocompleteListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _lastIdentPart:String,_fullIdent:String
	Field _parsers:StringMap<ICodeParser>
	Field _listForExtract:=New List<CodeItem>
	Field _listForExtract2:=New List<CodeItem>
	Field _disableUsingsFilter:Bool
	
	Method GetParser:ICodeParser( fileType:String )
		If _parsers[fileType] = Null Then UpdateParsers( fileType )
		Return _parsers[fileType]
	End
	
	Method GetKeywords:List<ListViewItem>( fileType:String )
		If _keywords[fileType] = Null Then UpdateKeywords( fileType )
		Return _keywords[fileType]
	End
	
	Method IsItemInScope:Bool( item:CodeItem,scope:CodeItem )
		If scope = Null Return False
		Return item.ScopeStartPos.x >= scope.ScopeStartPos.x And item.ScopeEndPos.x <= scope.ScopeEndPos.x
	End
	
	Method OnKeyFilter( event:KeyEvent )
		
		If Not IsOpened Return
		
		Select event.Type
			
			Case EventType.KeyDown,EventType.KeyRepeat
				
				Select event.Key
				Case Key.Escape
					Hide()
					event.Eat()
				Case Key.Up
					_view.SelectPrev()
					event.Eat()
				Case Key.Down
					_view.SelectNext()
					event.Eat()
				Case Key.PageUp
					_view.PageUp()
					event.Eat()
				Case Key.PageDown
					_view.PageDown()
					event.Eat()
				Case Key.Enter,Key.KeypadEnter
					If Prefs.AcUseEnter
						OnItemChoosen( _view.CurrentItem )
						If Not Prefs.AcNewLineByEnter Then event.Eat()
					Else
						Hide() 'hide by enter
					Endif
				Case Key.Tab
					If Prefs.AcUseTab
						OnItemChoosen( _view.CurrentItem )
						event.Eat()
					Endif
				Case Key.Space
					Local ctrl:=event.Modifiers & Modifier.Control
					If Prefs.AcUseSpace And Not ctrl
						OnItemChoosen( _view.CurrentItem,True )
						event.Eat()
					Endif
				Case Key.Period
					If Prefs.AcUseDot
						OnItemChoosen( _view.CurrentItem )
						event.Eat()
					Endif
				
				Case Key.Backspace
				Case Key.CapsLock
				Case Key.LeftShift,Key.RightShift
				Case Key.LeftControl,Key.RightControl
				Case Key.LeftAlt,Key.RightAlt
					'do nothing,skip filtering
				Default
					'Hide()
				End
			
			Case EventType.KeyChar
				
				If Not IsIdent( event.Text[0] ) Then Hide()
				
		End
		
	End
	
	Method OnItemChoosen( item:ListViewItem,bySpace:Bool=False )
		
		Local si:=Cast<CodeListViewItem>( item )
		Local ident:="",text:=""
		Local code:CodeItem=Null
		If si <> Null
			ident=si.CodeItem.Ident
			text=si.CodeItem.TextForInsert
			code=si.CodeItem
		Else
			ident=item.Text
			text=item.Text
		End
		Local result:=New AutocompleteResult
		result.ident=ident
		result.text=text
		result.item=code
		result.bySpace=bySpace
		OnChoosen( result )
		Hide()
	End
	
	Method UpdateKeywords( fileType:String )
		
		'keywords
		Local kw:=KeywordsManager.Get( fileType )
		Local list:=New List<ListViewItem>
		Local ic:=CodeItemIcons.GetKeywordsIcon()
		For Local i:=Eachin kw.Values()
			Local si:=New ListViewItem( i,ic )
			list.AddLast( si )
		Next
		'preprocessor
		'need to load it like keywords
		Local s:="#If ,#Rem,#End,#Endif,#Else,#Else If ,#Import ,monkeydoc,__TARGET__,__MOBILE_TARGET__,__DESKTOP_TARGET__,__HOSTOS__"
		Local arr:=s.Split( "," )
		For Local i:=Eachin arr
			list.AddLast( New ListViewItem( i ) )
		Next
		_keywords[fileType]=list
	End
	
	Method UpdateParsers( fileType:String )
		_parsers[fileType]=ParsersManager.Get( fileType )
	End
	
End
