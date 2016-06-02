
Namespace std.json

#rem monkeydoc JsonError class.
#end
Class JsonError Extends Throwable
End

#rem monkeydoc JsonValue class.

This is base class of all JsonValue types.

#end
Class JsonValue Abstract

	Method ToBool:Bool() Virtual
		Assert( False )
		Return Null
	End
	
	Method ToNumber:Double() Virtual
		Assert( False )
		Return Null
	End	
	
	Method ToString:String() Virtual
		Assert( False )
		Return Null
	End
	
	Method ToArray:Stack<JsonValue>() Virtual
		Assert( False )
		Return Null
	End
	
	Method ToObject:StringMap<JsonValue>() Virtual
		Assert( False )
		Return Null
	End
	
	Method ToJson:String() Virtual
		Local buf:=New StringStack
		PushJson( buf )
		Return buf.Join( "" )
	End
		
	Method ToInt:Int()
		Return Int( ToNumber() )
	End
	
	Method ToLong:Long()
		Return Long( ToNumber() )
	End
	
	Method ToFloat:Float()
		Return Float( ToNumber() )
	End
	
	Method ToDouble:Double()
		Return ToNumber()
	End
	
	Method Save:Bool( path:String )
	
		Local buf:=New StringStack
		PushJson( buf )
		
		Local src:=buf.Join( "" )
		Return stringio.SaveString( src,path )
	End
	
	Function Load:JsonValue( path:String )
	
		Local src:=stringio.LoadString( path )
		If Not src Return Null
		
		Local parser:=New JsonParser( src )
		Local value:=parser.ParseValue()
		
		Return value
	End
	
	Protected
	
	#rem monkeydoc @hidden
	#end
	Method PushJson:Void( buf:StringStack ) Virtual
		buf.Push( ToJson() )
	End
	
End

#rem monkeydoc JsonBool class.
#end
Class JsonBool Extends JsonValue

	Const TrueValue:JsonBool=New JsonBool( True )
	
	Const FalseValue:JsonBool=New JsonBool( False )

	Method New( data:Bool=False )
		_data=data
	End
	
	Property Data:Bool()
		Return _data
	Setter( data:Bool )
		_data=data
	End
	
	Method ToBool:Bool() Override
		Return _data
	End
	
	Method ToNumber:Double() Override
		Return _data
	End
	
	Method ToString:String() Override
		Return _data ? "true" Else "false"
	End
	
	Method ToJson:String() Override
		Return _data ? "true" Else "false"
	End

	Private
	
	Field _data:Bool
End

#rem monkeydoc JsonNumber class.
#end
Class JsonNumber Extends JsonValue

	Method New( data:Double=0 )
		_data=data
	End
	
	Property Data:Double()
		Return _data
	Setter( data:Double )
		_data=data
	End
	
	Method ToBool:Bool() Override
		Return _data
	End
	
	Method ToNumber:Double() Override
		Return _data
	End
	
	Method ToString:String() Override
		Return _data
	End
	
	Method ToJson:String() Override
		Return _data
	End

	Private
	
	Field _data:Double
End

#rem monkeydoc JsonString class.
#end
Class JsonString Extends JsonValue

	Method New( data:String="" )
		_data=data
	End
	
	Property Data:String()
		Return _data
	Setter( data:String )
		_data=data
	End
	
	Method ToBool:Bool() Override
		Return _data
	End
	
	Method ToNumber:Double() Override
		Return Double( _data )
	End
	
	Method ToString:String() Override
		Return _data
	End
	
	Method ToJson:String() Override
		Return "~q"+_data.Replace( "~q","\~q" )+"~q"
	End

	Private
	
	Field _data:String
End

#rem monkeydoc JsonArray class.
#end
Class JsonArray Extends JsonValue

	Method New( length:Int=0 )
		_data=New Stack<JsonValue>( length )
	End

	Method New( data:JsonValue[] )
		_data=New Stack<JsonValue>( data )
	End
	
	Method New( data:Stack<JsonValue> )
		_data=data
	End
	
	Property Data:Stack<JsonValue>()
		Return _data
	Setter( data:Stack<JsonValue> )
		_data=data
	End
	
	Property Length:Int()
		Return _data.Length
	End
	
	Method Add( value:JsonValue )
		_data.Add( value )
	End
	
	Method ToArray:Stack<JsonValue>() Override
		Return _data
	End
	
	Private
	
	Field _data:Stack<JsonValue>
	
	Method PushJson:Void( buf:StringStack ) Override
		buf.Push( "[" )
		Local t:=False
		For Local value:=Eachin _data
			If t buf.Push( "," )
			If value value.PushJson( buf ) Else buf.Push( "null" )
			t=True
		Next
		buf.Push( "]" )
	End
	
End

#rem monkeydoc JsonObject class.
#end
Class JsonObject Extends JsonValue

	Method New( data:StringMap<JsonValue> =Null )
		If Not data data=New StringMap<JsonValue>
		_data=data
	End
	
	Property Data:StringMap<JsonValue>()
		Return _data
	Setter( data:StringMap<JsonValue> )
		_data=data
	End
	
	Method Contains:Bool( key:String )
		Return _data.Contains( key )
	End
	
	Operator[]:JsonValue( key:String )
		Return _data[key]
	End
	
	Operator[]=( key:String,value:JsonValue )
		_data[key]=value
	End
	
	Method ToObject:StringMap<JsonValue>() Override
		Return Data
	End
	
	Function Load:JsonObject( path:String )
		Local json:=std.stringio.LoadString( path )
		If json Return Parse( json )
		Return Null
	End
	
	Function Parse:JsonObject( json:String )
		Try
			Local parser:=New JsonParser( json )
			Return New JsonObject( parser.ParseObject() )
		Catch ex:JsonError
		End
		Return Null
	End
	
	Private
	
	Field _data:StringMap<JsonValue>

	Method PushJson:Void( buf:StringStack ) Override
		buf.Push( "{" )
		Local t:=False
		For Local it:=Eachin _data
			If t buf.Push( "," )
			buf.Push( "~q"+it.Key.Replace( "~q","\~q" )+"~q:" )
			If it.Value it.Value.PushJson( buf ) Else buf.Push( "null" )
			t=True
		Next
		buf.Push( "}" )
	End
	
End

#rem monkeydoc JsonParser class.
#end
Class JsonParser

	Method New( json:String )
		_text=json
		Bump()
	End
	
	Method ParseValue:JsonValue()
		If TokeType=T_STRING Return New JsonString( ParseString() )
		If TokeType=T_NUMBER Return New JsonNumber( ParseNumber() )
		If Toke="{" Return New JsonObject( ParseObject() )
		If Toke="[" Return New JsonArray( ParseArray() )
		If CParse( "true" ) Return JsonBool.TrueValue
		If CParse( "false" ) Return JsonBool.FalseValue
		If CParse( "null" ) Return Null
		Return Null
	End
	
	Private
	
	Const T_EOF:=0
	Const T_STRING:=1
	Const T_NUMBER:=2
	Const T_SYMBOL:=3
	Const T_IDENT:=4
	
	Field _text:String
	Field _toke:String
	Field _type:Int
	Field _pos:Int
	
	Method GetChar:Int()
		If _pos=_text.Length Throw New JsonError()
		_pos+=1
		Return _text[_pos-1]
	End
	
	Method PeekChar:Int()
		If _pos=_text.Length Return 0
		Return _text[_pos]
	End
	
	Method ParseChar:Void( chr:Int )
		If _pos>=_text.Length Or _text[_pos]<>chr Throw New JsonError()
		_pos+=1
	End
	
	Method CParseChar:Bool( chr:Int )
		If _pos>=_text.Length Or _text[_pos]<>chr Return False
		_pos+=1
		Return True
	End
	
	Method CParseDigits:Bool()
		Local p:=_pos
		While _pos<_text.Length And _text[_pos]>=48 And _text[_pos]<=57
			_pos+=1
		Wend
		Return _pos>p
	End
	
	Method Bump:String()
	
		While _pos<_text.Length And _text[_pos]<=32
			_pos+=1
		Wend
		
		If _pos=_text.Length
			_toke=""
			_type=T_EOF
			Return _toke
		Endif
		
		Local pos:=_pos
		Local chr:=GetChar()
		
		If chr=34
			Repeat
				Local chr:=GetChar()
				If chr=34 Exit
				If chr=92 GetChar()
			Forever
			_type=T_STRING
		Else If chr=39
			Repeat
				Local chr:=GetChar()
				If chr=39 Exit
				If chr=92 GetChar()
			Forever
			_type=T_STRING
		Else If (chr>=48 And chr<=57) Or chr=45
			If chr=45 '-
				chr=GetChar()
				If chr<48 Or chr>57 Throw New JsonError()
			Endif
			If chr<>48 '0
				CParseDigits()
			End
			If CParseChar( 46 )	'.
				CParseDigits()
			Endif
			If CParseChar( 69 ) Or CParseChar( 101 ) 'e E
				If PeekChar()=43 Or PeekChar()=45 GetChar()	'+ -
				If Not CParseDigits() Throw New JsonError()
			Endif
			_type=T_NUMBER
		Else If (chr>=65 And chr<91) Or (chr>=97 And chr<123) Or chr=95
			chr=PeekChar()
			While (chr>=65 And chr<91) Or (chr>=97 And chr<123) Or (chr>=48 And chr<58) Or chr=95
				GetChar()
				chr=PeekChar()
			Wend
			_type=T_IDENT
		Else
			_type=T_SYMBOL
		Endif
		_toke=_text.Slice( pos,_pos )
		Return _toke
	End
	
	Property Toke:String()
		Return _toke
	End
	
	Property TokeType:Int()
		Return _type
	End
	
	Method CParse:Bool( toke:String )
		If toke<>_toke Return False
		Bump()
		Return True
	End
	
	Method Parse:Void( toke:String )
		If Not CParse( toke ) Throw New JsonError()
	End

	Method ParseObject:StringMap<JsonValue>()
		Parse( "{" )
		Local map:=New StringMap<JsonValue>
		If CParse( "}" ) Return map
		Repeat
			Local name:=Toke
			If TokeType=T_IDENT
				Bump()
			Else
				name=ParseString()
			Endif
			Parse( ":" )
			Local value:=ParseValue()
			map.Set( name,value )
		Until Not CParse( "," )
		Parse( "}" )
		Return map
	End
	
	Method ParseArray:Stack<JsonValue>()
		Parse( "[" )
		Local stack:=New Stack<JsonValue>
		If CParse( "]" ) Return stack
		Repeat
			Local value:=ParseValue()
			stack.Add( value )
		Until Not CParse( "," )
		Parse( "]" )
		Return stack
	End
	
	Method ParseString:String()
	
		If TokeType<>T_STRING Throw New JsonError()
		
		Local toke:=Toke.Slice( 1,-1 )
		
		Local i:=toke.Find( "\" )
		If i<>-1
			Local frags:=New StringStack,p:=0,esc:=""
			Repeat
				If i+1>=toke.Length Throw New JsonError()
				frags.Push( toke.Slice( p,i ) )
				Select toke[i+1]
				Case 34  esc="~q"					'\"
				Case 92  esc="\"					'\\
				Case 47  esc="/"					'\/
				Case 98  esc=String.FromChar( 8 )	'\b
				Case 102 esc=String.FromChar( 12 )	'\f
				Case 114 esc=String.FromChar( 13 )	'\r
				Case 110 esc=String.FromChar( 10 )	'\n
				Case 117								'\uxxxx
					If i+6>toke.Length Throw New JsonError()
					Local val:=0
					For Local j:=2 Until 6
						Local chr:=toke[i+j]
						If chr>=48 And chr<58
							val=val Shl 4 | (chr-48)
						Else If chr>=65 And chr<123
							chr&=31
							If chr<1 Or chr>6 Throw New JsonError()
							val=val Shl 4 | (chr+9)
						Else
							Throw New JsonError()
						Endif
					Next
					esc=String.FromChar( val )
					i+=4
				Default 
					Throw New JsonError()
				End
				frags.Push( esc )
				p=i+2
				i=toke.Find( "\",p )
				If i<>-1 Continue
				frags.Push( toke.Slice( p ) )
				Exit
			Forever
			toke=frags.Join( "" )
		Endif
		Bump()
		Return toke
	End
	
	Method ParseNumber:Double()
		If TokeType<>T_NUMBER Throw New JsonError()
		Local toke:=Toke
		Bump()
		Return Double( toke )
	End
	
End
