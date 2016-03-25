
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

	Field MX2_FILES:=New StringList
	Field MX2_LIBS:=New StringList
	
	Field SRC_FILES:=New StringStack
	Field OBJ_FILES:=New StringStack
	Field LD_OPTS:=New StringStack	
	Field CC_OPTS:=New StringStack
	Field CPP_OPTS:=New StringStack
	Field LD_LIBS:=New StringStack
	Field LD_SYSLIBS:=New StringStack
	Field DLL_FILES:=New StringStack
	Field ASSET_FILES:=New StringStack
	Field STD_INCLUDES:=New StringStack
	
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

		Local module:=New Module( StripDir( StripExt( opts.mainSource ) ),opts.mainSource,opts.productType )
		modules.Push( module )
		
		Local monkeyDone:=(module.name="monkey" And module.productType="module")
		
		If opts.clean 
			DeleteDir( module.outputDir,True )
			DeleteDir( module.cacheDir,True )
		Endif
		
		MX2_FILES.AddLast( module.srcPath )
		
		Repeat
		
			If MX2_FILES.Empty
			
				If MX2_LIBS.Empty
				
					If monkeyDone Exit
					monkeyDone=True
					
					MX2_LIBS.AddLast( "monkey" )
				Endif
				
				Local lib:=MX2_LIBS.RemoveFirst()
				If lib="monkey" And Not monkeyDone Continue
				
				Local module2:=modulesMap[lib]
				If module2
					modules.Remove( module2 )
					modules.Push( module2 )
					Continue
				Endif
				
				Local srcPath:=modulesDir+lib+"/"+lib+".monkey2"
				
				module=New Module( lib,srcPath,"module" )
				modulesMap[lib]=module
				modules.Push( module )

				LD_LIBS.Push( module.outputDir+lib+".a" )
				
				MX2_FILES.AddLast( module.srcPath )
			Endif
			
			Local path:=MX2_FILES.RemoveFirst()
			
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

	Method Semant()
	
		If opts.verbose=0 Print "Semanting..."

		For Local i:=0 Until modules.Length

			Local module:=modules[modules.Length-i-1]
			
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
			
			Local count:=0
			
			Repeat
			
				count+=1
				If count=1000 
'					Print "Giving up!"
'					Exit
				Endif
			
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
			
			Local main:=module.main
			
			If opts.productType="app" And module=modules[0]
				If main
					main.fdecl.symbol="bbMain"
				Else
					Print "Can't find Main:Void()"
				Endif
			Else If opts.productType="module"
				If main
					main.fdecl.symbol="mx2_"+module.ident+"_main"
				Endif
			Endif
			
			semantingModule=Null
			
			Local transFiles:=New StringMap<FileDecl>
			
			For Local inst:=Eachin module.genInstances
			
				Local transFile:FileDecl
				
				Local vvar:=Cast<VarValue>( inst )
				Local func:=Cast<FuncValue>( inst )
				Local ctype:=Cast<ClassType>( inst )
				
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
		
		Local module:=modules[0]
		
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
		
		Local module:=modules[0]
	
		For Local src:=Eachin SRC_FILES
		
			Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cacheDir ) )+".o"
						
			Local cmd:=""
			Select ExtractExt( src )
			Case ".c",".m"
				cmd="gcc "+CC_OPTS.Join( " " )
			Case ".cpp",".mm"
				cmd="g++ -std=c++11 -g "+CPP_OPTS.Join( " " )
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
	
		Local module:=modules[0]
		
		Local outputFile:="",assetsDir:=""
		
		If opts.target="emscripten"
		
			assetsDir=module.buildDir+"assets/"
			
		Else If HostOS="windows"
		
			outputFile=module.outputDir+module.name+".exe"
			assetsDir=module.outputDir+"assets"
			
		Else If HostOS="linux"
		
			outputFile=module.outputDir+module.name
			assetsDir=module.outputDir+"assets"
			
		Else If HostOS="macos"
		
			Local productName:=module.name

			Local outputDir:=module.outputDir+module.name+".app/"
			
			outputFile=outputDir+"Contents/MacOS/"+module.name
			assetsDir=outputDir+"Contents/Resources/"
			
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
			
		Else
		
			assetsDir=module.outputDir+"assets/"

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
		
		Local cmd:="g++"
		
		cmd+=" "+LD_OPTS.Join( " " )

		cmd+=" -o ~q"+outputFile+"~q"
		
		For Local obj:=Eachin OBJ_FILES
			cmd+=" ~q"+obj+"~q"
		Next
		
		For Local lib:=Eachin LD_LIBS
			cmd+=" ~q"+lib+"~q"
		Next

		cmd+=" "+LD_SYSLIBS.Join( " " )
		
		Exec( cmd )
		
		For Local src:=Eachin DLL_FILES
			Local dst:=ExtractDir( outputFile )+StripDir( src )
			If GetFileTime( src )>GetFileTime( dst ) CopyFile( src,dst )
		Next
		
		If Not opts.run Return
		
		Exec( "~q"+outputFile+"~q" )
		
	End
	
	Method CreateArchive()

		Local module:=modules[0]
		Local outputFile:=module.outputDir+module.name+".a"
		
		If opts.verbose>=0 Print "Archiving "+outputFile
		
		Local ar:="ar"
		If opts.target="emscripten" ar="emar"
		
		DeleteFile( outputFile )
		
		Local objs:=""
		
		For Local i:=0 Until OBJ_FILES.Length
			
			objs+=" ~q"+OBJ_FILES.Get( i )+"~q"
			
			If objs.Length<1000 And i<OBJ_FILES.Length-1 Continue

			Local cmd:=ar+" q ~q"+outputFile+"~q"+objs

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
			
			Local ntype:=Cast<NamespaceType>( nmspace.GetType( id ) )
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

		Type.BoolType=New PrimType( Cast<ClassType>( types.nodes["@bool"] ) )
		Type.ByteType=New PrimType( Cast<ClassType>( types.nodes["@byte"] ) )
		Type.UByteType=New PrimType( Cast<ClassType>( types.nodes["@ubyte"] ) )
		Type.ShortType=New PrimType( Cast<ClassType>( types.nodes["@short"] ) )
		Type.UShortType=New PrimType( Cast<ClassType>( types.nodes["@ushort"] ) )
		Type.IntType=New PrimType( Cast<ClassType>( types.nodes["@int"] ) )
		Type.UIntType=New PrimType( Cast<ClassType>( types.nodes["@uint"] ) )
		Type.LongType=New PrimType( Cast<ClassType>( types.nodes["@long"] ) )
		Type.ULongType=New PrimType( Cast<ClassType>( types.nodes["@ulong"] ) )
		Type.FloatType=New PrimType( Cast<ClassType>( types.nodes["@float"] ) )
		Type.DoubleType=New PrimType( Cast<ClassType>( types.nodes["@double"] ) )
		Type.StringType=New PrimType( Cast<ClassType>( types.nodes["@string"] ) )
		
		Type.ArrayClass=Cast<ClassType>( types.nodes["@Array"] )
		Type.ObjectClass=Cast<ClassType>( types.nodes["@object"] )
		Type.ThrowableClass=Cast<ClassType>( types.nodes["@throwable"] )
		
		Type.CStringClass=Cast<ClassType>( types.nodes["CString"] )
		Type.WStringClass=Cast<ClassType>( types.nodes["WString"] )
		Type.Utf8StringClass=Cast<ClassType>( types.nodes["Utf8String"] )

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
			ImportLocalFile( path )
		Endif
		
	End
	
	Method ImportSystemFile:Void( path:String )
	
		Local ext:=ExtractExt( path )
		
		If ext<>".monkey2" And imported.Contains( path ) Return
		
		Local name:=StripExt( path )
		
		Select ext.ToLower()
		Case ".a"

			If name.StartsWith( "lib" ) name=name.Slice( 3 ) Else name=path
			LD_SYSLIBS.Push( "-l"+name )
			
		Case ".lib"
		
			LD_SYSLIBS.Push( "-l"+name )
			
		Case ".h"
		
			STD_INCLUDES.Push( "<"+path+">" )
			
		Case ".framework"
		
			LD_SYSLIBS.Push( "-framework "+name )
			
		Case ".monkey2"
		
			If Not imported.Contains( path )
				modules.Top.moduleDeps.Push( name )
			Endif
			
			MX2_LIBS.AddLast( name )
		
		Default

			New BuildEx( "Unrecognized import file type: '"+path+"'" )
			
		End
		
		imported[path]=True

	End
	
	Method ImportLocalFile:Void( path:String )
	
		If currentDir path=currentDir+path
	
		If imported.Contains( path ) Return
		imported[path]=True
		
		Local ext:=ExtractExt( path )
		Local name:=StripDir( StripExt( path ) )

		If name="*"
			Local dir:=ExtractDir( path )
			If GetFileType( dir )<>FILETYPE_DIR
				New BuildEx( "Directory '"+dir+"' not found" )
				Return
			Endif
			
			Select ext
			Case ".h"
			
				CC_OPTS.Push( "-I~q"+dir+"~q" )
				CPP_OPTS.Push( "-I~q"+dir+"~q" )
				
			Case ".a",".lib"
			
				LD_OPTS.Push( "-L~q"+dir+"~q" )
				
			Default
			
				New BuildEx( "Unrecognized import file filter '*"+ext+"'" )
	
			End
			Return
		Endif
		
		If GetFileType( path )<>FILETYPE_FILE
			New BuildEx( "File '"+path+"' not found" )
			Return
		Endif
		
		Select ext.ToLower()
		Case ".mx2",".monkey2"
		
			MX2_FILES.AddLast( path )
			
		Case ".c",".cpp",".m",".mm"
		
			If modules.Length=1
				SRC_FILES.Push( path )
			Endif
			
		Case ".o"
		
			OBJ_FILES.Push( path )
			
		Case ".a",".lib"
		
			LD_SYSLIBS.Push( "~q"+path+"~q" )
			
		Case ".so",".dll",".exe"
		
			DLL_FILES.Push( path )
			
		Case ".h"
		
			STD_INCLUDES.Push( "~q"+path+"~q" )
			
		Case ".framework"
		
			New BuildEx( "Can't import local framework" )
			
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
