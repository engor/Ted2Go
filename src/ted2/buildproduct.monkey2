
Namespace ted2

Class BuildProduct

	Property ProductDir:String()

		Return _productDir
	End

	Method GetMx2ccOpts:String()
	
		Return OnGetMx2ccOpts()
	End
	
	Function GetBuildProduct:BuildProduct( srcPath:String,target:String,edit:Bool )
	
		Local product:BuildProduct
		
		Select target
		Case "desktop"
#if __TARGET__="windows"
			product=New WindowsProduct( srcPath )
#else if __TARGET__="macos"
			product=New MacosProduct( srcPath )
#else if __TARGET__="linux"
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
		_productsDir=StripExt( _srcPath )+".products/"
		_productDir=_productsDir+_target.Capitalize()+"/"

'		AddVar( "Product Location",StripExt( srcPath )+".products/"+_target.Capitalize()+"/","directory" )
	End
	
	Method OnGetMx2ccOpts:String() Virtual
		Return ""
	End
	
	Method OnCreateProduct() Virtual
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
		
		AddVar( "Application Name","Monkey 2 Game" )
		AddVar( "Application Type","gui","options:gui|console" )
	End
	
	Protected

	Method OnCreateProduct() Override
	
		Local appName:=GetVar( "APPLICATION_NAME" )
		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		CreateDir( ProductDir+"assets" )
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local appName:=GetVar( "APPLICATION_NAME" )
		Local appType:=GetVar( "APPLICATION_TYPE" )
		
		Local opts:=""
		opts+=" ~q-product="+ProductDir+appName+"~q"
		opts+=" -apptype="+appType
		
		Return opts
	End
	
End

Class WindowsProduct Extends DesktopProduct

	Method New( srcPath:String )
		Super.New( srcPath,"windows" )
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

		Local appName:=GetVar( "APPLICATION_NAME" )
		Local appDir:=ProductDir+appName+".app/"

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
		plist+="</dict>~n"
		plist+="</plist>~n"
					
		SaveString( plist,appDir+"Contents/Info.plist" )
	End

End

Class LinuxProduct Extends DesktopProduct

	Method New( srcPath:String )
		Super.New( srcPath,"linux" )
	End
End

Class EmscriptenProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"emscripten" )

		AddVar( "Application Name","Monkey 2 Game" )
	End
	
	Protected
	
	Method OnCreateProduct() Override

		Local appName:=GetVar( "APPLICATION_NAME" )
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local appName:=GetVar( "APPLICATION_NAME" )
	
		Local opts:=""
		opts+=" ~q-product="+ProductDir+appName+"~q"
		
		Return opts
	End

End

Class AndroidProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"android" )
		
		AddExts( New String[]( ".xml",".java",".gradle" ) )
		
		AddVar( "Application Name","Monkey 2 Game" )
		AddVar( "Package Name","com.monkey2.monkey2game" )
		AddVar( "Activity Name","Monkey2Game" )
		AddVar( "Screen Orientation","landscape","options:landscape|portrait|user" )
	End

	Protected
	
	Method OnCreateProduct() Override

		Local appName:=GetVar( "APPLICATION_NAME" )
		Local packageName:=GetVar( "PACKAGE_NAME" )
		Local activityName:=GetVar( "ACTIVITY_NAME" )
		Local screenOrientation:=GetVar( "SCREEN_ORIENTATION" )
		
		Local mainDir:=ProductDir+"app/src/main/"
		Local packageDir:=mainDir+"java/"+packageName.Replace( ".","/" )+"/"
		
		CopyTemplate( "android/Monkey2Game",StripSlashes( ProductDir ) )

		CreateDir( packageDir )
		CopyFile( mainDir+"Monkey2Game.java",packageDir+activityName+".java" )
		DeleteFile( mainDir+"Monkey2Game.java" )
	
	End
	
	Method OnGetMx2ccOpts:String() Override

		Local opts:=""
		opts+=" -assets=~q"+ProductDir+"app/src/main/assets/~q"
		opts+=" -dlls=~q"+ProductDir+"app/src/main/jniLibs/~q"
		
		Return opts
	End
	
End

Class IosProduct Extends BuildProduct

	Method New( srcPath:String )
		Super.New( srcPath,"ios" )
		
		AddVar( "Application Name","Monkey 2 Game" )
		
		AddVar( "Screen Orientation","landscape","options:landscape|portrait|user" )
	End

End
