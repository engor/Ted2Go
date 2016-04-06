
Namespace mx2

Class BuildOpts

	Field mainSource:String
	
	Field productType:String
	
	Field target:String
	
	Field config:String

	Field clean:Bool
	
	Field verbose:Int
	
	Field fast:Bool
	
	Field run:Bool
	
End

Class Builder

	Global instance:Builder
	
	Field errors:=New Stack<ErrorEx>

	Field opts:BuildOpts
	
	Field modulesDir:String

	Field profileName:String
	
	Field ppsyms:=New StringMap<String>

	Field mainModule:Module
	
	Field parsingModule:Module
	
	Field modules:=New Stack<Module>
	
	Field modulesMap:=New StringMap<Module>
	
	Field rootNamespace:NamespaceScope
	
	Field monkeyNamespace:NamespaceScope
	
	Field semantingModule:Module
	
	Field semantStmts:=New Stack<FuncValue>
	
	Field semantMembers:=New List<ClassType>
	
	Field imported:=New StringMap<Bool>
	
	Field currentDir:String

	
	Field tmpId:Int
	
	Field maxObjTime:Long

	Field MX2_SRCS:=New StringStack
	Field MX2_LIBS:=New StringStack
	
	Field SRC_FILES:=New StringStack
	Field OBJ_FILES:=New StringStack
	Field LD_OPTS:=New StringStack	
	Field CC_OPTS:=New StringStack
	Field CPP_OPTS:=New StringStack
	Field LD_LIBS:=New StringStack
	Field LD_SYSLIBS:=New StringStack
	Field DLL_FILES:=New StringStack
	Field ASSET_FILES:=New StringStack
	
	Field AR_CMD:="ar"
	Field CC_CMD:="gcc"
	Field CXX_CMD:="g++"
	Field LD_CMD:="g++"
	
	Method New( opts:BuildOpts )
	
'		If instance Print "OOPS! There is already a builder instance!"
		
		Self.opts=opts

		instance=Self
		
		Local copts:=""
		
		copts=GetEnv( "MX2_LD_OPTS_"+opts.target.ToUpper() )
		If copts LD_OPTS.Push( copts )

		copts=GetEnv( "MX2_LD_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts LD_OPTS.Push( copts )
		
		copts=GetEnv( "MX2_CC_OPTS_"+opts.target.ToUpper() )
		If copts CC_OPTS.Push( copts )
		
		copts=GetEnv( "MX2_CC_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts CC_OPTS.Push( copts )
		
		copts=GetEnv( "MX2_CPP_OPTS_"+opts.target.ToUpper() )
		If opts CPP_OPTS.Push( copts )
		
		copts=GetEnv( "MX2_CPP_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts CPP_OPTS.Push( copts )
		
		Select opts.target
		Case "desktop"
			AR_CMD="ar"
			CC_CMD="gcc"
			CXX_CMD="g++"
			LD_CMD="g++"
		Case "emscripten"
			AR_CMD="emar"
			CC_CMD="emcc"
			CXX_CMD="em++"
			LD_CMD="em++"
		End
		
		ppsyms["__HOSTOS__"]="~q"+HostOS+"~q"
		ppsyms["__TARGET__"]="~q"+opts.target+"~q"
		ppsyms["__CONFIG__"]="~q"+opts.config+"~q"
'		ppsyms["__CONFIG__"]="~qmx2new~q"
		
		profileName=opts.target+"_"+opts.config+"_"+HostOS
		
		modulesDir=RealPath( "modules" )+"/"
		
		ClearPrimTypes()
		
		rootNamespace=New NamespaceScope( Null,Null )
		
		monkeyNamespace=GetNamespace( "monkey" )
		
	End
	
	Method Parse()
	
		If opts.verbose=0 Print "Parsing..."
		
		Local name:=StripDir( StripExt( opts.mainSource ) )

		Local module:=New Module( name,opts.mainSource,opts.productType,MX2_PRODUCT_VERSION )
		modulesMap[name]=module
		modules.Push( module )
		
		mainModule=module
		If name="monkey" And module.productType="module" modulesMap["monkey"]=module
		
		If opts.clean 
			DeleteDir( module.outputDir,True )
			DeleteDir( module.cacheDir,True )
		Endif
		
		parsingModule=module
		MX2_SRCS.Push( module.srcPath )
		
		Repeat
		
			If MX2_SRCS.Empty
			
				parsingModule=Null
			
				If MX2_LIBS.Empty
				
					If modulesMap["monkey"] Exit
					
					MX2_LIBS.Push( "monkey" )
				Endif
				
				Local name:=MX2_LIBS.Pop()
				Local srcPath:=modulesDir+name+"/"+name+".monkey2"
				
				module=New Module( name,srcPath,"module",MX2_MODULES_VERSION )
				modulesMap[name]=module
				modules.Push( module )
				
				parsingModule=module
				MX2_SRCS.Push( module.srcPath )
			Endif
			
			Local path:=MX2_SRCS.Pop()
			
			If opts.verbose>0 Print "Parsing "+path
			
			Local ident:=module.ident+"_"+MungPath( MakeRelativePath( StripExt( path ),module.baseDir ) )
			
			Local parser:=New Parser
			
			Local cd:=currentDir

			currentDir=ExtractDir( path )
			
			Local fdecl:=parser.ParseFile( ident,path,ppsyms )
			
			fdecl.module=module
			fdecl.hfile=module.hfileDir+ident+".h"
			fdecl.cfile=module.cfileDir+ident+".cpp"

			module.fileDecls.Push( fdecl )

			For Local imp:=Eachin fdecl.imports
			
				ImportFile( imp )
				
			Next
			
			currentDir=cd
			
		Forever
	
	End
	
	Method SortModules( module:Module,done:StringMap<Bool>,deps:Stack<Module> )
	
		If done.Contains( module.name ) Return
		
		For Local dep:=Eachin module.moduleDeps.Keys
		
			Local module2:=modulesMap[dep]
		
			SortModules( module2,done,deps )
		
		Next
		
		If done.Contains( module.name ) Return
		
		done[module.name]=True
		
		deps.Push( module )
		
	End
	
	Method SortModules()

		'sort modules into dependency order
		Local sorted:=New Stack<Module>
		Local done:=New StringMap<Bool>
		
		sorted.Push( modulesMap["monkey"] )
		done["monkey"]=True
		
		For Local i:=0 Until modules.Length
			SortModules( modules[i],done,sorted )
		Next
		
		modules=sorted
		
		For Local i:=0 Until modules.Length
		
			Local module:=modules[modules.Length-i-1]

			If module<>mainModule LD_LIBS.Push( module.outputDir+module.name+".a" )
			
		Next
		
	End

	Method Semant()
	
		If opts.verbose=0 Print "Semanting..."
		
		SortModules()
		
		For Local i:=0 Until modules.Length
		
			Local module:=modules[i]
			
'			Print ""		
'			Print "Semanting module:"+module.srcPath
'			Print ""
			
			For Local fdecl:=Eachin module.fileDecls
			
				Local fscope:=New FileScope( fdecl )
				
				module.fileScopes.Push( fscope )
			Next
			
			If i=0 CreatePrimTypes()
			
			semantingModule=module
			
			For Local fscope:=Eachin module.fileScopes
			
				If opts.verbose>0 Print "Semanting "+fscope.fdecl.path
			
				fscope.Semant()
				
			Next
			
			Repeat
			
				If Not semantMembers.Empty
				
					Local ctype:=semantMembers.RemoveFirst()
					
					PNode.semanting.Push( ctype.cdecl )
					
					Try
					
						ctype.SemantMembers()
						
					Catch ex:SemantEx
					End
					
					PNode.semanting.Pop()

				Else If Not semantStmts.Empty
		
					Local func:=semantStmts.Pop()
					
					PNode.semanting.Push( func.fdecl )
					
					Try
						func.SemantStmts()
			
					Catch ex:SemantEx
					End
					
					PNode.semanting.Pop()
				
				Else
					Exit
				Endif

			Forever
			
			semantingModule=Null

			'Check Main
			'			
			Local main:=module.main
			
			If opts.productType="app" And module=mainModule
				If main
					main.fdecl.symbol="bbMain"
				Else
					New BuildEx( "Can't find Main:Void()" )
				Endif
			Else If opts.productType="module"
				If main
					main.fdecl.symbol="mx2_"+module.ident+"_main"
				Endif
			Endif
			
			'Ugly stuff for generic instances
			'
			Local transFiles:=New StringMap<FileDecl>
			
			For Local inst:=Eachin module.genInstances
			
				Local transFile:FileDecl
				
				Local vvar:=Cast<VarValue>( inst )
				Local func:=Cast<FuncValue>( inst )
				Local ctype:=TCast<ClassType>( inst )
				
				If vvar
					transFile=vvar.transFile
				Else If func
					transFile=func.transFile
				Else If ctype
					transFile=ctype.transFile
				Endif
				
				If Not transFile Or transFile.module=module Continue

				Local transFile2:=transFile

				transFile=transFiles[transFile2.ident]
				
				If Not transFile
				
'					Print "transFile2="+transFile2.path+", module="+transFile2.module.ident+", exhfile="+transFile2.exhfile+", hfile="+transFile2.hfile
				
					transFile=New FileDecl
					
					transFile.ident=module.ident+"_"+transFile2.ident
					
					transFile.path=transFile2.path
					transFile.nmspace=transFile2.nmspace
					transFile.usings=transFile2.usings
					transFile.imports=transFile2.imports
										
					transFile.module=module
					transFile.exhfile=transFile2.hfile
					transFile.hfile=module.hfileDir+transFile.ident+".h"
					transFile.cfile=module.cfileDir+transFile.ident+".cpp"
					
					transFiles[transFile2.ident]=transFile
					
					module.fileDecls.Push( transFile )
				Endif
				
				If vvar
					vvar.transFile=transFile
					transFile.globals.Push( vvar )
				Else If func
					func.transFile=transFile
					transFile.functions.Push( func )
				Else If ctype
					ctype.transFile=transFile
					transFile.classes.Push( ctype )
				Endif
				
			Next
	
		Next
		
	End
	
	Method Translate()
	
		If opts.verbose=0 Print "Translating..."
		
		Local module:=mainModule
		
		CreateDir( module.buildDir )
		CreateDir( module.buildDir+"build_cache" )
		If Not CreateDir( module.cacheDir ) Print "Failed to create dir:"+module.cacheDir
		If Not CreateDir( module.outputDir ) Print "Failed to create dir:"+module.outputDir

		For Local fdecl:=Eachin module.fileDecls
		
			If opts.verbose>0 Print "Translating "+fdecl.path
		
			Local translator:=New Translator_CPP
			
			Try
				translator.Translate( fdecl )
			Catch ex:TransEx
			End
			
			SRC_FILES.Push( fdecl.cfile )
		Next
	
	End
	
	Method Compile()
	
		If opts.verbose=0 Print "Compiling...."
		
		Local module:=mainModule
	
		For Local src:=Eachin SRC_FILES
		
			Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cacheDir ) )+".o"
						
			Local cmd:=""
			Select ExtractExt( src )
			Case ".c",".m"
				cmd=CC_CMD+" "+CC_OPTS.Join( " " )
			Case ".cc",".cxx",".cpp",".mm"
				cmd=CXX_CMD+" -std=c++11 -g "+CPP_OPTS.Join( " " )
			End
			
			cmd+=" -Wno-int-to-pointer-cast"
			cmd+=" -Wno-parentheses-equality"
			cmd+=" -Wno-comment"
			
			cmd+=" -I~q"+modulesDir+"monkey/native~q"
			
			'Check dependancies
			'			
			Local objTime:=GetFileTime( obj )
			
			Local deps:=StripExt( obj )+".deps"
			
			If opts.fast And objTime>=GetFileTime( src )	'source file up to date?
			
				If GetFileType( deps )=FILETYPE_NONE
				
					If opts.verbose>0 Print "Scanning "+src
			
					Exec( cmd+" -MM ~q"+src+"~q >~q"+deps+"~q" ) 
					
				Endif
				
				Local uptodate:=True
				
				Local srcs:=LoadString( deps ).Split( " \" )
				
				For Local i:=1 Until srcs.Length
				
					If GetFileTime( srcs[i].Trim() )>objTime
						uptodate=False
						Exit
					Endif
					
				Next
				
				If uptodate
					maxObjTime=Max( maxObjTime,objTime )
					OBJ_FILES.Push( obj )
					Continue
				Endif
				
			Else
			
				DeleteFile( deps )

			Endif
			
			If opts.verbose>0 Print "Compiling "+src
			
			cmd+=" -c -o ~q"+obj+"~q ~q"+src+"~q"
			
			Exec( cmd ) 

			maxObjTime=Max( maxObjTime,GetFileTime( obj ) )
			OBJ_FILES.Push( obj )
			
		Next
	
	End
	
	Method Link()
	
		Select opts.productType
		Case "app"
			CreateApp()
		Case "module"
			CreateArchive()
		End
	End
	
	Method CreateApp()
	
		Local module:=mainModule
		
		Local outputFile:="",assetsDir:="",dllsDir:=""
		
		Local cmd:=LD_CMD
		cmd+=" "+LD_OPTS.Join( " " )
		
		If opts.target="emscripten"
		
			outputFile=module.outputDir+module.name+".html"
			assetsDir=module.buildDir+"assets/"
			dllsDir=ExtractDir( outputFile )
			
'			Note: mserver can't handle --emrun as it tries to POST stdout
'			cmd="em++ --emrun --preload-file ~q"+assetsDir+"@/assets~q"

			cmd="em++ --preload-file ~q"+assetsDir+"@/assets~q"
			
		Else If HostOS="windows"
		
			outputFile=module.outputDir+module.name+".exe"
			assetsDir=module.outputDir+"assets/"
			dllsDir=ExtractDir( outputFile )
			
		Else If HostOS="macos"
		
			Local productName:=module.name

			Local outputDir:=module.outputDir+module.name+".app/"
			
			outputFile=outputDir+"Contents/MacOS/"+module.name
			assetsDir=outputDir+"Contents/Resources/"
			dllsDir=ExtractDir( outputFile )
			
			CreateDir( outputDir )
			CreateDir( outputDir+"Contents" )
			CreateDir( outputDir+"Contents/MacOS" )
			CreateDir( outputDir+"Contents/Resources" )
			
			Local plist:=""
			plist+="<?xml version=~q1.0~q encoding=~qUTF-8~q?>~n"
			plist+="<!DOCTYPE plist PUBLIC ~q-//Apple Computer//DTD PLIST 1.0//EN~q ~qhttp://www.apple.com/DTDs/PropertyList-1.0.dtd~q>~n"
			plist+="<plist version=~q1.0~q>~n"
			plist+="<dict>~n"
			plist+="~t<key>CFBundleExecutable</key>~n"
			plist+="~t<string>"+productName+"</string>~n"
			plist+="~t<key>CFBundleIconFile</key>~n"
			plist+="~t<string>"+productName+"</string>~n"
			plist+="~t<key>CFBundlePackageType</key>~n"
			plist+="~t<string>APPL</string>~n"
			plist+="</dict>~n"
			plist+="</plist>~n"
			
			SaveString( plist,outputDir+"Contents/Info.plist" )
			
		Else	'linux!
		
			outputFile=module.outputDir+module.name
			assetsDir=module.outputDir+"assets/"
			dllsDir=ExtractDir( outputFile )

		Endif
		
		If opts.verbose>=0 Print "Linking "+outputFile
		
		DeleteDir( assetsDir,True )
		CreateDir( assetsDir )
		
		For Local ass:=Eachin ASSET_FILES
		
			Local i:=ass.Find( "@/" )
			If i=-1
				CopyFile( ass,assetsDir+StripDir( ass ) )
				Continue
			Endif
			
			Local dst:=assetsDir+ass.Slice( i+2 )
			If Not dst.EndsWith( "/" ) dst+="/"
			CreateDir( dst )
			
			ass=ass.Slice( 0,i )
			
			CopyFile( ass,dst+StripDir( ass ) )
		Next
		
		cmd+=" -o ~q"+outputFile+"~q"
		
		For Local obj:=Eachin OBJ_FILES
			cmd+=" ~q"+obj+"~q"
		Next
		
		For Local lib:=Eachin LD_LIBS
			cmd+=" ~q"+lib+"~q"
		Next

		cmd+=" "+LD_SYSLIBS.Join( " " )
		
'		Print cmd
		Exec( cmd )
		
		For Local src:=Eachin DLL_FILES
		
			Local dir:=dllsDir
			
			Local ext:=ExtractExt( src )
			If ext
				Local rdir:=GetEnv( "MX2_APP_DIR_"+ext.Slice( 1 ).ToUpper() )
				If rdir dir=RealPath( dir+rdir )
			Endif
			
			If Not dir.EndsWith( "/" ) dir+="/"
			
			Local dst:=dir+StripDir( src )
			
			If Not CopyAll( src,dst ) Throw New BuildEx( "Failed to copy '"+src+"' to '"+dst+"'" )
		Next
		
		If Not opts.run Return
		
		Local run:=""
		If opts.target="emscripten"
			Local mserver:=GetEnv( "MX2_MSERVER" )
			run=mserver+" ~q"+outputFile+"~q"
		Else
			run="~q"+outputFile+"~q"
		Endif
		
		Exec( run )
	End
	
	Function CopyAll:Bool( src:String,dst:String )
	
		Select GetFileType( src )

		Case FILETYPE_FILE
		
			If Not CreateDir( ExtractDir( dst ) ) Return False
		
			If GetFileTime( src )>GetFileTime( dst )
				If Not CopyFile( src,dst ) Return False
			Endif
			
			Return GetFileType( dst )=FILETYPE_FILE
			
		Case FILETYPE_DIR
		
			If Not CreateDir( dst ) Return False
			
			For Local file:=Eachin LoadDir( src )
			
				If Not CopyAll( src+"/"+file,dst+"/"+file ) Return False
			
			Next
			
			Return True
		
		End
		
		Return False
		
	End
	
	Method CreateArchive()

		Local module:=mainModule
		
		Local outputFile:=module.outputDir+module.name+".a"
		
		If opts.verbose>=0 Print "Archiving "+outputFile
		
		DeleteFile( outputFile )
		
		Local objs:=""
		
		For Local i:=0 Until OBJ_FILES.Length
			
			objs+=" ~q"+OBJ_FILES.Get( i )+"~q"
			
			If objs.Length<1000 And i<OBJ_FILES.Length-1 Continue

			Local cmd:=AR_CMD+" q ~q"+outputFile+"~q"+objs

			Exec( cmd )
			
			objs=""
			
		Next
		
	End
	
	Method GetNamespace:NamespaceScope( path:String )
	
		Local nmspace:=rootNamespace,i0:=0
		
		While i0<path.Length
			Local i1:=path.Find( ".",i0 )
			If i1=-1 i1=path.Length
			
			Local id:=path.Slice( i0,i1 )
			i0=i1+1
			
			Local ntype:=TCast<NamespaceType>( nmspace.GetType( id ) )
			If Not ntype
				ntype=New NamespaceType( id,nmspace )
				nmspace.Insert( id,ntype )
			Endif
			
			nmspace=ntype.scope
		Wend
		
		Return nmspace
	End
	
	Method ClearPrimTypes()
	
'		Type.VoidType=Null
		Type.BoolType=Null
		Type.ByteType=Null
		Type.UByteType=Null
		Type.ShortType=Null
		Type.UShortType=Null
		Type.IntType=Null
		Type.UIntType=Null
		Type.LongType=Null
		Type.ULongType=Null
		Type.FloatType=Null
		Type.DoubleType=Null
		Type.StringType=Null
		Type.ArrayClass=Null
		Type.ObjectClass=Null
		Type.ThrowableClass=Null
	End
	
	Method CreatePrimTypes()
	
		Local types:=monkeyNamespace

		'Find new 'monkey.types' namespace...
		For Local scope:=Eachin monkeyNamespace.inner
			Local nmspace:=Cast<NamespaceScope>( scope )
			If Not nmspace Or nmspace.ntype.ident<>"types" Continue
			types=nmspace
			Exit
		Next

		Type.BoolType=New PrimType( TCast<ClassType>( types.nodes["@bool"] ) )
		Type.ByteType=New PrimType( TCast<ClassType>( types.nodes["@byte"] ) )
		Type.UByteType=New PrimType( TCast<ClassType>( types.nodes["@ubyte"] ) )
		Type.ShortType=New PrimType( TCast<ClassType>( types.nodes["@short"] ) )
		Type.UShortType=New PrimType( TCast<ClassType>( types.nodes["@ushort"] ) )
		Type.IntType=New PrimType( TCast<ClassType>( types.nodes["@int"] ) )
		Type.UIntType=New PrimType( TCast<ClassType>( types.nodes["@uint"] ) )
		Type.LongType=New PrimType( TCast<ClassType>( types.nodes["@long"] ) )
		Type.ULongType=New PrimType( TCast<ClassType>( types.nodes["@ulong"] ) )
		Type.FloatType=New PrimType( TCast<ClassType>( types.nodes["@float"] ) )
		Type.DoubleType=New PrimType( TCast<ClassType>( types.nodes["@double"] ) )
		Type.StringType=New PrimType( TCast<ClassType>( types.nodes["@string"] ) )
		
		Type.ArrayClass=TCast<ClassType>( types.nodes["@Array"] )
		Type.ObjectClass=TCast<ClassType>( types.nodes["@object"] )
		Type.ThrowableClass=TCast<ClassType>( types.nodes["@throwable"] )
		
		Type.CStringClass=TCast<ClassType>( types.nodes["CString"] )
		Type.WStringClass=TCast<ClassType>( types.nodes["WString"] )
		Type.Utf8StringClass=TCast<ClassType>( types.nodes["Utf8String"] )

		Type.ExceptionClass=TCast<ClassType>( types.nodes["@Exception"] )

		rootNamespace.Insert( "void",Type.VoidType )
		rootNamespace.Insert( "bool",Type.BoolType )
		rootNamespace.Insert( "byte",Type.ByteType )
		rootNamespace.Insert( "ubyte",Type.UByteType )
		rootNamespace.Insert( "short",Type.ShortType )
		rootNamespace.Insert( "ushort",Type.UShortType )
		rootNamespace.Insert( "int",Type.IntType )
		rootNamespace.Insert( "uint",Type.UIntType )
		rootNamespace.Insert( "long",Type.LongType )
		rootNamespace.Insert( "ulong",Type.ULongType )
		rootNamespace.Insert( "float",Type.FloatType )
		rootNamespace.Insert( "double",Type.DoubleType )
		rootNamespace.Insert( "string",Type.StringType )
		rootNamespace.Insert( "object",Type.ObjectClass )
		rootNamespace.Insert( "throwable",Type.ThrowableClass )
		
		rootNamespace.Insert( "CString",Type.CStringClass )
		rootNamespace.Insert( "WString",Type.WStringClass )
		rootNamespace.Insert( "Utf8String",Type.Utf8StringClass )
		
		rootNamespace.Insert( "Exception",Type.ExceptionClass )
		
		Type.BoolType.Semant()
		Type.ByteType.Semant()
		Type.UByteType.Semant()
		Type.ShortType.Semant()
		Type.UShortType.Semant()
		Type.IntType.Semant()
		Type.UIntType.Semant()
		Type.LongType.Semant()
		Type.ULongType.Semant()
		Type.FloatType.Semant()
		Type.DoubleType.Semant()
		Type.StringType.Semant()
		Type.ArrayClass.Semant()
		Type.ObjectClass.Semant()
		Type.ThrowableClass.Semant()
	End
	
	#rem
	Method AllocTmp:String()

		tmpId+=1
		
		For Local i:=0 Until 10
		
			Local id:=(tmpId+i) Mod 10
			
			Local tmp:="tmp/tmp"+id+".txt"
			Local f:=FileStream.Open( tmp,"w" )
			If Not f Continue
			
			f.Close()
			tmpId=id
			Return tmp
		Next
		
		Return ""
	End
	#end
	
	Method ImportFile:Void( path:String )
	
		If path.StartsWith( "<" ) And path.EndsWith( ">" )
			ImportSystemFile( path.Slice( 1,-1 ) )
		Else
			If currentDir path=currentDir+path
			ImportLocalFile( path )
		Endif
		
	End
	
	Method ImportSystemFile:Void( path:String )
	
		Local ext:=ExtractExt( path )

		Local name:=StripExt( path )
		
		If ext=".monkey2" parsingModule.moduleDeps[name]=True
		
		If imported.Contains( path ) Return
		
		imported[path]=True
		
		Select ext.ToLower()
		Case ".a"

			If name.StartsWith( "lib" ) name=name.Slice( 3 ) Else name=path
			LD_SYSLIBS.Push( "-l"+name )
			
		Case ".lib",".dylib"
		
			LD_SYSLIBS.Push( "-l"+name )
			
		Case ".framework"
		
			LD_SYSLIBS.Push( "-framework "+name )
			
		Case ".h",".hh",".hpp"
		
'			STD_INCLUDES.Push( "<"+path+">" )
			
		Case ".monkey2"

			MX2_LIBS.Push( name )
		
		Default

			New BuildEx( "Unrecognized import file type: '"+path+"'" )
			
		End

	End
	
	Method ImportLocalFile:Void( path:String )
	
		If imported.Contains( path ) Return
		imported[path]=True
		
		Local ext:=ExtractExt( path ).ToLower()
		
		Local name:=StripDir( StripExt( path ) )

		If name="*"
		
			Local dir:=ExtractDir( path )
			
			If GetFileType( dir )<>FILETYPE_DIR
				New BuildEx( "Directory '"+dir+"' not found" )
				Return
			Endif
			
			Local qdir:="~q"+dir+"~q"
			
			Select ext
			Case ".h"
			
				CC_OPTS.Push( "-I"+qdir )
				CPP_OPTS.Push( "-I"+qdir )
				
			Case ".hh",".hpp"
			
				CPP_OPTS.Push( "-I"+qdir )
				
			Case ".a",".lib",".dylib"
			
				LD_OPTS.Push( "-L"+qdir )
				
			Case ".framework"
			
				LD_OPTS.Push( "-F"+qdir )
				
			Default
			
				New BuildEx( "Unrecognized import file filter '*"+ext+"'" )
	
			End
			Return
		Endif
		
		Local qpath:="~q"+path+"~q"
		
		Select ext
		Case ".framework"
			
			If GetFileType( path )<>FILETYPE_DIR
				New BuildEx( "Framework "+qpath+" not found" )
				Return
			Endif
			
		Default
		
			Local tpath:=path
		
			Local i:=tpath.Find( "@/" )
			If i<>-1 tpath=tpath.Slice( 0,i )
		
			If GetFileType( tpath )<>FILETYPE_FILE
				New BuildEx( "File "+qpath+" not found" )
				Return
			Endif
			
		End
		
		Select ext
		Case ".mx2",".monkey2"
		
			MX2_SRCS.Push( path )
			
		Case ".h",".hh",".hpp"
		
'			STD_INCLUDES.Push( qpath )
			
		Case ".c",".cc",".cxx",".cpp",".m",".mm"
		
			If parsingModule=mainModule SRC_FILES.Push( path )
		
'			If modules.Length=1
'				SRC_FILES.Push( path )
'			Endif
			
		Case ".o"
		
			OBJ_FILES.Push( path )
			
		Case ".a",".lib"
		
			LD_SYSLIBS.Push( qpath )
			
		Case ".so",".dll",".exe"
		
			DLL_FILES.Push( path )
			
		Case ".dylib"
		
			LD_SYSLIBS.Push( qpath )
			
			DLL_FILES.Push( path )
			
		Case ".framework"
		
			'OK, this is ugly...
		
			ImportLocalFile( ExtractDir( path )+"*.framework" )
			
			ImportSystemFile( StripDir( path ) )
			
			DLL_FILES.Push( path )
		
		Default
		
			ASSET_FILES.Push( path )
		End
	
	End
	
	Method Exec:Bool( cmd:String )
	
		If Not system( cmd+" 2>errs.txt" ) Return True
		
		Local errs:=LoadString( "errs.txt" )
		
		Throw New BuildEx( "System command '"+cmd+"' failed.~n~n"+cmd+"~n~n"+errs )
		
		Return False
	End
End
