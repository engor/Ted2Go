
Namespace ted2


Class Highlighter

	Const COLOR_NONE:=0
	Const COLOR_IDENT:=1
	Const COLOR_KEYWORD:=2
	Const COLOR_STRING:=3
	Const COLOR_NUMBER:=4
	Const COLOR_COMMENT:=5
	Const COLOR_PREPROC:=6
	Const COLOR_OTHER:=7
	
	'use it like a property, as readonly
	Field Executor:Int( text:String,colors:Byte[],sol:Int,eol:Int,state:Int )
	
	Property Keywords:Keywords()
		Return _keywords
	End
	
	
	Protected
	
	Field _keywords:Keywords 'or codeanalyzer here which will be include keywords
	
End
