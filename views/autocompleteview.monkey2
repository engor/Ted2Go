
Namespace ted2go


Class CodeListViewItem Implements ListViewItem
	
	Method New(item:CodeItem)
		_item = item
		_icon = CodeItemIcons.GetIcon(item)
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		Local dx := 0.0
		If _icon <> Null
			canvas.DrawImage(_icon, x-_icon.Width*handleX, y-_icon.Height*handleY)
			dx = _icon.Width+8
		Endif
		canvas.DrawText(Text, x+dx, y, handleX, handleY)
	End
	
	Property CodeItem:CodeItem()
		Return _item
	End
	
	Property Text:String()
		Return _item.Text
	End
	
	
	Private
	
	Field _item:CodeItem
	Field _icon:Image
	
End



Class AutocompleteDialog Extends DialogExt
	
	Field OnChoosen:Void(text:String)
	
	Method New(title:String)
		Self.New(title,280,480)
	End
	
	Method New(title:String,width:Int,maxHeight:Int)
	
		Title = title
		
		_view = New ListView(20,width,maxHeight)
		
		ContentView = _view
		
		_keywords = New StringMap<List<ListViewItem>>
		_parsers = New StringMap<ICodeParser>
		
		_view.OnItemChoosen += Lambda()
			OnItemChoosen(_view.CurrentItem)
		End
		
		App.KeyEventFilter += Lambda(event:KeyEvent)
			OnKeyFilter(event)
		End
		
	End
	
	Property LastIdentPart:String()
		Return _lastIdentPart
	End
	
	Property FullIdent:String()
		Return _fullIdent
	End
	
	Method CanShow:Bool(line:String, posInLine:Int, fileType:String)
	
		Local parser := GetParser(fileType)
		Return parser.CanShowAutocomplete(line, posInLine)
		
	End
	
	Method Show(ident:String, filePath:String, fileType:String, docLine:Int)
		
		Local dotPos := ident.FindLast(".")
		
		' using lowerCase for keywords
		Local lastIdent := (dotPos > 0) ? ident.Slice(dotPos+1) Else ident
		lastIdent = lastIdent.ToLower()
		
		Local starts := ident.ToLower().StartsWith(_fullIdent.ToLower())
		
		Local result := New List<ListViewItem>
		
		'-----------------------------
		' some optimization
		'-----------------------------
		'if typed ident starts with previous
		'need to simple filter items
		If IsOpened And starts And Not ident.EndsWith(".")
			
			Local items := _view.Items
			For Local i := Eachin items
				
				If i.Text.ToLower().StartsWith(lastIdent)
					result.AddLast(i)
				Endif
				
			Next
			
			' some "copy/paste" code
			_fullIdent = ident
			_lastIdentPart = lastIdent
			If IsOpened Then Hide() 'hide to re-layout on open
			
			'nothing to show
			If result.Empty 
				Return
			Endif
						
			_view.Reset()'reset selIndex
			_view.SetItems(result)
			
			Show()
			
			Return
		End
		
		
		_fullIdent = ident
		_lastIdentPart = lastIdent
		
		Local onlyOne := (dotPos = -1)
		
		'-----------------------------
		' extract keywords
		'-----------------------------
		If onlyOne
			Local kw := GetKeywords(fileType)
			For Local i := Eachin kw
				Local txt := i.Text.ToLower()
				If txt.StartsWith(lastIdent)
					result.AddLast(i)
				End
			Next
		Endif
		
		'-----------------------------
		' extract items
		'-----------------------------
		Local parser := GetParser(fileType)
		_listForExtract.Clear()
		parser.GetItemsForAutocomplete(ident, filePath, docLine, _listForExtract)
		
		For Local i := Eachin _listForExtract
			result.AddLast(New CodeListViewItem(i))
		End
		
		' hide to re-layout on open
		If IsOpened Then Hide()
		
		' nothing to show
		If result.Empty 
			Return
		Endif
				
		SortResults(result)
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
		Show()
				
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _lastIdentPart:String, _fullIdent:String
	Field _parsers:StringMap<ICodeParser>
	Field sorter:Int(lhs:ListViewItem, rhs:ListViewItem)
	Field _listForExtract := New List<CodeItem>
	
	
	Method New()
	End
	
	Method SortResults(list:List<ListViewItem>)
		
		If sorter = Null
			sorter = Lambda:Int(lhs:ListViewItem, rhs:ListViewItem)
				Return lhs.Text <=> rhs.Text
			End
		Endif
		
		list.Sort(sorter)
		
	End
	
	Method GetParser:ICodeParser(fileType:String)
		If _parsers[fileType] = Null Then UpdateParsers(fileType)
		Return _parsers[fileType]
	End
	
	Method GetKeywords:List<ListViewItem>(fileType:String)
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
		Return _keywords[fileType]
	End
	
	Method IsItemInScope:Bool(item:CodeItem, scope:CodeItem)
		If scope = Null Return False
		Return item.ScopeStartLine >= scope.ScopeStartLine And item.ScopeEndLine <= scope.ScopeEndLine
	End
	
	Method OnKeyFilter(event:KeyEvent)
		If Not IsOpened Return
		If event.Type = EventType.KeyDown Or event.Type = EventType.KeyRepeat
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
			Case Key.Home
				_view.SelectFirst()
				event.Eat()
			Case Key.KeyEnd
				_view.SelectLast()
				event.Eat()
			Case Key.Enter, Key.KeypadEnter
				OnItemChoosen(_view.CurrentItem)
				event.Eat()
			Case Key.Backspace
			Case Key.CapsLock
			Case Key.LeftShift, Key.RightShift
			Case Key.LeftControl, Key.RightControl
			Case Key.LeftAlt, Key.RightAlt
				'do nothing, skip filtering
			Default
				'Hide()
			End
			
		Endif
	End
	
	Method OnItemChoosen(item:ListViewItem)
		Local si := Cast<CodeListViewItem>(item)
		Local t := ""
		If si <> Null
			t = si.CodeItem.Ident
		Else
			t = item.Text
		End
		
		OnChoosen(t)
		Hide()
	End
	
	Method UpdateKeywords(fileType:String)
		'keywords
		Local kw := KeywordsManager.Get(fileType)
		Local list := New List<ListViewItem>
		For Local i := Eachin kw.Values()
			list.AddLast(New StringListViewItem(i))
		Next
		'preprocessor
		'need to load it like keywords
		Local s := "#If ,#Rem,#End,#Endif,#Import "
		Local arr := s.Split(",")
		For Local i := Eachin arr
			list.AddLast(New StringListViewItem(i))
		Next
		_keywords[fileType] = list
	End
	
	Method UpdateParsers(fileType:String)
		_parsers[fileType] = ParsersManager.Get(fileType)
	End
	
End
