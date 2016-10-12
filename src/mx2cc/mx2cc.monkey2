
Namespace mx2cc

Using mx2.docs

#Import "<std>"

#Import "mx2"

#Import "docs/docsmaker"
#Import "docs/jsonbuffer"
#Import "docs/minimarkdown"
#Import "docs/markdownbuffer"
#Import "docs/manpage"

#Import "geninfo/geninfo"

Using libc..
Using std..
Using mx2..

Global StartDir:String

'Const TestArgs:="mcx2cc makedocs"

'Const TestArgs:="mx2cc makemods -clean -config=release monkey libc miniz stb-image stb-image-write stb-vorbis std"

'Const TestArgs:="mx2cc makeapp -clean -config=release src/ted2/ted2.monkey2"

'Const TestArgs:="mx2cc makeapp -apptype=console -clean -config=debug -target=desktop -semant -geninfo src/mx2cc/test.monkey2"
Const TestArgs:="mx2cc makeapp -apptype=console -clean -config=debug -target=desktop -parse -geninfo src/mx2cc/translator_cpp.monkey2"

'Const TestArgs:="mx2cc makeapp -clean -config=debug -target=desktop -product=D:/test_app/test.exe -assets=D:/test_app/assets -dlls=D:/test_app/ src/mx2cc/test.monkey2"

'Const TestArgs:="mx2cc makeapp -clean src/ted2/ted2"

'Const TestArgs:="mx2cc makemods -clean -config=release monkey libc miniz stb-image hoedown std"

'Const TestArgs:="mx2cc makeapp -verbose -target=desktop -config=release src/mx2cc/mx2cc"

'To build mx2cc...
'
'Const TestArgs:="mx2cc makeapp -build -clean -apptype=console -config=release src/mx2cc/mx2cc.monkey2"

'To build rasbian mx2cc...
'
'Const TestArgs:="mx2cc makemods -clean -config=release -target=raspbian monkey libc miniz stb-image stb-image-write stb-vorbis std"
'Const TestArgs:="mx2cc makeapp -build -clean -config=release -target=raspbian src/mx2cc/mx2cc.monkey2"

Function Main()

	Print "mx2cc version "+MX2CC_VERSION
	
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

		Print "Usage: mx2cc makeapp|makemods|makedocs [-build|-run] [-clean] [-verbose[=1|2|3]] [-target=desktop|emscripten] [-config=debug|release] [-apptype=gui|console] source|modules..."
		Print "Defaults: -run -target=desktop -config=debug -apptype=gui"

#If __CONFIG__="release"
		exit_(0)
#Endif
		args=TestArgs.Split( " " )
		If args.Length<2 exit_(0)
		
	Endif
	
	Local ok:=False
	
	Try
	
		Local cmd:=args[1]
		args=args.Slice( 2 )
		
		Select cmd
		Case "makeapp"
			ok=MakeApp( args )
		Case "makemods"
			ok=MakeMods( args )
		Case "makedocs"
			ok=MakeDocs( args )
		Default
			Fail( "Unrecognized mx2cc command: '"+cmd+"'" )
		End
		
	Catch ex:BuildEx
	
		Fail( "Internal mx2cc build error" )
	End
	
	If Not ok libc.exit_( 1 )
End

Function MakeApp:Bool( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="app"
	opts.appType="gui"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.verbose=0
	opts.passes=5
	
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

	New BuilderInstance( opts )
	
	Builder.Parse()
	If Builder.errors.Length Return False
	If opts.passes=1 
		If opts.geninfo
			Local gen:=New ParseInfoGenerator
			Local jobj:=gen.GenParseInfo( Builder.mainModule.fileDecls[0] )
			Print jobj.ToJson()
		Endif
		Return True
	Endif
	
	Builder.Semant()
	If Builder.errors.Length Return False
	If opts.passes=2
		Return True
	Endif
	
	Builder.Translate()
	If Builder.errors.Length Return False
	If opts.passes=3 
		Return True
	Endif
	
	Builder.product.Build()
	If Builder.errors.Length Return False
	If opts.passes=4
		Print "Application built:"+Builder.product.outputFile
		Return True
	Endif
	
	Builder.product.Run()
	Return True
End

Function MakeMods:Bool( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="module"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.verbose=0
	opts.passes=4
	
	args=ParseOpts( opts,args )

	If Not args args=EnumModules()
	
	Local errs:=0
	
	Local target:=opts.target
	
	For Local modid:=Eachin args
	
		Local path:="modules/"+modid+"/"+modid+".monkey2"
		
		If GetFileType( path )<>FILETYPE_FILE Fail( "Module file '"+path+"' not found" )
	
		Print ""
		Print "***** Making module '"+modid+"' *****"
		Print ""
		
		opts.mainSource=RealPath( path )
		opts.target=target
		
		New BuilderInstance( opts )
		
		Builder.Parse()
		If Builder.errors.Length errs+=1;Continue
		If opts.passes=1 Continue

		Builder.Semant()
		If Builder.errors.Length errs+=1;Continue
		If opts.passes=2 Continue
		
		Builder.Translate()
		If Builder.errors.Length errs+=1;Continue
		If opts.passes=3 Continue
		
		Builder.product.Build()
		If Builder.errors.Length errs+=1;Continue
	Next
	
	Return errs=0
End

Function MakeDocs:Bool( args:String[] )

	Local opts:=New BuildOpts
	opts.productType="module"
	opts.target="desktop"
	opts.config="debug"
	opts.clean=False
	opts.fast=True
	opts.verbose=0
	opts.passes=2
	
	args=ParseOpts( opts,args )
	
	opts.clean=False
	
	If Not args args=EnumModules()
	
	Local docsMaker:=New DocsMaker
	
	Local errs:=0
	
	For Local modid:=Eachin args

		Local path:="modules/"+modid+"/"+modid+".monkey2"
		If GetFileType( path )<>FILETYPE_FILE Fail( "Module file '"+path+"' not found" )
	
		Print ""
		Print "***** Doccing module '"+modid+"' *****"
		Print ""
		
		opts.mainSource=RealPath( path )
		
		New BuilderInstance( opts )

		Builder.Parse()
		If Builder.errors.Length errs+=1;Continue
		
		Builder.Semant()
		If Builder.errors.Length errs+=1;Continue
		
		docsMaker.MakeDocs( Builder.modules.Top )
	Next
	
	Local api_indices:=New StringStack
	Local man_indices:=New StringStack
	
	For Local modid:=Eachin EnumModules()
	
		Local index:=LoadString( "modules/"+modid+"/docs/__MANPAGES__/index.js" )
		If index man_indices.Push( index )
		
		index=LoadString( "modules/"+modid+"/docs/__PAGES__/index.js" )
		If index api_indices.Push( index )
		
	Next
	
	Local page:=LoadString( "docs/modules_template.html" )
	page=page.Replace( "${API_INDEX}",api_indices.Join( "," ) )
	SaveString( page,"docs/modules.html" )
	
	page=LoadString( "docs/manuals_template.html" )
	page=page.Replace( "${MAN_INDEX}",man_indices.Join( "," ) )
	SaveString( page,"docs/manuals.html" )
	
	Return True
End

Function ParseOpts:String[]( opts:BuildOpts,args:String[] )

	opts.verbose=Int( GetEnv( "MX2_VERBOSE" ) )

	For Local i:=0 Until args.Length
	
		Local arg:=args[i]
	
		Local j:=arg.Find( "=" )
		If j=-1 
			Select arg
			Case "-run"
				opts.passes=5
			Case "-build"
				opts.passes=4
			Case "-translate"
				opts.passes=3
			Case "-semant"
				opts.passes=2
			Case "-parse"
				opts.passes=1
			Case "-clean"
				opts.clean=True
			Case "-verbose"
				opts.verbose=1
			Case "-geninfo"
				opts.geninfo=True
			Default
				Return args.Slice( i )
			End
			Continue
		Endif
		
		Local opt:=arg.Slice( 0,j ),val:=arg.Slice( j+1 )
		
		Local path:=val.Replace( "\","/" )
		If path.StartsWith( "~q" ) And path.EndsWith( "~q" ) path=path.Slice( 1,-1 )
		
		val=val.ToLower()
		
		Select opt
		Case "-product"
			opts.product=path
		Case "-assets"
			opts.assets=path
		Case "-dlls"
			opts.dlls=path
		Case "-apptype"
			Select val
			Case "gui","console"
				opts.appType=val
			Default
				Fail( "Invalid value for 'apptype' option: '"+val+"' - must be 'gui' or 'console'" )
			End
		Case "-target"
			Select val
			Case "desktop","windows","macos","linux","raspbian","emscripten","android","ios"
				opts.target=val
			Default
				Fail( "Invalid value for 'target' option: '"+val+"' - must be 'desktop', 'raspbian', 'emscripten', 'android' or 'ios'" )
			End
		Case "-config"
			Select val
			Case "debug","release"
				opts.config=val
			Default
				Fail( "Invalid value for 'config' option: '"+val+"' - must be 'debug' or 'release'" )
			End
		Case "-verbose"
			Select val
			Case "0","1","2","3","-1"
				opts.verbose=Int( val )
			Default
				Fail( "Invalid value for 'verbose' option: '"+val+"' - must be '0', '1', '2', '3' or '-1'" )
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

Function LoadEnv:Bool( path:String )

	SetEnv( "MX2_HOME",CurrentDir() )
	SetEnv( "MX2_MODULES",CurrentDir()+"modules" )

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
		
	exit_( 1 )
End
