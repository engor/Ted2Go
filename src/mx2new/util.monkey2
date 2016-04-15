
Namespace mx2

#If __HOSTOS__="macos"
Const HostOS:="macos"
#Elseif __HOSTOS__="winnt"
Const HostOS:="windows"
#Elseif __HOSTOS__="windows"
Const HostOS:="windows"
#Elseif __HOSTOS__="linux"
Const HostOS:="linux"
#Endif

Const CHAR_EOL:=10
Const CHAR_TAB:=9
Const CHAR_RETURN:=13
Const CHAR_HASH:=35
Const CHAR_QUOTE:=34
Const CHAR_PLUS:=43
Const CHAR_MINUS:=45
Const CHAR_DOT:=46
Const CHAR_UNDERSCORE:=95
Const CHAR_APOSTROPHE:=39
Const CHAR_DOLLAR:=36
Const CHAR_TILDE:=126
Const CHAR_BACKSLASH:=92

Global STRING_BACKSLASH:=String.FromChar( CHAR_BACKSLASH )
Global STRING_TILDE:=String.FromChar( CHAR_TILDE )
Global STRING_QUOTE:=String.FromChar( CHAR_QUOTE )
Global STRING_EOL:=String.FromChar( CHAR_EOL )
Global STRING_RETURN:=String.FromChar( CHAR_RETURN )
Global STRING_TAB:=String.FromChar( CHAR_TAB )

Global STRING_CPPBACKSLASH:=STRING_BACKSLASH+STRING_BACKSLASH
Global STRING_CPPQUOTE:=STRING_BACKSLASH+STRING_QUOTE
Global STRING_CPPEOL:=STRING_BACKSLASH+"n"
Global STRING_CPPRETURN:=STRING_BACKSLASH+"r"
Global STRING_CPPTAB:=STRING_BACKSLASH+"t"

Global STRING_MX2TILDE:=STRING_TILDE+STRING_TILDE
Global STRING_MX2QUOTE:=STRING_TILDE+"q"
Global STRING_MX2EOL:=STRING_TILDE+"n"
Global STRING_MX2RETURN:=STRING_TILDE+"r"
Global STRING_MX2TAB:=STRING_TILDE+"t"

Function MungPath:String( path:String )
	Local id:=path
	id=id.Replace( "_","_0" )
	id=id.Replace( "../","_1" )
	id=id.Replace( "/","_2" )
	id=id.Replace( ":","_3" )
	id=id.Replace( " ","_4" )
	id=id.Replace( "-","_5" )
	Return id
End

Function GetEnv:String( name:String )
	Local p:=getenv( name )
	If p Return String.FromCString( p )
	Return ""
End

Function SetEnv( name:String,value:String )
	setenv( name,value,1 )
End

Function CSaveString( str:String,path:String )
	Local t:=stringio.LoadString( path )
	If t<>str stringio.SaveString( str,path )
End

Function MakeRelativePath:String( path:String,baseDir:String )

'	Print "MakeRelativepath("+path+","+baseDir+")"

	While baseDir.EndsWith( "/" )
		baseDir=baseDir.Slice( 0,-1 )
	Wend
	baseDir+="/"

	Local relpath:=""

	While Not path.StartsWith( baseDir )
		Local tdir:=baseDir
		baseDir=ExtractDir( baseDir )
		If baseDir=tdir 
			Print "MakeRelativePath Error! baseDir="+baseDir
			Return path
		Endif
		relpath="../"+relpath
	Wend
	
	relpath+=path.Slice( baseDir.Length )
	
'	Print "Result="+relpath
	
	Return relpath
End

Function ToStrings<T>:String[]( bits:T[] )
	Local strs:=New String[bits.Length]
	For Local i:=0 Until strs.Length
		If bits[i] strs[i]=bits[i].ToString()
	Next
	Return strs
End

Function Join<T>:String( bits:T[],sep:String="," )
	Return sep.Join( ToStrings( bits ) )
End

Function SemantRValues:Value[]( exprs:Expr[],scope:Scope )

	Local args:=New Value[exprs.Length]
	For Local i:=0 Until args.Length
		If exprs[i] args[i]=exprs[i].SemantRValue( scope )
	Next
	
	Return args
End

Function SemantArgs:Value[]( exprs:Expr[],scope:Scope )

	Local args:=New Value[exprs.Length]
	For Local i:=0 Until args.Length
		If exprs[i] args[i]=exprs[i].Semant( scope )
	Next
	Return args
End

Function UpCast:Value[]( args:Value[],type:Type )

	args=args.Slice( 0 )
	For Local i:=0 Until args.Length
		If args[i] args[i]=args[i].UpCast( type )
	Next
	Return args
End

Function Types:Type[]( args:Value[] )

	Local types:=New Type[args.Length]
	For Local i:=0 Until types.Length
		If args[i] types[i]=args[i].type
	Next
	Return types
End

Function TypesEqual:Bool( lhs:Type[],rhs:Type[] )

	If lhs.Length<>rhs.Length Return False
	
	For Local i:=0 Until lhs.Length
		If Not lhs[i].Equals( rhs[i] ) Return False
	Next
	
	Return True
End

Function AnyTypeGeneric:Bool( types:Type[] )

	For Local type:=Eachin types
		If type.IsGeneric Return True
	Next
	
	Return False
End

Function AllTypesGeneric:Bool( types:Type[] )

	For Local type:=Eachin types
		If Not type.IsGeneric Return False
	Next
	
	Return True
End

Function DequoteMx2String:String( str:String )

	If str.Length<2 Or str[0]<>CHAR_QUOTE Or str[str.Length-1]<>CHAR_QUOTE
		Print "MX2 string error:"+str
		Return str
	Endif
	
	str=str.Slice( 1,-1 )
	
	str=str.Replace( STRING_MX2TILDE,STRING_TILDE )
	str=str.Replace( STRING_MX2QUOTE,STRING_QUOTE )
	str=str.Replace( STRING_MX2EOL,STRING_EOL )
	str=str.Replace( STRING_MX2RETURN,STRING_RETURN )
	str=str.Replace( STRING_MX2TAB,STRING_TAB )
	
	Return str
End

Function EnquoteCppString:String( str:String )

	str=str.Replace( STRING_BACKSLASH,STRING_CPPBACKSLASH )
	str=str.Replace( STRING_QUOTE,STRING_CPPQUOTE )
	str=str.Replace( STRING_EOL,STRING_CPPEOL )
	str=str.Replace( STRING_RETURN,STRING_CPPRETURN )
	str=str.Replace( STRING_TAB,STRING_CPPTAB )
	
	Return STRING_QUOTE+str+STRING_QUOTE
End
