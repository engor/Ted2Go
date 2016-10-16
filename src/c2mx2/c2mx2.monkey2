
#rem

A very much WIP C->MX2 'Extern' generator based on 'libclang'. However, it did libclang itself and chipmunk nicely.

This wont work 'as is' - you'll need to copy LLVM binaries to this dir (inside a LLVM dir). LLVM binaries are here:

http://llvm.org/releases/download.html

You'll probably also need mingw-64 in your system PATH.

Use 32 bit binaries for Windows.

Only tested on Windows.

#end

#Import "<libc>"
#Import "<std>"

#Import "libclang_extern.monkey2"

Using libc..
Using std..
Using libclang..

Global tab:String
Global buf:=New StringStack

Global CurrentFile:String

Global params:String
Global enumid:String

Global AnonEnumType:="Int"
Global LongType:="Long"
Global ULongType:="ULong"
Global LongLongType:="Long"
Global ULongLongType:="ULong"

Global IncludeFiles:StringMap<Bool>
Global ExcludeFiles:StringMap<Bool>

Global ext_structs:=New StringMap<Bool>
Global def_structs:=New StringMap<Bool>

Global Keywords:StringMap<String>

Function InitKeywords()
	If Keywords Return 
	
	Keywords=New StringMap<String>
	
	Local kws:=""

	kws+="Namespace;Using;Import;Extern;"
	kws+="Public;Private;Protected;Friend;"
	kws+="Void;Bool;Byte;UByte;Short;UShort;Int;UInt;Long;ULong;Float;Double;String;Object;Continue;Exit;"
	kws+="New;Self;Super;Eachin;True;False;Null;Where;"
	kws+="Alias;Const;Local;Global;Field;Method;Function;Property;Getter;Setter;Operator;Lambda;"
	kws+="Enum;Class;Interface;Struct;Protocol;Extends;Implements;Virtual;Override;Abstract;Final;Inline;"
	kws+="Var;Varptr;Ptr;"
	kws+="Not;Mod;And;Or;Shl;Shr;End;"
	kws+="If;Then;Else;Elseif;Endif;"
	kws+="While;Wend;"
	kws+="Repeat;Until;Forever;"
	kws+="For;To;Step;Next;"
	kws+="Select;Case;Default;"
	kws+="Try;Catch;Throw;Throwable;"
	kws+="Return;Print;Static;Cast;Extension"
	
	For Local kw:=Eachin kws.Split( ";" )
		Keywords[kw.ToLower()]=kw
	Next
End

Struct CXString Extension
	Method To:String()
		Return ToString( Self )
	End
End

Function ToString:String( str:CXString )
	Local p:=clang_getCString( str )
	Local t:=String.FromCString( p )
	clang_disposeString( str )
	Return t
End

Function ToCString:const_char_t Ptr( str:String )
	Local n:=str.Length+1
	Local buf:=Cast<Byte Ptr>( malloc( n ) )
	str.ToCString( buf,n )
	Return Cast<const_char_t Ptr>( buf )
End

Function ErrInfo:String( cursor:CXCursor )
	Local srcloc:=clang_getCursorLocation( cursor )
	Local file:CXFile,line:UInt
	clang_getFileLocation( srcloc,Varptr file,Varptr line,Null,Null )
	Local str:=clang_getFileName( file )
	Return String( str )+" ["+line+"]"
End

Function Err( err:String,cursor:CXCursor )
	Print ErrInfo( cursor )+" : "+err
End

Function TypeName:String( type:CXType )

	Local ctype:=String( clang_getTypeSpelling( type ) )
	If ctype.Contains( "(anonymous" ) Return ""
	
	If ctype.StartsWith( "const " ) 
	
		ctype=ctype.Slice( 6 )
		If ctype.EndsWith( " &" ) ctype=ctype.Slice( 0,-2 )
		
	Else If ctype.EndsWith( " &" )
	
		Print "Error: non-const reference type"
		Return ""
	Endif
	
	If ctype.StartsWith( "struct " )
		ctype=ctype.Slice( 7 )
	Else If ctype.StartsWith( "union " )
		ctype=ctype.Slice( 6 )
	Else If ctype.StartsWith( "enum " )
		ctype=ctype.Slice( 5 )
	Endif

	If Keywords.Contains( ctype ) ctype+="_"
	
	Return ctype
End

Function TransType:String( type:CXType )

	Select type.kind
	
	Case CXType_Void Return "Void"
	
	Case CXType_Char_S,CXType_Char_U Return clang_isConstQualifiedType( type ) ? "libc.const_char_t" Else "libc.char_t"
	
	Case CXType_SChar Return "Byte"
	
	Case CXType_UChar Return "UByte"
	
	Case CXType_Bool Return "Bool"
	
	Case CXType_Short Return "Short"
	
	Case CXType_UShort Return "UShort"
	
	Case CXType_Int Return "Int"
	
	Case CXType_UInt Return "UInt"
	
	Case CXType_Float Return "Float"
	
	Case CXType_Double Return "Double"
	
	Case CXType_Long Return LongType
	
	Case CXType_ULong Return ULongType
	
	Case CXType_LongLong Return LongLongType
	
	Case CXType_ULongLong Return ULongLongType
	
	Case CXType_Typedef return TypeName( type )
	
	Case CXType_Enum Return TypeName( type )
	
	Case CXType_Record Return TypeName( type )
	
	Case CXType_Elaborated Return TransType( clang_Type_getNamedType( type ) )
	
	Case CXType_Pointer 
	
		Local ptype:=TransType( clang_getPointeeType( type ) )
		If ptype
			If ptype.EndsWith( ")" ) ptype+=" " Else ptype+=" Ptr"
			Return ptype
		Endif
	
	Case CXType_ConstantArray	'naughty!
	
		Local ptype:=TransType( clang_getElementType( type ) )
		If ptype Return ptype+" Ptr"
	
	Case CXType_IncompleteArray 
	
		Local ptype:=TransType( clang_getElementType( type ) )
		If ptype Return ptype+" Ptr"
	
'	Case CXType_LValueReference		'C++ time!
	
'		If clang_isConstQualifiedType( type ) Return TypeName( type )

	Case CXType_Unexposed
	
		Local ctype:=clang_getCanonicalType( type )
		
		If ctype.kind=CXType_FunctionProto
		
			Local retType:=TransType( clang_getResultType( ctype ) )
			
			Local n:=clang_getNumArgTypes( type ),args:=""

			For Local i:=0 Until n
				If i args+=", "
				args+=TransType( clang_getArgType( type,i ) )
			Next
			
			Return retType+"( "+args+" )"
		Endif
		
	End
	
'	Print "Unknown CXType:"+clang_getTypeSpelling( type )+", CXTypeKind="+Int( type.kind )
	
	Return ""
End

Function TransType:String( cursor:CXCursor )

	Return TransType( clang_getCursorType( cursor ) )
End

Function DeclName:String( cursor:CXCursor )

	Local id:=String( clang_getCursorSpelling( cursor ) )
	
	If Keywords.Contains( id ) id+="_"
	
	Return id
End

Function TypeName:String( cursor:CXCursor )

	Return TypeName( clang_getCursorType( cursor ) )
End

Function VisitFunc:CXChildVisitResult( cursor:CXCursor,parent:CXCursor,client_data:CXClientData )

	Select clang_getCursorKind( cursor )

	Case CXCursor_ParmDecl

		Local id:=DeclName( cursor )

		Local type:=TransType( cursor )

		If Not type
			params="?"
			Return CXChildVisit_Break
		Endif

		If type="libc.char_t Ptr" Or type="libc.const_char_t Ptr" type="CString"

		If params params+=", "
		If id params+=id+":"+type Else params+=type
	End
	
	Return CXChildVisit_Continue
End

Function VisitEnum:CXChildVisitResult( cursor:CXCursor,parent:CXCursor,client_data:CXClientData )

	Select clang_getCursorKind( cursor )

	Case CXCursor_EnumConstantDecl
	
		buf.Push( tab+"Const "+DeclName( cursor )+":"+enumid )
	
	End
	
	Return CXChildVisit_Continue
End

Function SetFile( file:String )
	If file=CurrentFile Return
	CurrentFile=file
	buf.Push( "~n'***** File: "+CurrentFile+" *****~n" )
End

Function VisitMembers:CXChildVisitResult( cursor:CXCursor,parent:CXCursor,client_data:CXClientData )

	Local srcloc:=clang_getCursorLocation( cursor )
	Local cfile:CXFile,line:UInt
	clang_getFileLocation( srcloc,Varptr cfile,Varptr line,Null,Null )
	Local file:=String( clang_getFileName( cfile ) )
	
	If IncludeFiles
		If Not IncludeFiles.Contains( StripDir( file ) ) Return CXChildVisit_Continue
	Else If ExcludeFiles
		If ExcludeFiles.Contains( StripDir( file ) ) Return CXChildVisit_Continue
	Endif
	
	Select clang_getCursorKind( cursor )
	
	Case CXCursor_EnumDecl

		Local id:=TransType( cursor )
		If id
			SetFile( file )
			buf.Push( tab+"Enum "+id+"~nEnd" )
			enumid=id
		Else
			enumid=AnonEnumType
		Endif
			
		clang_visitChildren( cursor,VisitEnum,Null )
		enumid=""
				
	Case CXCursor_StructDecl
	
		Local id:=TransType( cursor )
		
		If id
			If clang_isCursorDefinition( cursor )

				SetFile( file )
				buf.Push( tab+"Struct "+id )
			
				tab+="~t"
				clang_visitChildren( cursor,VisitMembers,Null )
				tab=tab.Slice( 0,-1 )
					
				buf.Push( tab+"End" )
			
				def_structs[id]=True
			Else
				ext_structs[id]=True
			Endif
		Else
			Err( "Ignoring anonymous struct",cursor )
		Endif
	
	Case CXCursor_UnionDecl

		Local id:=TransType( cursor )
			
		If id
			If clang_isCursorDefinition( cursor )
			
				SetFile( file )
				buf.Push( tab+"Struct "+id )
				buf.Push( tab+"End" )
				
				Err( "***** Union "+id+" converted to empty struct *****",cursor )

				def_structs[id]=True
			Else
				ext_structs[id]=True
			Endif
		Else
			Err( "Ignoring anonymous union",cursor )
		Endif
	
	Case CXCursor_TypedefDecl
	
		Local id:=DeclName( cursor )

		Local type:=TransType( clang_getTypedefDeclUnderlyingType( cursor ) )
		
		If type 
			If type<>id
				SetFile( file )
				buf.Push( tab+"Alias "+id+":"+type )
			Endif
		Else
			Err( "Failed to convert type for typedef: "+id,cursor )
		Endif
	
	Case CXCursor_FunctionDecl

		Local id:=DeclName( cursor )
	
		Local ftype:=clang_getCursorType( cursor )
		
		Local retType:=TransType( clang_getResultType( ftype ) )
		
		If retType

			params=""		
			clang_visitChildren( cursor,VisitFunc,Null )
			
			If params<>"?"
				SetFile( file )
				buf.Push( tab+"Function "+id+":"+retType+"( "+params+" )" )
			Else
				Err( "Failed to convert params for function: "+id,cursor )
			Endif
		Else
			Err( "Failed to convert return type for function: "+id,cursor )
		Endif
		
	Case CXCursor_VarDecl
	
		Local id:=DeclName( cursor )
		
		Local type:=TransType( cursor )
		
		If type
			SetFile( file )
			buf.Push( "Global "+id+":"+type )
		Else
			Err( "Failed to convert type for var: "+id,cursor )
		Endif
		
	Case CXCursor_FieldDecl

		Local id:=DeclName( cursor )
		Local type:=TransType( cursor )
		
		If type
			buf.Push( tab+"Field "+id+":"+type )
		Else
			Err( "Failed to convert type of field: "+id,cursor )
		Endif
	
	End
	
	Return CXChildVisit_Continue
End

Function VisitAll:CXChildVisitResult( cursor:CXCursor,parent:CXCursor,client_data:CXClientData )

	Local ctype:=clang_getCursorType( cursor )

	Print tab+clang_getCursorSpelling( cursor )+":"+clang_getTypeSpelling( ctype )+", cursor kind="+Int( cursor.kind )+", type kind="+Int( ctype.kind )
	
	tab+="~t"
	clang_visitChildren( cursor,VisitAll,Null )
	tab=tab.Slice( 0,-1 )

	Return CXChildVisit_Continue
End

Function Main()

	ChangeDir( AppDir() )
	
	While GetFileType( "bin" )<>FileType.Directory Or GetFileType( "modules" )<>FileType.Directory

		If IsRootDir( CurrentDir() )
			Print "Error initializing c2mx2 - can't find working dir!"
			libc.exit_( 1 )
		Endif
		
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend

	Local config:=JsonObject.Load( "src/c2mx2/chipmunk_c2mx2.json" )

	'change to working dir
	If config.Contains( "workingDir" ) 
		ChangeDir( config.GetString( "workingDir" ) )
	Endif
	
	'clang args
	Local cargs:=config.GetArray( "clangArgs" )
	Local args:=New const_char_t Ptr[ cargs.Length]
	For Local i:=0 Until args.Length
		args[i]=ToCString( cargs[i].ToString() )
	Next

	'input file
	Local file:=config.GetString( "inputFile" )

	'include/exclude files
	If config.Contains( "includeFiles" )
		IncludeFiles=New StringMap<Bool>
		For Local file:=Eachin config.GetArray( "includeFiles" )
			IncludeFiles[file.ToString()]=True
		Next
	Else If config.Contains( "excludeFiles" )
		ExcludeFiles=New StringMap<Bool>
		For Local file:=Eachin config.GetArray( "excludeFiles" )
			ExcludeFiles[file.ToString()]=True
		Next
	Endif
	
	'anonymous enum type
	If config.Contains( "anonEnumType" )
		AnonEnumType=config.GetString( "anonEnumType" )
	Endif

	'start clang	
	Local index:=clang_createIndex( 1,1 )
	
	Local tu:=clang_createTranslationUnitFromSourceFile( index,file,2,args.Data,0,Null )
	Assert( tu,"Failed to create translation unit from source file" )
	
	'emit header
	Local header:=config.GetArray( "header" )
	For Local line:=Eachin header
		buf.Push( line.ToString() )
	Next
	
	'Let's GO!
	InitKeywords()
	
	Local cursor:=clang_getTranslationUnitCursor( tu )
	
	clang_visitChildren( cursor,VisitMembers,Null )

	'emit extern structs	
	buf.Push( "~n'***** Extern Structs *****~n" )
	For Local id:=Eachin ext_structs.Keys
		If def_structs[id] Continue
		
		buf.Push( "Struct "+id )
		buf.Push( "End" )
	Next
	
	'emit footer
	If config.Contains( "footer" )
		Local footer:=config.GetArray( "footer" )
		For Local line:=Eachin footer
			buf.Push( line.ToString() )
		Next
	Endif

	'emit output	
	Local output:=config.GetString( "outputFile" )
	If output
		SaveString( buf.Join( "~n" ),output )
	Else
		Print buf.Join( "~n" )
	Endif

End
