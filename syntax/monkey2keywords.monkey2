
Namespace ted2


Class Monkey2Keywords Implements IKeywords
	
	Method Contains:Bool(word:String)
		Return _keywords.Contains(word)
	End

	Method Get:String(word:String)
		Return _keywords.Get(word)
	End	
	
	Function Acquire:IKeywords()
		Return _instance
	End
	
	Private
	
	Field _keywords:Keywords
	Global _instance := New Monkey2Keywords
	
	Method New()
		_keywords = KeywordsManager.Get("monkey2")
	End
	
End
