
Namespace mx2

Global Builder:BuilderInstance

Class BuildOpts

	Field mainSource:String
	
	Field productType:String	'"app" or "module"
	
	Field target:String
	
	Field config:String
	
	Field clean:Bool
	
	Field product:String

	Field assets:String

	Field dlls:String

	Field appType:String
	
	Field verbose:Int
	
	Field fast:Bool

	Field passes:Int	'1=parse, 2=semant, 3=translate, 4=build, 5=run
	
	Field geninfo:Bool
	
	Field wholeArchive:Bool
	
End

Class BuilderInstance

	Field errors:=New Stack<ErrorEx>

	Field opts:BuildOpts
	
	Field product:BuildProduct
	
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
	
	Field MX2_SRCS:=New StringStack

	Field MX2_LIBS:=New StringStack
	
	Method New( opts:BuildOpts )
	
		Self.opts=opts
		
		Builder=self

		If Int( GetEnv( "MX2_WHOLE_ARCHIVE" ) ) opts.wholeArchive=True
		
		If opts.target="desktop"
		
			opts.target=HostOS
			
		Else If HostOS="windows" And opts.target="raspbian"
		
			SetEnv( "PATH",GetEnv( "MX2_RASPBIAN_TOOLS" )+";"+GetEnv( "PATH" ) )
			
		Endif
		
		ppsyms["__HOST__"]="~q"+HostOS+"~q"
		ppsyms["__HOSTOS__"]="~q"+HostOS+"~q"
		ppsyms["__TARGET__"]="~q"+opts.target+"~q"
		ppsyms["__CONFIG__"]="~q"+opts.config+"~q"
		
		Select opts.target
		Case "windows","macos","linux","raspbian"
			ppsyms["__DESKTOP_TARGET__"]="true"
			ppsyms["__WEB_TARGET__"]="false"
			ppsyms["__MOBILE_TARGET__"]="false"
		Case "emscripten"
			ppsyms["__DESKTOP_TARGET__"]="false"
			ppsyms["__WEB_TARGET__"]="true"
			ppsyms["__MOBILE_TARGET__"]="false"
		Case "android","ios"
			ppsyms["__DESKTOP_TARGET__"]="false"
			ppsyms["__WEB_TARGET__"]="false"
			ppsyms["__MOBILE_TARGET__"]="true"
		End

		profileName=opts.target+"_"+opts.config
		
		MODULES_DIR=CurrentDir()+"modules/"
		
		If opts.productType="app" APP_DIR=ExtractDir( opts.mainSource )
		
		ClearPrimTypes()
		
		rootNamespace=New NamespaceScope( Null,Null )
		
		monkeyNamespace=GetNamespace( "monkey" )
	End
	
	Method Parse()
	
		If opts.verbose=0 Print "Parsing..."
		
		Local name:=StripDir( StripExt( opts.mainSource ) )

		Local module:=New Module( name,opts.mainSource,MX2CC_VERSION,profileName )
		modulesMap[name]=module
		modules.Push( module )
		
		Select opts.target
		Case "android"
			product=New AndroidBuildProduct( module,opts )
		Case "ios"
			product=New IosBuildProduct( module,opts )
		Default
			product=New GccBuildProduct( module,opts )
		End
		
		mainModule=module
		
		If name="monkey" And opts.productType="module" modulesMap["monkey"]=module
		
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
				Local srcPath:=MODULES_DIR+name+"/"+name+".monkey2"
				
				module=New Module( name,srcPath,MX2CC_VERSION,profileName )
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

			If module<>mainModule product.MOD_LIBS.Push( module.outputDir+module.name+".a" )
			
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
			
				PNode.semanting.Push( fscope.fdecl )
				
				Try
					fscope.SemantUsings()
				catch ex:SemantEx
				End
				
				PNode.semanting.Pop()
				
			Next
			
			For Local fscope:=Eachin module.fileScopes
			
				If opts.verbose>0 Print "Semanting "+fscope.fdecl.path
			
				fscope.Semant()
				
			Next
			
			Repeat
			
				If Not semantMembers.Empty
				
					Local ctype:=semantMembers.RemoveFirst()
					
					PNode.semanting.Push( ctype.cdecl )
					Scope.semanting.Push( Null )
					
					Try
					
						ctype.SemantMembers()
						
					Catch ex:SemantEx
					End
					
					PNode.semanting.Pop()
					Scope.semanting.Pop()

				Else If Not semantStmts.Empty
		
					Local func:=semantStmts.Pop()
					
					PNode.semanting.Push( func.fdecl )
					Scope.semanting.Push( Null )
					
					Try
						func.SemantStmts()
			
					Catch ex:SemantEx
					End
					
					PNode.semanting.Pop()
					Scope.semanting.Pop()
				
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
		
		CreateDir( module.outputDir )

		If Not CreateDir( module.hfileDir ) Throw New BuildEx( "Failed to create dir:"+module.hfileDir )
		If Not CreateDir( module.cfileDir ) Throw New BuildEx( "Failed to create dir:"+module.cfileDir )

		For Local fdecl:=Eachin module.fileDecls
		
			If opts.verbose>0 Print "Translating "+fdecl.path
		
			Local translator:=New Translator_CPP
			
			Try
				translator.Translate( fdecl )
			Catch ex:TransEx
			End
			
			product.SRC_FILES.Push( fdecl.cfile )
		Next
		
	End
	
	Method GetNamespace:NamespaceScope( path:String,mustExist:Bool=False )
	
		Local nmspace:=rootNamespace,i0:=0
		
		While i0<path.Length
			Local i1:=path.Find( ".",i0 )
			If i1=-1 i1=path.Length
			
			Local id:=path.Slice( i0,i1 )
			i0=i1+1
			
			Local ntype:=TCast<NamespaceType>( nmspace.GetType( id ) )
			If Not ntype
				If mustExist New SemantEx( "Namespace '"+path+"' not found" )
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
		Type.VariantType=Null
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
		Type.VariantType=New PrimType( TCast<ClassType>( types.nodes["@variant"] ) )
		
		Type.ArrayClass=TCast<ClassType>( types.nodes["@Array"] )
		Type.ObjectClass=TCast<ClassType>( types.nodes["@object"] )
		Type.ThrowableClass=TCast<ClassType>( types.nodes["@throwable"] )

		Type.CStringClass=TCast<ClassType>( types.nodes["@cstring"] )
		Type.TypeInfoClass=TCast<ClassType>( types.nodes["@typeinfo"] )

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
		rootNamespace.Insert( "variant",Type.VariantType )
		
		rootNamespace.Insert( "object",Type.ObjectClass )
		rootNamespace.Insert( "throwable",Type.ThrowableClass )

		rootNamespace.Insert( "cstring",Type.CStringClass )
		rootNamespace.Insert( "typeinfo",Type.TypeInfoClass )
		
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
		Type.VariantType.Semant()
		Type.ArrayClass.Semant()
		Type.ObjectClass.Semant()
		Type.ThrowableClass.Semant()
		Type.CStringClass.Semant()
		Type.TypeInfoClass.Semant()
	End
	
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
			product.LD_SYSLIBS.Push( "-l"+name )
			
		Case ".lib",".dylib"
		
			product.LD_SYSLIBS.Push( "-l"+name )
			
		Case ".framework"
		
			product.LD_SYSLIBS.Push( "-framework "+name )
			
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
		
		Local i:=path.Find( "@/" )
		If i<>-1
			Local src:=path.Slice( 0,i )
			
			If GetFileType( src )=FileType.None
				New BuildEx( "Asset '"+src+"' not found" )
				Return
			Endif
			
			product.ASSET_FILES.Push( path )
			Return
		Endif
		
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
			
				product.CC_OPTS.Push( "-I"+qdir )
				product.CPP_OPTS.Push( "-I"+qdir )
				
			Case ".hh",".hpp"
			
				product.CPP_OPTS.Push( "-I"+qdir )
				
			Case ".a",".lib",".dylib"
			
				product.LD_OPTS.Push( "-L"+qdir )
				
			Case ".framework"
			
				product.LD_OPTS.Push( "-F"+qdir )
				
			Default
			
				New BuildEx( "Unrecognized import file filter '*"+ext+"'" )
	
			End
			Return
		Endif
		
		Local qpath:="~q"+path+"~q"

		Select ext
		Case ".framework"
			
			If GetFileType( path )<>FileType.Directory
				New BuildEx( "Framework "+qpath+" not found" )
				Return
			Endif
			
		Default
		
			Select GetFileType( path )
			Case FileType.Directory
			
				product.ASSET_FILES.Push( path )
				Return
				
			Case FileType.None
			
				New BuildEx( "File "+qpath+" not found" )
				Return
				
			End
		End
		
		Select ext
		Case ".mx2",".monkey2"
		
			MX2_SRCS.Push( path )
			
		Case ".h",".hh",".hpp"
		
'			STD_INCLUDES.Push( qpath )
			
		Case ".c",".cc",".cxx",".cpp",".m",".mm",".asm",".s"
		
			If parsingModule=mainModule product.SRC_FILES.Push( path )
		
'			If modules.Length=1
'				SRC_FILES.Push( path )
'			Endif
			
		Case ".o"
		
			product.OBJ_FILES.Push( path )
			
		Case ".a",".lib"
		
			product.LD_SYSLIBS.Push( qpath )
			
		Case ".so"
		
			If opts.target="android"		'probably all non-windows targets
			
				product.LD_SYSLIBS.Push( qpath )
			
			Endif
			
			product.DLL_FILES.Push( path )
			
		Case ".dll",".exe"
		
			product.DLL_FILES.Push( path )
			
		Case ".dylib"
		
			product.LD_SYSLIBS.Push( qpath )
			
			product.DLL_FILES.Push( path )
			
		Case ".framework"
		
			'OK, this is ugly...
		
			ImportLocalFile( ExtractDir( path )+"*.framework" )
			
			ImportSystemFile( StripDir( path ) )
			
			product.DLL_FILES.Push( path )
		
		Default
		
			product.ASSET_FILES.Push( path )
		End
	
	End
	
	Method AllocTmpFile:String( kind:String )
	
		CreateDir( "tmp" )

		For Local i:=1 Until 10
			Local file:="tmp/"+kind+i+".txt"
			DeleteFile( file )
			If GetFileType( file )=FileType.None Return file
		Next
		
		Throw New BuildEx( "Can't allocate tmp file" )
		Return ""
	End
	
	Method Exec:Bool( cmd:String )
	
		If opts.verbose>2 Print cmd
	
		Local errs:=AllocTmpFile( "stderr" )
			
		If Not system( cmd+" 2>"+errs ) Return True
		
		Local terrs:=LoadString( errs )
		
		Throw New BuildEx( "System command '"+cmd+"' failed.~n~n"+cmd+"~n~n"+terrs )
		
		Return False
	End
End
