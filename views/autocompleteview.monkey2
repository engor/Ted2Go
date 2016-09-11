
Namespace ted2go


Class CodeListViewItem Implements ListViewItem
	
	Method New(ident:String)
		_ident = ident
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(_ident,x,y,handleX,handleY)
	End
	
	Property CodeItem:ICodeItem()
		Return _item
	End
	
	
	Private
	
	Field _ident:String
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
	
	Method Show(ident:String, fileType:String)
		
		ident = ident.ToLower()
		
		'if typed ident starts with previous
		'need to  simple filter items
		If IsOpened And ident.StartsWith(_ident)
			
		End
		
		
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
		If _parsers[fileType] = Null Then UpdateParsers(fileType)
			
		Local result := New List<ListViewItem>
		
		'add keywords
		Local kw := _keywords[fileType]
		For Local i := Eachin kw
			Local txt := i.Text.ToLower()
			If txt.StartsWith(ident)
				result.AddLast(i)
			End
		Next
		
		'add parsed words
		Local items := _parsers[fileType].Items
		For Local i := Eachin items
			Local txt := i.Ident.ToLower()
			If txt.StartsWith(ident)
				result.AddLast(New StringListViewItem(i.Ident)) 'call NEW everytime - not good
			End
		Next
		
		
		If IsOpened Then Hide() 'hide to re-layout on open
		
		'nothing to show
		If result.Empty 
			Return
		Endif
		
		result.Sort(False)
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
		Show()
			
		_ident = ident
		
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _ident:String
	Field _parsers:StringMap<ICodeParser>
	
	
	Method New()
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
			Case Key.Enter
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
		'Local si := Cast<StringItem>(item)
		'Local t := ""
		'If si <> Null
		'	t = si.Text
		'End
		
		OnChoosen(item.Text)
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
		Local s := "#If ,#Rem,#End,#Import "
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

