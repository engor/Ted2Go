
Namespace ted2go


Class BuildProduct

	Property AppName:String()
	
		Return _appName
	End

	Property ProductDir:String()

		Return _productDir
	End

	Method GetMx2ccOpts:String()
	
		Return OnGetMx2ccOpts()
	End
	
	Method GetExecutable:String()
	
		Return OnGetExecutable()
	End
	
	Function GetBuildProduct:BuildProduct( srcPath:String,target:String,edit:Bool )
	
		Local product:BuildProduct
		
		Select target
		Case "desktop"
#if __TARGET__="windows"
			product=New WindowsProduct( srcPath )
#else if __TARGET__="macos"
			product=New MacosProduct( srcPath )
#else if __TARGET__="linux" Or __TARGET__="raspbian"
			product=New LinuxProduct( srcPath )
#endif
		Case "emscripten"
			product=New EmscriptenProduct( srcPath )
		Case "android"
			product=New AndroidProduct( srcPath )
		Case "ios"
			product=New IosProduct( srcPath )
		End
		
		If Not product Return Null
		
		product.LoadVars()

		If GetFileType( product.ProductDir )=FileType.Directory
		
			If edit And Not product.EditVars() Return Null
			
		Else

			If Not product.EditVars() Return Null
			
		Endif
		
		If GetFileType( product.ProductDir )<>FileType.Directory
		
			If Not CreateDir( product.ProductDir )
				Alert( "Failed to create product directory '"+product.ProductDir+"'" )
				Return Null
			Endif
			
			product.OnCreateProduct()

		Endif
		
		Return product
	End

	Protected
	
	Method New( srcPath:String,target:String )
	
		_srcPath=srcPath
		_target=target
		_appName=StripDir( StripExt( srcPath ) ).Capitalize()
		_productsDir=StripExt( _srcPath )+".products/"
		_productDir=_productsDir+(target="ios" ? "iOS" Else target.Capitalize())+"/"
		
		AddVar( "Application Name",_appName )
	End
	
	Method OnCreateProduct() Virtual
	End
	
	Method OnGetMx2ccOpts:String() Virtual
		Return ""
	End
	
	Method OnGetExecutable:String() Virtual
		Return ""
	End
	
	Method AddExts( exts:String[] )
	
		For Local ext:=Eachin exts
			_exts[ext]=True
		Next
	End
	
	Method AddVar( name:String,value:String,type:String="string" )
	
		_pvars.Push( New ProductVar( name,value,type ) )
	End
	
	Method GetVar:String( name:String )
	
		Return _vars[name]
	End
	
	Method ReplaceVars:String( src:String )
	
		Local i0:=0
		
		Repeat
			Local i1:=src.Find( "${",i0 )
			If i1=-1 Exit
			
			Local i2:=src.Find( "}",i1+2 )
			If i2=-1 Exit
			
			Local id:=src.Slice( i1+2,i2 )
			If Not _vars.Contains( id )
				i0=i2+1
				Continue
			Endif
			
			Local r:=_vars[id]
			src=src.Slice( 0,i1 )+r+src.Slice( i2+1 )
			i0=i1+r.Length
		Forever

		Return src
		
	End
	
	Method CopyTemplate:Bool( src:String,dst:String )

		Select GetFileType( src )
		
		Case FileType.File
		
			If _exts.Contains( ExtractExt( src ).ToLower() )
			
				Local tmp:=LoadString( src )
				
				tmp=ReplaceVars( tmp )
				
				If Not SaveString( tmp,dst ) Return False
			
			Else
			
				If Not CopyFile( src,dst ) Return False
		
			Endif
			
		Case FileType.Directory
		
			If Not CreateDir( dst ) Return False
		
			For Local f:=Eachin LoadDir( src )
			
				If Not CopyTemplate( src+"/"+f,dst+"/"+f ) Return False

			Next
				
		End
		
		Return true
	End

	Private

	Field _srcPath:String
	Field _target:String
	Field _appName:String
	Field _productDir:String
	Field _productsDir:String
	Field _exts:=New StringMap<Bool>
	Field _vars:=New StringMap<String>
	Field _pvars:=New Stack<ProductVar>
	
	Method EditVars:Bool()
	
		Local save:=New StringMap<String>
		
		For Local pvar:=Eachin _pvars
			save[pvar.name]=pvar.value
		End
	
		Local opts:=New EditProductDialog( "Build settings for "+StripDir( _srcPath )+" for "+_target.Capitalize()+" target ",_pvars )
		
		If Not opts.Run()
			For Local pvar:=Eachin _pvars
				pvar.value=save[pvar.name]
			Next
			Return False
		Endif
		
		UpdateVars()
		
		Local changed:Bool
		For Local pvar:=Eachin _pvars
			If pvar.value=save[pvar.name] Continue
			changed=True
			Exit
		Next
		
		Local fail:=False
		
		If changed And GetFileType( ProductDir )=FileType.Directory
			Select TextDialog.Run( "Edit Build Settings","Directory at '"+ProductDir+"' already exists.",New String[]( "Overwrite","Cancel" ) )
			Case 0
				If Not DeleteDir( ProductDir,True )
					Alert( "Failed to delete directory '"+ProductDir+"'" )
					fail=True
				Endif
			Case 1
				fail=True
			End
		Endif
		
		If fail
			For Local pvar:=Eachin _pvars
				pvar.value=save[pvar.name]
			Next
			UpdateVars()
			Return False
		Endif
		
		SaveVars()
		Return True
	End

	Method FindVar:ProductVar( name:String )
	
		For Local pvar:=Eachin _pvars
			If pvar.name=name Return pvar
		Next
		
		Return Null
	End
	
	Method SaveVars( jobj:JsonObject )
	
		For Local pvar:=Eachin _pvars
			jobj[pvar.name]=New JsonString( pvar.value )
		Next

	End
	
	Method LoadVars( jobj:JsonObject )
	
		For Local it:=Eachin jobj.ToObject()
			Local pvar:=FindVar( it.Key )
			If pvar pvar.value=it.Value.ToString()
		Next

		UpdateVars()
	End
	
	Method UpdateVars()

		_vars.Clear()

		For Local pvar:=Eachin _pvars
			Local id:=pvar.name.ToUpper().Replace( " ","_" )
			_vars[id]=pvar.value
		Next
		
		_appName=GetVar( "APPLICATION_NAME" )
	End
	
	Method SaveVars()
	
		Local jprods:=JsonObject.Load( _productsDir+"products.json" )
		If Not jprods jprods=New JsonObject
		
		Local jvars:=New JsonObject
		SaveVars( jvars )
		
		jprods[_target]=jvars
		
		CreateDir( _productsDir )
		SaveString( jprods.ToJson(),_productsDir+"products.json" )
	End
	
	Method LoadVars()
		
		Local jprods:=JsonObject.Load( _productsDir+"products.json" )
		If Not jprods Return
		
		Local jvars:=Cast<JsonObject>( jprods[_target] )
		If jvars LoadVars( jvars )
	End
	
End

Class DesktopProduct Extends BuildProduct

	Method New( srcPath:String,target:String )
		Super.New( srcPath,target )
		
		AddVar( "Application Type","gui","options:gui|console" )
	End
	
	Protected

	Method OnCreateProduct() Override
	
		CreateDir( ProductDir+"assets" )
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		Local opts:=""
		opts+=" ~q-product="+ProductDir+AppName+"~q"
		opts+=" -apptype="+appType
		
		Return opts
	End
	
End

Class WindowsProduct Extends DesktopProduct

	Method New( srcPath:String )
		Super.New( srcPath,"windows" )
	End

	Method OnGetMx2ccOpts:String() Override

		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		Local opts:=""
		opts+=" ~q-product="+ProductDir+AppName+"~q"
		opts+=" -apptype="+appType
		
		Return opts
	End
	
	Method OnGetExecutable:String() Override

		Return ProductDir+AppName+".exe"
	End

End

Class MacosProduct Extends DesktopProduct

	Method New( srcPath:String )

		Super.New( srcPath,"macos" )
	End
	
	Protected
	
	Method OnCreateProduct() Override
	
		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		If appType<>"gui"
			CreateDir( ProductDir+"assets" )
			Return
		Endif

		Local appDir:=ProductDir+AppName+".app/"

		CreateDir( appDir )
		CreateDir( appDir+"Contents" )
		CreateDir( appDir+"Contents/MacOS" )
		CreateDir( appDir+"Contents/Resources" )
					
		Local plist:=""
		plist+="<?xml version=~q1.0~q encoding=~qUTF-8~q?>~n"
		plist+="<!DOCTYPE plist PUBLIC ~q-//Apple Computer//DTD PLIST 1.0//EN~q ~qhttp://www.apple.com/DTDs/PropertyList-1.0.dtd~q>~n"
		plist+="<plist version=~q1.0~q>~n"
		plist+="<dict>~n"
		plist+="~t<key>CFBundleName</key>~n"
		plist+="~t<string>"+AppName+"</string>~n"
		plist+="~t<key>CFBundleExecutable</key>~n"
		plist+="~t<string>"+AppName+"</string>~n"
		plist+="~t<key>CFBundleIconFile</key>~n"
		plist+="~t<string>"+AppName+"</string>~n"
		plist+="~t<key>CFBundlePackageType</key>~n"
		plist+="~t<string>APPL</string>~n"
		plist+="~t<key>NSHighResolutionCapable</key> <true/>~n"
		plist+="</dict>~n"
		plist+="</plist>~n"
					
		SaveString( plist,appDir+"Contents/Info.plist" )
	End
	
	Method OnGetExecutable:String() Override

		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		If appType<>"gui" Return ProductDir+AppName

		Return ProductDir+AppName+".app/Contents/MacOS/"+AppName
	End

End

Class LinuxProduct Extends DesktopProduct

	Method New( srcPath:String )
#if __TARGET__="linux"
		Super.New( srcPath,"linux" )
#Else
		Super.New( srcPath,"raspbian" )
#Endif
	End

	Protected
	
	Method OnGetExecutable:String() Override

		Return ProductDir+AppName
	End
	
End

Class EmscriptenProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"emscripten" )

		AddExts( New String[]( ".html" ) )
		
		AddVar( "Application Type","wasm","options:wasm|wasm+asmjs|asmjs" )
	End
	
	Protected
	
	Method OnCreateProduct() Override

		CopyTemplate( "products/emscripten",StripSlashes( ProductDir ) )
		
		CreateDir( ProductDir+"assets" )
		
		If AppName<>"Monkey2Game"
		
			CopyFile( ProductDir+"Monkey2Game.html",ProductDir+AppName+".html" )
		
			DeleteFile( ProductDir+"Monkey2Game.html" )
		Endif
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local appType:=GetVar( "APPLICATION_TYPE" )

		Local opts:=""
		
		opts+=" ~q-product="+ProductDir+AppName+".js~q"
		opts+=" -apptype="+appType

		Return opts
	End

	Method OnGetExecutable:String() Override

		Return ProductDir+AppName+".html"
	End
End

Class AndroidProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"android" )
		
		AddExts( New String[]( ".xml",".java",".gradle" ) )
		
		AddVar( "Package Name","com.monkey2.monkey2game" )
		AddVar( "Activity Name","Monkey2Game" )
	End

	Protected
	
	Method OnCreateProduct() Override

		Local packageName:=GetVar( "PACKAGE_NAME" )
		Local activityName:=GetVar( "ACTIVITY_NAME" )
		
		Local mainDir:=ProductDir+"app/src/main/"
		Local packageDir:=mainDir+"java/"+packageName.Replace( ".","/" )+"/"
		
		CopyTemplate( "products/android/Monkey2Game",StripSlashes( ProductDir ) )

		CreateDir( packageDir )
		CopyFile( mainDir+"Monkey2Game.java",packageDir+activityName+".java" )
		DeleteFile( mainDir+"Monkey2Game.java" )
	
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local opts:=""
		opts+=" ~q-product="+ProductDir+"~q"
		
		Return opts
	End
	
End

Class IosProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"ios" )
		
		AddExts( New String[]( ".pbxproj" ) )
	End
	
	Method OnCreateProduct() Override

		CopyTemplate( "products/ios",StripSlashes( ProductDir ) )
		
		If AppName<>"Monkey2Game"
			libc.rename( ProductDir+"Monkey2Game.xcodeproj",ProductDir+AppName+".xcodeproj" )
		Endif
	End
	
	Method OnGetMx2ccOpts:String() Override
	
		Local opts:=""
		opts+=" ~q-product="+ProductDir+"~q"
		
		Return opts
	End
	

End
