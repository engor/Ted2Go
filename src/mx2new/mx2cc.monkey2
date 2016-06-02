
Namespace mx2cc

Using mx2.docs

#Import "<hoedown>"
#Import "<std>"

#Import "mx2.monkey2"

#Import "docsmaker.monkey2"
#Import "htmldocsmaker.monkey2"

Using libc..
Using std..
Using mx2..

Global StartDir:String

'Const TestArgs:="mx2cc makemods"

Const TestArgs:="mx2cc makedocs std"

'Const TestArgs:="mx2cc makeapp src/mx2new/test.monkey2"

'Const TestArgs:="mx2cc makemods -clean -config=release monkey libc miniz stb-image hoedown std"

'Const TestArgs:="mx2cc makeapp -verbose -target=desktop -config=release src/mx2new/mx2cc.monkey2"

Function Main()

	Print "MX2CC V0."+MX2CC_VERSION

	StartDir=CurrentDir()

	ChangeDir( AppDir() )
		
	Local env:="bin/env_"+HostOS+".txt"
	
	While Not IsRootDir( CurrentDir() ) And GetFileType( env )<>FILETYPE_FILE
	
		ChangeDir( ExtractDir( CurrentDir() ) )
	Wend
	
	If GetFileType( env )<>FILETYPE_FILE Fail( "Unable to locate mx2cc 'bin' directory" )
	
	LoadEnv( env )
	
	Local args:=AppArgs()
	
	If args.Length<2

		Print "Usage: mx2cc makeapp|makemods|makedocs [-run] [-clean] [-verbose] [-target=desktop|emscripten] [-config=debug|release] source|modules..."

#If __CONFIG__="release"
		exit_(0)
#Endif
		args=TestArgs.Split( " " )
		
	Endif
	
	Try
	
		Local cmd:=args[1]
		args=args.Slice( 2 )
		
		Select cmd
		Case "makeapp"
			MakeApp( args )
		Case "makemods"
			MakeMods( args )
		Case "makedocs"
			MakeDocs( args )
		Default
			Fail( "Unrecognized mx2cc command: '"+cmd+"'" )
		End
		
	Catch ex:BuildEx
	
		Fail( "Build error." )
		
	End
	
End

Function MakeApp( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="app"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.run=True
	opts.verbose=0
	
	args=ParseOpts( opts,args )
	
	If args.Length<>1 Fail( "Invalid app source file" )
	
	Local cd:=CurrentDir()
	ChangeDir( StartDir )
	Local srcPath:=RealPath( args[0].Replace( "\","/" ) )
	ChangeDir( cd )
	
	opts.mainSource=srcPath
	
	Print ""
	Print "***** Building app '"+opts.mainSource+"' *****"
	Print ""

	Local builder:=New Builder( opts )
	
	builder.Parse()
	If builder.errors.Length Return
	
	builder.Semant()
	If builder.errors.Length Return
	
	builder.Translate()
	If builder.errors.Length Return

	builder.Compile()
	If builder.errors.Length Return

	Local app:=builder.Link()
	If builder.errors.Length Return
	
	If Not opts.run Print "Application built:"+app
End

Function MakeMods( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="module"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.verbose=0
	
	args=ParseOpts( opts,args )

	If Not args args=EnumModules()
	
	For Local modid:=Eachin args
	
		Local path:="modules/"+modid+"/"+modid+".monkey2"
		If GetFileType( path )<>FILETYPE_FILE Fail( "Module file '"+path+"' not found" )
	
		Print ""
		Print "***** Making module '"+modid+"' *****"
		Print ""
		
		opts.mainSource=RealPath( path )
		
		Local builder:=New Builder( opts )
		
		builder.Parse()
		If builder.errors.Length Continue

		builder.Semant()
		If builder.errors.Length Continue
		
		builder.Translate()
		If builder.errors.Length Continue
		
		builder.Compile()
		If builder.errors.Length Continue

		builder.Link()
	Next
End

Function MakeDocs( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="module"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.verbose=0
	
	args=ParseOpts( opts,args )
	opts.clean=False
	
	If Not args args=EnumModules()
	
	Local docsMaker:=New HtmlDocsMaker
	
	Local mx2_api:=""
	
	For Local modid:=Eachin args

		Local path:="modules/"+modid+"/"+modid+".monkey2"
		If GetFileType( path )<>FILETYPE_FILE Fail( "Module file '"+path+"' not found" )
	
		Print ""
		Print "***** Doccing module '"+modid+"' *****"
		Print ""
		
		opts.mainSource=RealPath( path )
		
		Local builder:=New Builder( opts )

		builder.Parse()
		If builder.errors.Length Continue
		
		builder.Semant()
		If builder.errors.Length Continue
		
		Local tree:=docsMaker.MakeDocs( builder.modules.Top )
		
		If mx2_api mx2_api+=","
		mx2_api+=tree

	Next
	
	Local index:=stringio.LoadString( "docs/modules_template.html" )
	index=index.Replace( "${MX2_API}",mx2_api )
	stringio.SaveString( index,"docs/modules.html" )

End

Function ParseOpts:String[]( opts:BuildOpts,args:String[] )

	opts.verbose=Int( GetEnv( "MX2_VERBOSE" ) )

	For Local i:=0 Until args.Length
	
		Local arg:=args[i]
	
		Local j:=arg.Find( "=" )
		If j=-1 
			Select arg
			Case "-run"
				opts.run=True
			Case "-build"
				opts.run=False
			Case "-clean"
				opts.clean=True
			Case "-verbose"
				opts.verbose=1
			Default
				Return args.Slice( i )
			End
			Continue
		Endif
		
		Local opt:=arg.Slice( 0,j ),val:=arg.Slice( j+1 ).ToLower()
		
		Select opt
		Case "-target"
			Select val
			Case "desktop","emscripten"
				opts.target=val
			Default
				Fail( "Invalid value for 'target' option: '"+val+"'" )
			End
		Case "-config"
			Select val
			Case "debug","release"
				opts.config=val
			Default
				Fail( "Invalid value for 'config' option: '"+val+"'" )
			End
		Case "-verbose"
			Select val
			Case "0","1","2","-1"
				opts.verbose=Int( val )
			Default
				Fail( "Invalid value for 'verbose' option: '"+val+"'" )
			End
		Default
			Fail( "Invalid option: '"+opt+"'" )
		End
	
	Next
	
	Return Null
End

Function EnumModules( out:StringStack,cur:String,deps:StringMap<StringStack> )
	If out.Contains( cur ) Return
	
	For Local dep:=Eachin deps[cur]
		EnumModules( out,dep,deps )
	Next
	
	out.Push( cur )
End

Function EnumModules:String[]()

	Local mods:=New StringMap<StringStack>

	For Local f:=Eachin LoadDir( "modules" )
	
		Local dir:="modules/"+f+"/"
		If GetFileType( dir )<>FileType.Directory Continue
		
		Local str:=LoadString( dir+"module.json" )
		If Not str Continue
		
		Local obj:=JsonObject.Parse( str )
		If Not obj 
			Print "Error parsing json:"+dir+"module.json"
			Continue
		Endif
		
		Local name:=obj["module"].ToString()
		If name<>f Continue
		
		Local deps:=New StringStack
		If name<>"monkey" deps.Push( "monkey" )
		
		Local jdeps:=obj["depends"]
		If jdeps
			For Local dep:=Eachin jdeps.ToArray()
				deps.Push( dep.ToString() )
			Next
		Endif
		
		mods[name]=deps
	Next
	
	Local out:=New StringStack
	For Local cur:=Eachin mods.Keys
		EnumModules( out,cur,mods )
	Next
	
	Return out.ToArray()
End

#rem
Function EnumModules:String[]()

	Local mods:=New StringStack
	
	For Local line:=Eachin stringio.LoadString( "modules/modules.txt" ).Split( "~n" )
	
		Local i:=line.Find( "'" )
		If i<>-1 line=line.Slice( 0,i )
		
		line=line.Trim()
		If line mods.Push( line )
		
	Next
	
	Return mods.ToArray()
End
#end

Function LoadEnv:Bool( path:String )

	SetEnv( "MX2_HOME",CurrentDir() )

	Local lineid:=0
	
	For Local line:=Eachin stringio.LoadString( path ).Split( "~n" )
		lineid+=1
	
		Local i:=line.Find( "'" )
		If i<>-1 line=line.Slice( 0,i )
		
		line=line.Trim()
		If Not line Continue
		
		i=line.Find( "=" )
		If i=-1 Fail( "Env config file error at line "+lineid )
		
		Local name:=line.Slice( 0,i ).Trim()
		Local value:=line.Slice( i+1 ).Trim()
		
		value=ReplaceEnv( value,lineid )
		
		SetEnv( name,value )

	Next
	
	Return True
End

Function ReplaceEnv:String( str:String,lineid:Int )
	Local i0:=0
	Repeat
		Local i1:=str.Find( "${",i0 )
		If i1=-1 Return str
		
		Local i2:=str.Find( "}",i1+2 )
		If i2=-1 Fail( "Env config file error at line "+lineid )
		
		Local name:=str.Slice( i1+2,i2 ).Trim()
		Local value:=GetEnv( name )
		
		str=str.Slice( 0,i1 )+value+str.Slice( i2+1 )
		i0=i1+value.Length
	Forever
	Return ""
End

Function Fail( msg:String )

	Print ""
	Print "***** Fatal mx2cc error *****"
	Print ""
	Print msg
		
	exit_( -1 )
End
