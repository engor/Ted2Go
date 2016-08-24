
Namespace mx2

Class BuildProduct

	Field module:Module
	Field opts:BuildOpts
	
	Field outputFile:String

	Field LD_OPTS:=New StringStack	
	Field CC_OPTS:=New StringStack
	Field CPP_OPTS:=New StringStack

	Field SRC_FILES:=New StringStack
	Field OBJ_FILES:=New StringStack
	Field LD_LIBS:=New StringStack
	Field LD_SYSLIBS:=New StringStack
	Field DLL_FILES:=New StringStack
	Field ASSET_FILES:=New StringStack
	
	Method New( module:Module,opts:BuildOpts )
		Self.module=module
		Self.opts=opts
		
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
		
	End

	Method Build() Virtual
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
			
				If GetFileTime( dst )>=GetFileTime( src ) Continue
				
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
	
	Field maxObjTime:Long

	Method New( module:Module,opts:BuildOpts )
		Super.New( module,opts )
		
		Select opts.target
		Case "emscripten"
			AR_CMD= "emar"
			CC_CMD= "emcc"
			CXX_CMD="em++"
			LD_CMD= "em++"
			AS_CMD= ""
		Default
			AR_CMD= "ar"
			CC_CMD= "gcc"
			CXX_CMD="g++"
			LD_CMD= "g++"
			AS_CMD= "as"
		End
		
	End
	
	Method Build() Override

		If opts.verbose=0 Print "Compiling...."
		
		If Not CreateDir( module.cacheDir ) Throw New BuildEx( "Error create dir '"+module.cacheDir+"'" )
		
		For Local src:=Eachin SRC_FILES
		
			Local obj:=module.cacheDir+MungPath( MakeRelativePath( src,module.cacheDir ) )+".o"
			
			Local ext:=ExtractExt( src ).ToLower()
						
			Local cmd:="",isasm:=False
			
			Select ext
			Case ".c",".m"
			
				cmd=CC_CMD+" "+CC_OPTS.Join( " " )
				cmd+=" -I~q"+MODULES_DIR+"monkey/native~q"
				cmd+=" -I~q"+MODULES_DIR+"~q"
				If APP_DIR cmd+=" -I~q"+APP_DIR+"~q"
				
			Case ".cc",".cxx",".cpp",".mm"

				cmd=CXX_CMD+" "+CPP_OPTS.Join( " " )
				cmd+=" -I~q"+MODULES_DIR+"monkey/native~q"
				cmd+=" -I~q"+MODULES_DIR+"~q"
				If APP_DIR cmd+=" -I~q"+APP_DIR+"~q"

			Case ".asm",".s"
			
				cmd=AS_CMD
				isasm=True
			End
			
			'Check dependancies
			'			
			Local objTime:=GetFileTime( obj )
			
			Local deps:=StripExt( obj )+".deps"
			
			If opts.fast And objTime>=GetFileTime( src )	'source file up to date?
			
				Local uptodate:=True
			
				If Not isasm
			
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
				
				Endif
				
				If uptodate
					maxObjTime=Max( maxObjTime,objTime )
					OBJ_FILES.Push( obj )
					Continue
				Endif
				
			Else
			
				DeleteFile( deps )

			Endif
			
			If opts.verbose>0 Print "Compiling "+src
			
			If Not isasm cmd+=" -c"
			
			cmd+=" -o ~q"+obj+"~q ~q"+src+"~q"
			
			Exec( cmd )
			
			maxObjTime=Max( maxObjTime,GetFileTime( obj ) )
			
			OBJ_FILES.Push( obj )
			
		Next
	
		Select opts.productType
		Case "app"
			CreateApp()
		Case "module"
			CreateArchive()
		End
	
	End
	
	Method CreateApp()
	
		Local assetsDir:="",dllsDir:=""
		
		Local cmd:=LD_CMD
		cmd+=" "+LD_OPTS.Join( " " )
		
		If opts.target="desktop" And HostOS="windows"
		
			If opts.appType="gui" cmd+=" -mwindows"
		
			outputFile=module.outputDir+module.name+".exe"
			assetsDir=module.outputDir+"assets/"
			dllsDir=ExtractDir( outputFile )
			
		Else If opts.target="desktop" And HostOS="macos"
		
			If opts.appType="gui"
			
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
				
			Else
			
				outputFile=module.outputDir+module.name
				assetsDir=module.outputDir+"assets/"
				dllsDir=ExtractDir( outputFile )
			
			Endif
			
		Else If opts.target="desktop" And HostOS="linux"
		
			outputFile=module.outputDir+module.name
			assetsDir=module.outputDir+"assets/"
			dllsDir=ExtractDir( outputFile )
			
		Else If opts.target="emscripten"
		
			outputFile=module.outputDir+module.name+".html"
			assetsDir=module.outputDir+"assets/"
			dllsDir=ExtractDir( outputFile )
			
'			Note: mserver can't handle --emrun as it tries to POST stdout
'			cmd="em++ --emrun --preload-file ~q"+assetsDir+"@/assets~q"

			cmd+=" --preload-file ~q"+assetsDir+"@/assets~q"
			
		Endif
		
		If opts.verbose>=0 Print "Linking "+outputFile
		
		CopyAssets( assetsDir )
		
		cmd+=" -o ~q"+outputFile+"~q"
		
		Local lnkFiles:=""
		
		For Local obj:=Eachin OBJ_FILES
			lnkFiles+=" ~q"+obj+"~q"
		Next
		
		For Local lib:=Eachin LD_LIBS
			lnkFiles+=" ~q"+lib+"~q"
		Next
	
		lnkFiles+=" "+LD_SYSLIBS.Join( " " )
		
		If HostOS="windows" And opts.target="desktop"
			Local tmp:=AllocTmpFile( "lnkFiles" )
			SaveString( lnkFiles,tmp )
			cmd+=" -Wl,@"+tmp
		Else
			cmd+=lnkFiles
		Endif

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
	
	Method CreateArchive:String()

		Local outputFile:=module.outputDir+module.name+".a"
		
		'AR is slow! This is probably not quite right, but it'll do for now...
		If GetFileTime( outputFile )>maxObjTime Return outputFile
		
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
		
		Return outputFile
		
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
	
Class AndroidBuildProduct Extends BuildProduct

	Method New( module:Module,opts:BuildOpts )
		Super.New( module,opts )
	End
	
	Method Build() Override
	
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
		
			For Local extmod:=Eachin Builder.instance.modules
				If extmod=module continue
			
				Local src:=extmod.outputDir+"obj/local/$(TARGET_ARCH_ABI)/libmx2_"+extmod.name+".a"
					
				buf.Push( "include $(CLEAR_VARS)" )
				buf.Push( "LOCAL_MODULE := mx2_"+extmod.name )
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
		
		buf.Push( "LOCAL_CFLAGS += -I~q"+MODULES_DIR+"monkey/native~q" )
		buf.Push( "LOCAL_CFLAGS += -I~q"+MODULES_DIR+"~q" )
		If APP_DIR buf.Push( "LOCAL_CFLAGS += -I~q"+APP_DIR+"~q" )
		
		For Local opt:=Eachin CC_OPTS
			If opt.StartsWith( "-I" ) buf.Push( "LOCAL_CFLAGS += "+opt )
		Next
		
		buf.Push( "LOCAL_SRC_FILES := \" )
		For Local src:=Eachin SRC_FILES
			buf.Push( MakeRelativePath( src,jniDir )+" \" )
		Next
		buf.Push( "" )
		
		If opts.productType="app"
		
			buf.Push( "LOCAL_STATIC_LIBRARIES := \" )
			For Local extmod:=Eachin Builder.instance.modules.Backwards()
				If extmod=module Continue
				
				buf.Push( "mx2_"+extmod.name+" \" )
			Next
			buf.Push( "" )
			
			buf.Push( "LOCAL_SHARED_LIBRARIES := \" )
			For Local dll:=Eachin DLL_FILES
				buf.Push( StripDir( dll )+" \" )
			Next
			buf.Push( "" )
			
			For Local lib:=Eachin LD_SYSLIBS
				If lib.StartsWith( "-l" ) buf.Push( "LOCAL_LDLIBS += "+lib )
			Next
			
			'This keeps the JNI functions in sdl2 alive, or it gets optimized out of the build as its unused...
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
		
		If opts.productType="app"
		
			CopyAssets( module.outputDir+"assets/" )
		
		Endif
		
	End
	
End
