
Namespace ted2go



Interface ICodeItem Extends ListViewItem
	
End


Class CodeItem Implements ICodeItem
	
	Method New(ident:String)
		_ident = ident
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(_ident,x,y,handleX,handleY)
	End
	
	Private
	
	Field _ident:String
	
End


Class StringItem Implements ListViewItem
	
	Property Text:String()
		Return _text
	End
	
	Method New(text:String)
		_text = text
	End
	
	Method Draw(canvas:Canvas,x:Float,y:Float, handleX:Float=0, handleY:Float=0)
		canvas.DrawText(_text,x,y,handleX,handleY)
	End
	
	Private
	
	Field _text:String
	
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
		
		'if typed ident starts with previous
		'need to  simple filter items
		If IsOpened And ident.StartsWith(_ident)
			
		End
		
		
		If _keywords[fileType] = Null Then UpdateKeywords(fileType)
			
		Local result := New List<ListViewItem>
		
		'add keywords
		Local kw := _keywords[fileType]
		For Local i := Eachin kw
			Local txt := i.Text.ToLower()
			If txt.StartsWith(ident)
				result.AddLast(i)
			End
		Next
		
		'nothing to show
		If result.Empty 
			Hide()
			Return
		Endif
		
		result.Sort()
		
		_view.Reset()'reset selIndex
		_view.SetItems(result)
		
	
		Show()
			
		_ident = ident
		
	End
	
		
	Private
	
	Field _view:ListView
	Field _keywords:StringMap<List<ListViewItem>>
	Field _ident:String
	
	Method New()
	End
	
	Method OnKeyFilter(event:KeyEvent)
		If Not IsOpened Return
		If event.Type = EventType.KeyDown Or event.Type = EventType.KeyRepeat
			Select event.Key
			Case Key.Escape
				Hide()
				event.Eat()
			case Key.Up
				_view.SelectPrev()
				event.Eat()
			case Key.Down
				_view.SelectNext()
				event.Eat()
			case Key.Enter
				OnItemChoosen(_view.CurrentItem)
				event.Eat()
				
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
		Local kw := KeywordsManager.Get(fileType)
		Local list := New List<ListViewItem>
		For Local i := Eachin kw.Values()
			list.AddLast(New StringItem(i))
		Next
		_keywords[fileType] = list
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

