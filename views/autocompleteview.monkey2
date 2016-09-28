
Namespace ted2go


Class CodeListViewItem Implements ListViewItem
	
	Method New(item:ICodeItem)
		_item = item
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(Text,x,y,handleX,handleY)
	End
	
	Property CodeItem:ICodeItem()
		Return _item
	End
	
	Property Text:String()
		Return _item.Text
	End
	
	
	Private
	
	Field _item:ICodeItem
	
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
	
	Property Ident:String()
		Return _ident
	End
	
	Method Show(ident:String, filePath:String, fileType:String, docLine:Int)
		
		'ident = ident.ToLower()
		
		'if typed ident starts with previous
		'need to simple filter items
		If IsOpened And ident.StartsWith(_ident)
			
		End
		
		
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
		If _parsers[fileType] = Null Then UpdateParsers(fileType)
			
		Local parser := _parsers[fileType]
		
		Local result := New List<ListViewItem>
		
		'add keywords
		Local kw := _keywords[fileType]
		For Local i := Eachin kw
			Local txt := i.Text.ToLower()
			If txt.StartsWith(ident)
				result.AddLast(i)
			End
		Next
		
		Local idents := ident.Split(".")
		Local items:List<ICodeItem>
		
		'ident = idents[idents.Length-1]
		
		'check current scope
'		Local target := New List<ICodeItem>
		Local scope := parser.GetScope(filePath, docLine)

		' the first ident part
		Local onlyOne := (idents.Length = 1)
		
		'what the first ident is?	
		Local firstIdent := idents[0]
		Local item:ICodeItem = Null
		
		' check in this scope
		If scope <> Null

			Local items := scope.Children
			If items <> Null
				For Local i := Eachin items
					If CheckAccess(i, filePath) And CheckIdent(i.Ident, firstIdent, onlyOne)
						If Not onlyOne
							item = i
							Exit
						Else
							result.AddLast(New CodeListViewItem(i))
						Endif
					Endif
				Next
			Endif

		Endif
		
		' and check in global scope
		If item = Null Or onlyOne
			For Local i := Eachin parser.Items
				If CheckAccess(i, filePath) And CheckIdent(i.Ident, firstIdent, onlyOne)
					If Not onlyOne
						item = i
						Exit
					Else
						result.AddLast(New CodeListViewItem(i))
					Endif
				Endif
			Next
		Endif
		
		'If item <> Null Print "first: "+item.Text
		
		' var1.var2.var3...
		If Not onlyOne And item <> Null
			
			' strt from the second ident part here
			For Local k := 1 Until idents.Length
				
				' need to check by ident type
				Local type := item.Type
				'Print "idnt: "+item.Ident+" : "+type+" : "+item.KindStr
				item = Null
				For Local i := Eachin parser.Items
					If i.Ident = type
						item = i
						Exit
					Endif
				Next
				If item = Null Then Exit
				scope = item
				
				Local identPart := idents[k]
				Local last := (k = idents.Length-1)
									
				Local items := item.Children
				If items <> Null
					For Local i := Eachin items
						If CheckAccess(i, filePath) And CheckIdent(i.Ident, identPart, last)
							item = i
							If last
								result.AddLast(New CodeListViewItem(i))
							Else
								Exit
							Endif
						Endif
					Next
				Endif
				
				If item = Null Then Exit
			Next
			
		Endif

		
		If IsOpened Then Hide() 'hide to re-layout on open
		
		'nothing to show
		If result.Empty 
			Return
		Endif
		
		result.Sort(False)
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
		Show()
		
		' store last ident part
		_ident = idents[idents.Length-1]
		
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _ident:String
	Field _parsers:StringMap<ICodeParser>
	
	
	Method New()
	End
	
	Method CheckAccess:Bool(item:ICodeItem, filePath:String)
		Local a := item.Access
		If a = AccessMode.Public_ Return True
		' need to extend logic for 'protected'
		Return item.FilePath = filePath
	End
	
	Method CheckIdent:Bool(ident1:String, ident2:String, startsOnly:Bool)
		If ident2 = "" Return True
		If startsOnly
			Return ident1.ToLower().StartsWith(ident2.ToLower())
		Else
			Return ident1 = ident2
		Endif
	End
	
	Method ItemsAtScopeInternal(scope:ICodeItem, ident:String, startsOnly:Bool, findInParents:Bool, target:List<ICodeItem>)
		
		Local item := scope
		While item <> Null
			If (startsOnly And item.Ident.ToLower().StartsWith(ident)) Or (Not startsOnly And item.Ident = ident)
				target.AddLast(item)
			Endif
			
			Local items := item.Children
			If items <> Null
				For Local i := Eachin items
					If (startsOnly And i.Ident.ToLower().StartsWith(ident)) Or (Not startsOnly And i.Ident = ident)
						target.AddLast(i)
					Endif
				Next
			Endif
			If findInParents
				item = item.Parent
			Else
				Return
			Endif
		Wend
		
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
				Hide()
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


Private

Class KeywordWrapper
	
	Method New(word:String, fileType:String)
		_word = word
		_fileType = fileType
	End
	
	Property Word:String()
		Return _word
	End
	
	Property FileType:String()
		Return _fileType
	End
	
		
	Private
	
	Field _word:String
	Field _fileType:String
	
End

