
Namespace ted2go


Class Monkey2Keywords Extends KeywordsPlugin
	
	Property Name:String() Override
		Return "Monkey2Keywords"
	End
	
			
	Private
	
	Global _instance := New Monkey2Keywords
	
	Method New()
		Super.New()
		_types = New String[](".monkey2")
	End
	
	Method GetInternal:String() Override
		Local s:="" 
		s+="Namespace;Using;Import;Extern;"
		s+="Public;Private;Protected;Friend;"
		s+="Void;Bool;Byte;UByte;Short;UShort;Int;UInt;Long;ULong;Float;Double;String;Object;Continue;Exit;"
		s+="New;Self;Super;Eachin;True;False;Null;Where;"
		s+="Alias;Const;Local;Global;Field;Method;Function;Property;Getter;Setter;Operator;Lambda;"
		s+="Enum;Class;Interface;Struct;Extends;Implements;Virtual;Override;Abstract;Final;Inline;"
		s+="Var;Varptr;Ptr;"
		s+="Not;Mod;And;Or;Shl;Shr;End;"
		s+="If;Then;Else;Elseif;Endif;"
		s+="While;Wend;"
		s+="Repeat;Until;Forever;"
		s+="For;To;Step;Next;"
		s+="Select;Case;Default;"
		s+="Try;Catch;Throw;Throwable;"
		s+="Return;Print;Static;Cast;Extension"
		Return s
	End
	
	'Method GetWordsFilePath:String() Override
	'	Return AppDir()+"keywords-monkey2.json"
	'End
	
End
