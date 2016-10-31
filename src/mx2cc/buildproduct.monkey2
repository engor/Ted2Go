
Namespace mx2

Class BuildProduct

	Field module:Module
	Field opts:BuildOpts
	Field imports:=New Stack<Module>
	Field outputFile:String
	
	Field LD_OPTS:String
	Field CC_OPTS:String
	Field CPP_OPTS:String
	Field AS_OPTS:String

	Field SRC_FILES:=New StringStack
	Field OBJ_FILES:=New StringStack
	Field LD_SYSLIBS:=New StringStack
	Field ASSET_FILES:=New StringStack
	Field DLL_FILES:=New StringStack
	
	Method New( module:Module,opts:BuildOpts )
		Self.module=module
		Self.opts=opts
		
		Local copts:=""
		
		copts+=" -I~q"+MODULES_DIR+"~q"
		copts+=" -I~q"+MODULES_DIR+"monkey/native~q"
		If APP_DIR copts+=" -I~q"+APP_DIR+"~q"
		
		CC_OPTS+=copts
		CPP_OPTS+=copts
		
		copts=GetEnv( "MX2_LD_OPTS_"+opts.target.ToUpper() )
		If copts LD_OPTS+=" "+copts

		copts=GetEnv( "MX2_LD_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts LD_OPTS+=" "+copts
		
		copts=GetEnv( "MX2_CC_OPTS_"+opts.target.ToUpper() )
		If copts CC_OPTS+=" "+copts
		
		copts=GetEnv( "MX2_CC_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts CC_OPTS+=" "+copts
		
		copts=GetEnv( "MX2_CPP_OPTS_"+opts.target.ToUpper() )
		If opts CPP_OPTS+=" "+copts
		
		copts=GetEnv( "MX2_CPP_OPTS_"+opts.target.ToUpper()+"_"+opts.config.ToUpper() )
		If copts CPP_OPTS+=" "+copts
		
		copts=GetEnv( "MX2_AS_OPTS" )
		If copts AS_OPTS+=" "+copts
	End

	Method Build()
	
		If Not CreateDir( module.cacheDir ) Throw New BuildEx( "Error creating dir '"+module.cacheDir+"'" )
		
		If opts.reflection
			CC_OPTS+=" -DBB_REFLECTION"
			CPP_OPTS+=" -DBB_REFLECTION"
		Endif

		If opts.verbose=0 Print "Compiling..."
		
		Local srcs:=New StringStack

		If opts.productType="app"
		
			srcs.Push( module.rfile )
			
			For Local imp:=Eachin imports
			
				srcs.Push( imp.rfile )
			Next
			
		Endif
		
		For Local fdecl:=Eachin module.fileDecls
		
			srcs.Push( fdecl.cfile )
		Next
		
		srcs.AddAll( SRC_FILES )
		
		Build( srcs )
	End
	
	Method Build( srcs:StringStack ) Virtual
	End
	
	Method Run() Virtual
	End

	Protected
	
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
	
	Method CopyAssets( assetsDir:String )
	
		If Not assetsDir.EndsWith( "/" ) assetsDir+="/"
		
		DeleteDir( assetsDir,True )
		
		CreateDir( assetsDir )
		
		Local assetFiles:=New StringMap<String>
		
		For Local src:=Eachin ASSET_FILES
		
			Local dst:=assetsDir
		
			Local i:=src.Find( "@/" )
			If i<>-1
				dst+=src.Slice( i+2 )
				src=src.Slice( 0,i )
				If Not dst.EndsWith( "/" ) dst+="/"
			Endif
			
			Select GetFileType( src )
			
			Case FileType.File
			
				dst+=StripDir( src )
				EnumAssetFiles( src,dst,assetFiles )
				
			Case FileType.Directory
			
				EnumAssetFiles( src,dst,assetFiles )
			End
			
		Next
		
		CopyAssetFiles( assetFiles )
	End

	Method CopyDlls( dllsDir:String )
	
		If Not dllsDir.EndsWith( "/" ) dllsDir+="/"
	
		For Local src:=Eachin DLL_FILES
		
			Local dir:=dllsDir
			
			Local ext:=ExtractExt( src )
			If ext
				Local rdir:=GetEnv( "MX2_APP_DIR_"+ext.Slice( 1 ).ToUpper() )
				If rdir 
					dir=RealPath( dir+rdir )
					If Not dir.EndsWith( "/" ) dir+="/"
				Endif
			Endif
			
			Local dst:=dir+StripDir( src )
			
			'FIXME! Hack for copying frameworks on macos!
			'		
#If __HOSTOS__="macos"
			If ExtractExt( src ).ToLower()=".framework"
				CreateDir( ExtractDir( dst ) )
				If Not Exec( "rm -f -R "+dst ) Throw New BuildEx( "rm failed" )
				If Not Exec( "cp -f -R "+src+" "+dst ) Throw New BuildEx( "cp failed" )
				Continue
			Endif
#Endif
			
			If Not CopyAll( src,dst ) Throw New BuildEx( "Failed to copy '"+src+"' to '"+dst+"'" )
			
		Next
	
	End
		
	Private
		
	Method CopyAll:Bool( src:String,dst:String )
		
		Select GetFileType( src )

		Case FILETYPE_FILE
		
			If Not CreateDir( ExtractDir( dst ) ) Return False
		
'			If GetFileTime( src )>GetFileTime( dst )
				If Not CopyFile( src,dst ) Return False
'			Endif
			
			Return True
			
		Case FILETYPE_DIR
		
			If Not CreateDir( dst ) Return False
			
			For Local file:=Eachin LoadDir( src )
				If Not CopyAll( src+"/"+file,dst+"/"+file ) Return False
			Next
			
			Return True
		
		End
		
		Return False
		
	End
	
	Method CopyAssetFiles( files:StringMap<String> )
	
		For Local it:=Eachin files
		
			Local src:=it.Value
			Local dst:=it.Key
			
			If CreateDir( ExtractDir( dst ) )
			
				'If GetFileTime( dst )>=GetFileTime( src ) Continue
				
				If CopyFile( src,dst ) Continue

			Endif
			
			Throw New BuildEx( "Error copying asset file '"+src+"' to '"+dst+"'" )
		Next
	End
	
	Method EnumAssetFiles( src:String,dst:String,files:StringMap<String> )

		Select GetFileType( src )

		Case FILETYPE_FILE
		
			If Not files.Contains( dst ) files[dst]=src
			
		Case FILETYPE_DIR
		
			For Local f:=Eachin LoadDir( src )
			
				EnumAssetFiles( src+"/"+f,dst+"/"+f,files )

			Next
		
		End
		
	End
		
End

Class GccBuildProduct Extends BuildProduct

	Field AR_CMD:="ar"
	Field CC_CMD:="gcc"
	Field CXX_CMD:="g++"
	Field AS_CMD:="as"
	Field LD_CMD:="g++"
	
	Method New( module:Module,opts:BuildOpts )
		Super.New( module,opts )
		
		Select opts.target
		Case "emscripten"
			AR_CMD= "emar"
			CC_CMD= "emcc"
			CXX_CMD="em++"
			LD_CMD= "em++"
			AS_CMD= ""
		Case "raspbian"
			AR_CMD= "arm-linux-gnueabihf-ar"
			CC_CMD= "arm-linux-gnueabihf-gcc"
			CXX_CMD="arm-linux-gnueabihf-g++"
			LD_CMD= "arm-linux-gnueabihf-g++"
			AS_CMD= "arm-linux-gnueabihf-as"
		Default
			Local suffix:=GetEnv( "MX2_GCC_SUFFIX" )
			AR_CMD= "ar"
			CC_CMD= "gcc"+suffix
			CXX_CMD="g++"+suffix
			LD_CMD= "g++"+suffix
			AS_CMD= "as"
			If opts.target="ios" AS_CMD+=" -arch armv7"
		End
		
	End
	
	Method CompileSource:String( src:String )
	
		Local rfile:=src.EndsWith( "/_r.cpp" )

		Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cacheDir ) )
		If rfile And opts.reflection obj+="_r"
		obj+=".o"
		
		Local ext:=ExtractExt( src ).ToLower()
						
		Local cmd:="",isasm:=False

		Select ext
		Case ".c",".m"
			
			cmd=CC_CMD+CC_OPTS+" -c"
				
		Case ".cc",".cxx",".cpp",".mm"

			cmd=CXX_CMD+CPP_OPTS+" -c"

		Case ".asm",".s"
		
			cmd=AS_CMD+AS_OPTS
			
			isasm=True
		End
			
		'Check dependancies
		'			
		Local objTime:=GetFileTime( obj )

		'create deps file name
		'			
		Local deps:=StripExt( obj )+".deps"
		
		If opts.fast And objTime>=GetFileTime( src )	'source file up to date?
		
			If isasm Return obj
			
			Local uptodate:=True
			
			If GetFileType( deps )=FILETYPE_NONE
					
				If opts.verbose>0 Print "Scanning "+src
				
				Exec( cmd+" -MM ~q"+src+"~q >~q"+deps+"~q" ) 
			Endif
					
			Local srcs:=LoadString( deps ).Split( " \" )
					
			For Local i:=1 Until srcs.Length
					
				Local src:=srcs[i].Trim().Replace( "\ "," " )
					
				If GetFileTime( src )>objTime
					uptodate=False
					Exit
				Endif
						
			Next
				
			If uptodate Return obj
				
		Else
			
			DeleteFile( deps )

		Endif
			
		If opts.verbose>0 Print "Compiling "+src
			
		cmd+=" -o ~q"+obj+"~q ~q"+src+"~q"
			
		Exec( cmd )
		
		Return obj
	End
	
	Method Build( srcs:StringStack ) Override
		
		Local objs:=New StringStack
		
		For Local src:=Eachin srcs
		
			objs.Push( CompileSource( src ) )
		Next
		
		objs.AddAll( OBJ_FILES )
		
		If opts.productType="module"
		
			BuildModule( objs )
		
		Else
		
			BuildApp( objs )
		End
	End
	
	Method BuildModule( objs:StringStack )

		Local output:=module.afile

		Local maxObjTime:Long
		For Local obj:=Eachin objs
			maxObjTime=Max( maxObjTime,GetFileTime( obj ) )
		Next
		If GetFileTime( output )>maxObjTime Return
		
		If opts.verbose>=0 Print "Archiving "+output+"..."
		
		DeleteFile( output )
		
		Local args:=""

		For Local i:=0 Until objs.Length
			
			args+=" ~q"+objs.Get( i )+"~q"
			
			If args.Length<1000 And i<objs.Length-1 Continue

			Local cmd:=AR_CMD+" q ~q"+output+"~q"+args

			Exec( cmd )
			
			args=""
			
		Next
	End
	
	Method BuildApp( objs:StringStack ) Virtual
	
		outputFile=opts.product
		If Not outputFile outputFile=module.outputDir+module.name
		
		Local assetsDir:=ExtractDir( outputFile )+"assets/"
		
		Local dllsDir:=ExtractDir( outputFile )

		Local cmd:=LD_CMD+LD_OPTS
		
		Select opts.target
		Case "windows"
		
			If ExtractExt( outputFile ).ToLower()<>".exe" outputFile+=".exe"
		
			If opts.appType="gui" cmd+=" -mwindows"
			
		Case "macos"
		
			If opts.appType="gui"
			
				Local appDir:=outputFile
				If ExtractExt( appDir ).ToLower()<>".app" appDir+=".app"
				appDir+="/"
				
				Local appName:=StripExt( StripDir( outputFile ) )
				
				outputFile=appDir+"Contents/MacOS/"+appName
				assetsDir=appDir+"Contents/Resources/"
				dllsDir=ExtractDir( outputFile )
				
				If GetFileType( appDir )=FileType.None

					CreateDir( appDir )
					CreateDir( appDir+"Contents" )
					CreateDir( appDir+"Contents/MacOS" )
					CreateDir( appDir+"Contents/Resources" )
					
					Local plist:=""
					plist+="<?xml version=~q1.0~q encoding=~qUTF-8~q?>~n"
					plist+="<!DOCTYPE plist PUBLIC ~q-//Apple Computer//DTD PLIST 1.0//EN~q ~qhttp://www.apple.com/DTDs/PropertyList-1.0.dtd~q>~n"
					plist+="<plist version=~q1.0~q>~n"
					plist+="<dict>~n"
					plist+="~t<key>CFBundleExecutable</key>~n"
					plist+="~t<string>"+appName+"</string>~n"
					plist+="~t<key>CFBundleIconFile</key>~n"
					plist+="~t<string>"+appName+"</string>~n"
					plist+="~t<key>CFBundlePackageType</key>~n"
					plist+="~t<string>APPL</string>~n"
					plist+="~t<key>NSHighResolutionCapable</key> <true/>~n"
					plist+="</dict>~n"
					plist+="</plist>~n"
					
					SaveString( plist,appDir+"Contents/Info.plist" )
				
				Endif
			
			Endif
		
		Case "emscripten"

			assetsDir=module.outputDir+"assets/"
			
			If ExtractExt( outputFile ).ToLower()<>".js" And ExtractExt( outputFile ).ToLower()<>".html" outputFile+=".html"
			
			cmd+=" --preload-file ~q"+assetsDir+"@/assets~q"
		End
		
		If opts.verbose>=0 Print "Linking "+outputFile+"..."
		
		cmd+=" -o ~q"+outputFile+"~q"
		
		Local lnkFiles:=""
		
		For Local obj:=Eachin objs
			lnkFiles+=" ~q"+obj+"~q"
		Next
		
		If opts.wholeArchive 
#If __TARGET__="macos"
			lnkFiles+=" -Wl,-all_load"
#Else
			lnkFiles+=" -Wl,--whole-archive"
#Endif
		Endif
		
		For Local imp:=Eachin imports
			lnkFiles+=" ~q"+imp.afile+"~q"
		Next

		If opts.wholeArchive 
#If __TARGET__="macos"
'			lnkFiles+=" -Wl,-all_load"
#Else
			lnkFiles+=" -Wl,--no-whole-archive"
#Endif
		Endif
		
		lnkFiles+=" "+LD_SYSLIBS.Join( " " )
		
		If opts.target="windows"
			lnkFiles=lnkFiles.Replace( " -Wl,"," " )
			Local tmp:=AllocTmpFile( "lnkFiles" )
			SaveString( lnkFiles,tmp )
			cmd+=" -Wl,@"+tmp
		Else
			cmd+=lnkFiles
		Endif

		CopyAssets( assetsDir )
		
		CopyDlls( dllsDir )
		
		Exec( cmd )
	End
	
	Method Run() Override
	
		Local run:=""
		If opts.target="emscripten"
			Local mserver:=GetEnv( "MX2_MSERVER" )
			run=mserver+" ~q"+outputFile+"~q"
		Else
			run="~q"+outputFile+"~q"
		Endif
		
		If opts.verbose>=0 Print "Running "+outputFile
		Exec( run )
	End
	
End

Class IosBuildProduct Extends GccBuildProduct

	Method New( module:Module,opts:BuildOpts )
	
		Super.New( module,opts )
	End
	
	Method BuildApp( objs:StringStack ) Override
	
		BuildModule( objs )
		
		Local arc:=module.afile

		Local outputFile:=opts.product+"libmx2_main.a"
		
		Local cmd:="libtool -static -o ~q"+outputFile+"~q ~q"+arc+"~q"
		
		If opts.wholeArchive cmd+=" -Wl,--whole-archive"
		
		For Local imp:=Eachin imports
			cmd+=" ~q"+imp.afile+"~q"
		Next

		If opts.wholeArchive cmd+=" -Wl,--no-whole-archive"
		
		For Local lib:=Eachin LD_SYSLIBS
			If lib.ToLower().EndsWith( ".a~q" ) cmd+=" "+lib
		Next
		
		Exec( cmd )
		
		CopyAssets( opts.product+"assets/" )
	End
	
	Method Run() Override
	End
	
End

Function SplitOpts:String[]( opts:String )

	Local out:=New StringStack

	Local i0:=0
	Repeat
	
		While i0<opts.Length And opts[i0]<=32
			i0+=1
		Wend
		If i0>=opts.Length Exit

		Local i1:=opts.Find( " ",i0 )
		If i1=-1 i1=opts.Length

		Local i2:=opts.Find( "~q",i0 )
		If i2<>-1 And i2<i1
			i1=opts.Find( "~q",i2+1 )+1
			If Not i1 i1=opts.Length
		Endif

		out.Push( opts.Slice( i0,i1 ) )
		i0=i1+1
	
	Forever
	
	Return out.ToArray()
End

Class AndroidBuildProduct Extends BuildProduct

	Method New( module:Module,opts:BuildOpts )

		Super.New( module,opts )
	End
	
	Method Build( srcs:StringStack ) Override
	
		Local jniDir:=module.outputDir+"jni/"
		
		If Not CreateDir( jniDir ) Throw New BuildEx( "Failed to create dir '"+jniDir+"'" )
	
		Local buf:=New StringStack
		
		buf.Push( "APP_OPTIM := "+opts.config )
		
		buf.Push( "APP_ABI := armeabi-v7a" )
'		buf.Push( "APP_ABI := armeabi armeabi-v7a x86" )
'		buf.Push( "APP_ABI := armeabi-v7a x86" )
'		buf.Push( "APP_ABI := all" )

		buf.Push( "APP_PLATFORM := 10" )
		
		buf.Push( "APP_CFLAGS += -std=gnu99" )
		buf.Push( "APP_CPPFLAGS += -std=c++11" )
		buf.Push( "APP_CPPFLAGS += -frtti" )
		buf.Push( "APP_CPPFLAGS += -fexceptions" )
		buf.Push( "APP_STL := c++_static" )
		
		CSaveString( buf.Join( "~n" ),jniDir+"Application.mk" )
		
		buf.Clear()

		buf.Push( "LOCAL_PATH := $(call my-dir)" )
		
		If opts.productType="app"
		
			For Local imp:=Eachin imports
			
				Local src:=imp.outputDir+"obj/local/$(TARGET_ARCH_ABI)/libmx2_"+imp.name+".a"
					
				buf.Push( "include $(CLEAR_VARS)" )
				buf.Push( "LOCAL_MODULE := mx2_"+imp.name )
				buf.Push( "LOCAL_SRC_FILES := "+src )
				buf.Push( "include $(PREBUILT_STATIC_LIBRARY)" )
			Next
			
			For Local dll:=Eachin DLL_FILES
			
				buf.Push( "include $(CLEAR_VARS)" )
				buf.Push( "LOCAL_MODULE := "+StripDir( dll ) )
				buf.Push( "LOCAL_SRC_FILES := "+dll )
				buf.Push( "include $(PREBUILT_SHARED_LIBRARY)" )
			
			Next
			
		Endif
		
		buf.Push( "include $(CLEAR_VARS)" )
		
		If opts.productType="app"
			buf.Push( "LOCAL_MODULE := mx2_main" )
		Else
			buf.Push( "LOCAL_MODULE := mx2_"+module.name )
		Endif
		
		Local cc_opts:=SplitOpts( CC_OPTS )
		
		For Local opt:=Eachin cc_opts
			If opt.StartsWith( "-I" ) Or opt.StartsWith( "-D" ) buf.Push( "LOCAL_CFLAGS += "+opt )
		Next
		
		buf.Push( "LOCAL_SRC_FILES := \" )
		
		For Local src:=Eachin srcs
			buf.Push( MakeRelativePath( src,jniDir )+" \" )
		Next
		
		buf.Push( "" )

		buf.Push( "LOCAL_CFLAGS += -DGL_GLEXT_PROTOTYPES" )
		
		If opts.productType="app"
		
			buf.Push( "LOCAL_STATIC_LIBRARIES := \" )
			For Local imp:=Eachin imports	'Builder.modules.Backwards()
				If imp=module Continue
				
				buf.Push( "mx2_"+imp.name+" \" )
			Next
			buf.Push( "" )
			
			buf.Push( "LOCAL_SHARED_LIBRARIES := \" )
			For Local dll:=Eachin DLL_FILES
				buf.Push( StripDir( dll )+" \" )
			Next
			buf.Push( "" )
			
			buf.Push( "LOCAL_LDLIBS += -ldl" )
			
			For Local lib:=Eachin LD_SYSLIBS
				If lib.StartsWith( "-l" ) buf.Push( "LOCAL_LDLIBS += "+lib )
			Next
			
			buf.Push( "LOCAL_LDLIBS += -llog -landroid" )

			'This keeps the JNI functions in sdl2 alive, or it gets optimized out of the build as its unused...alas, probably keeps
			'entire static lib alive...
			'
			buf.Push( "LOCAL_WHOLE_STATIC_LIBRARIES := mx2_sdl2" )

			buf.Push( "include $(BUILD_SHARED_LIBRARY)" )
		Else

			buf.Push( "include $(BUILD_STATIC_LIBRARY)" )
		Endif
		
		CSaveString( buf.Join( "~n" ),jniDir+"Android.mk" )
		buf.Clear()
		
		Local cd:=CurrentDir()
		
		ChangeDir( module.outputDir )
		
		Exec( "ndk-build" )
		
		ChangeDir( cd )
		
		If opts.productType="app" And opts.assets And opts.dlls
		
			CopyDir( module.outputDir+"libs",opts.dlls )

			CopyAssets( opts.assets )
		
		Endif
		
	End
	
End
