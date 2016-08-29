
Namespace code2go


#rem monkeydoc Keywords for someone language
#end
Class Keywords
	
	Method New()
	End
	
	Method New(words:String[])
		For Local kw := Eachin words
			_keywords[kw.ToLower()] = kw
		Next
	End
	
	Method Contains:Bool(word:String)
		Return _keywords.Contains(word.ToLower())
	End

	Method Get:String(word:String)
		Return _keywords[word.ToLower()]
	End	
	

Private
	
	Global _keywords := New StringMap<String>
	
End


#rem monkeydoc KeywordsManager class.
Storage for all keywords for all supported highlighted langs.
#end

Class KeywordsManager
	
	Function Init()
		Local json:JsonObject
		Local file := AppDir()+ "keywords.json"
		If (GetFileType(file) = FileType.File)
			json = JsonObject.Load(file)
		Else
			json = GetInternal()
		Endif
		
		Local langs := json["langs"]
		Local arr := langs.ToString().Split(";")
		For Local l := Eachin arr
			Local words := json[l].ToString().Split(";")
			_map[l.ToLower()] = New Keywords(words)
		Next
	End
	
	Function Contains:Bool(lang:String)
		Return _map.Contains(lang.ToLower())
	End

	Function Get:Keywords(lang:String)
		Local kw := _map[lang.ToLower()]
		If kw = Null Then kw = _empty
		Return kw
	End	
	

Private
	
	Global _map := New StringMap<Keywords>
	Global _empty := New Keywords
	
	Function GetInternal:JsonObject()
		Local json:="{"
		json+="~qlangs~q:~qmonkey2~q,"
		json+="~qmonkey2~q:~q"
		json+="Namespace;Using;Import;Extern;"
		json+="Public;Private;Protected;Friend;"
		json+="Void;Bool;Byte;UByte;Short;UShort;Int;UInt;Long;ULong;Float;Double;String;Object;Continue;Exit;"
		json+="New;Self;Super;Eachin;True;False;Null;Where;"
		json+="Alias;Const;Local;Global;Field;Method;Function;Property;Getter;Setter;Operator;Lambda;"
		json+="Enum;Class;Interface;Struct;Extends;Implements;Virtual;Override;Abstract;Final;Inline;"
		json+="Var;Varptr;Ptr;"
		json+="Not;Mod;And;Or;Shl;Shr;End;"
		json+="If;Then;Else;Elseif;Endif;"
		json+="While;Wend;"
		json+="Repeat;Until;Forever;"
		json+="For;To;Step;Next;"
		json+="Select;Case;Default;"
		json+="Try;Catch;Throw;Throwable;"
		json+="Return;Print;Static;Cast"
		json+="~q}"
		Return JsonObject.Parse(json)
	End
	
End