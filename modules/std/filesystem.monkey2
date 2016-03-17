
Namespace std.filesystem

Using libc

#Import "native/filesystem.h"
#Import "native/filesystem.cpp"

Extern

Function AppDir:String()="bbFileSystem::appDir"
Function AppPath:String()="bbFileSystem::appPath"
Function AppArgs:String[]()="bbFileSystem::appArgs"
Function CopyFile:Bool( srcPath:String,dstPath:String )="bbFileSystem::copyFile"

Public

Const FILETYPE_UNKNOWN:=-1
Const FILETYPE_NONE:=0
Const FILETYPE_FILE:=1
Const FILETYPE_DIR:=2

Function AssetsDir:String()

#If __TARGET__="desktop" And __HOSTOS__="macos"
	Return AppDir()+"../Resources/"
#Else
	Return AppDir()+"assets/"
#Endif

End

Function ExtractRootDir:String( path:String )

	If path.StartsWith( "//" ) Return "//"
	
	Local i:=path.Find( "/" )
	If i=0 Return "/"
	
	If i=-1 i=path.Length
	
	Local j:=path.Find( "://" )
	If j>0 And j<i Return path.Slice( 0,j+3 )
	
	j=path.Find( ":/" )
	If j>0 And j<i Return path.Slice( 0,j+2 )
	
	j=path.Find( "::" )
	If j>0 And j<i Return path.Slice( 0,j+2 )
	
	Return ""
	
End

Function IsRootDir:Bool( path:String )

	If path="//" Return True
	
	If path="/" Return True
	
	Local i:=path.Find( "/" )
	If i=-1 i=path.Length
	
	Local j:=path.Find( "://" )
	If j>0 And j<i Return j+3=path.Length
	
	j=path.Find( ":/" )
	If j>0 And j<i Return j+2=path.Length
	
	j=path.Find( "::" )
	If j>0 And j<i Return j+2=path.Length
	
	Return False
End

Function IsRealPath:Bool( path:String )

	Return ExtractRootDir( path )<>""
End

Function StripSlashes:String( path:String )

	If Not path.EndsWith( "/" ) Return path
	
	Local root:=ExtractRootDir( path )
	
	Repeat
	
		If path=root Return path

		path=path.Slice( 0,-1 )
		
	Until Not path.EndsWith( "/" )
	
	Return path
End

Function ExtractDir:String( path:String )

	path=StripSlashes( path )
	If IsRootDir( path ) Return path
	
	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( 0,i+1 )
	
	Return ""
End

Function StripDir:String( path:String )

	path=StripSlashes( path )
	If IsRootDir( path ) Return ""

	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( i+1 )
	
	Return path
End

Function ExtractExt:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return ""
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( i )
	
	Return ""
End

Function StripExt:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return path
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( 0,i )
	
	Return path
End

Function RealPath:String( path:String )

	Local rpath:=ExtractRootDir( path )
	If rpath
		path=path.Slice( rpath.Length )
	Else
		rpath=CurrentDir()
	Endif
	
	If Not rpath rpath=CurrentDir()
	
	While path
		Local i:=path.Find( "/" )
		If i=-1 Return rpath+path
		Local t:=path.Slice( 0,i )
		path=path.Slice( i+1 )
		Select t
		Case ""
		Case "."
		Case ".."
			rpath=ExtractDir( rpath )
		Default
			rpath+=t+"/"
		End
	Wend
	
	Return rpath
End

Function FileTime:long( path:String )

	path=StripSlashes( path )

	Local st:stat_t
	
	If stat( path,Varptr st )<0 Return 0
	
	Return libc.tolong( st.st_mtime )
End

Function FileType:Int( path:String )

	path=StripSlashes( path )

	Local st:stat_t

	If stat( path,Varptr st )<0 Return FILETYPE_NONE
	
	Select st.st_mode & S_IFMT
	Case S_IFDIR Return FILETYPE_DIR
	Case S_IFREG Return FILETYPE_FILE
	End
	
	Return FILETYPE_UNKNOWN
End

Function DeleteFile:Bool( path:String )

	remove( path )
	
	Return FileType( path )=FILETYPE_NONE
End

Function CreateDir:Bool( path:String,recursive:Bool=True )

	path=StripSlashes( path )

	If recursive
		Local parent:=ExtractDir( path )
		If parent And Not IsRootDir( parent ) 
			If FileType( parent )=FILETYPE_NONE And Not CreateDir( parent,True ) Return False
		Endif
	Endif

	mkdir( path,$1ff )

	Return FileType( path )=FILETYPE_DIR
End

Function CurrentDir:String()

	Local sz:=4096
	Local buf:=Cast<CChar Ptr>( malloc( sz ) )
	getcwd( buf,sz )
	Local path:=String.FromCString( buf )
	free( buf )
	
	path=path.Replace( "\","/" )
	If path.EndsWith( "/" ) Return path
	Return path+"/"
End

Function ChangeDir( path:String )

	path=StripSlashes( path )
	
	chdir( path )
End

Function LoadDir:String[]( path:String )

	path=StripSlashes( path )

	Local dir:=opendir( path )
	If Not dir Return Null
	
	Local files:=New StringStack
	
	Repeat
		Local ent:=readdir( dir )
		If Not ent Exit
		
		Local file:=String.FromTString( ent[0].d_name )
		If file="." Or file=".." Continue
		
		files.Push( file )
	Forever
	
	closedir( dir )
	
	Return files.ToArray()
End

Function DeleteAll:Bool( path:String )

	path=StripSlashes( path )

	Select FileType( path )
	Case FILETYPE_NONE
	
		Return True
		
	Case FILETYPE_FILE
	
		Return DeleteFile( path )
		
	Case FILETYPE_DIR
	
		For Local f:=Eachin LoadDir( path )
			If Not DeleteAll( path+"/"+f ) Return False
		Next
		
		rmdir( path )
		Return FileType( path )=FILETYPE_NONE
	End
	
	Return False
End

Function DeleteDir:Bool( path:String,recursive:Bool=True )

	path=StripSlashes( path )

	Select FileType( path )
	Case FILETYPE_NONE

		Return True

	Case FILETYPE_FILE
	
		Return False
		
	Case FILETYPE_DIR
	
		If recursive Return DeleteAll( path )
		
		rmdir( path )
		Return FileType( path )=FILETYPE_NONE
	End
	
	Return False
End

