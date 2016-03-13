
Namespace std.filesystemex

Using libc

#Import "native/filesystem.h"
#Import "native/filesystem.cpp"

Extern

Function AppDirectory:String()="bbFileSystem::appDir"
Function AppPath:String()="bbFileSystem::appPath"
Function AppArgs:String[]()="bbFileSystem::appArgs"
Function CopyFile:Bool( srcPath:String,dstPath:String )="bbFileSystem::copyFile"

Public

Enum FileType
	None=0
	File=1
	Directory=2
	Unknown=3
End

#rem monkeydoc Gets the filesystem directory of the assets folder.

@return The directory app assets are stored in.

#end
Function AssetsDirectory:String()

#If __TARGET__="desktop" And __HOSTOS__="macos"
	Return AppDirectory()+"../Resources/"
#Else
	Return AppDirectory()+"assets/"
#Endif

End

#rem monkeydoc Gets the root directory of a file system path.

@param path The filesystem path.

@return The root directory of `path`, or an empty string if `path` is not an absolute path.
 
#end
Function GetRootDirectory:String( path:String )

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

#rem monkeydoc Checks if a path is root directory.

@param path The filesystem path to check.

@return True if `path` is a root directory path.

#end
Function IsRootDirectory:Bool( path:String )

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

#rem monkeydoc Check if a filesystem path is an absolute path.

An absolute path is a path that begins with a root directory.

@param path The filesystem path to check.

@return True if `path` is an absolute path.

#end
Function IsAbsolutePath:Bool( path:String )

	Return GetRootDirectory( path )<>""
End

#rem monkeydoc Strips any trailing slashes from a filesystem path.

This function will not strip slashes from a root directory path.

@param path The filesystem path.

@return The path stripped of trailing slashes.

#end
Function StripSlashes:String( path:String )

	If Not path.EndsWith( "/" ) Return path
	
	Local root:=GetRootDirectory( path )
	
	Repeat
	
		If path=root Return path

		path=path.Slice( 0,-1 )
		
	Until Not path.EndsWith( "/" )
	
	Return path
End

#rem monkeydoc Gets the parent directory component from a filesystem path.

If `path` is a root directory, `path` is returned without modification.

If `path` does not contain a parent directory, an empty string is returned.

@param path The filesystem path.

@return The parent directory of `path`.

#end
Function GetParentDirectory:String( path:String )

	path=StripSlashes( path )
	If IsRootDirectory( path ) Return path
	
	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( 0,i+1 )
	
	Return ""
End

#rem monkeydoc Strips the parent directory component from a filesystem path.

If `path` is a root directory, an empty string is returned.

If `path` does not contain a parent directory, `path` is returned without modification.

@param path The filesystem path.

@return `path` with the parent directory stripped.

#end
Function StripParentDirectory:String( path:String )

	path=StripSlashes( path )
	If IsRootDirectory( path ) Return ""

	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( i+1 )
	
	Return path
End

#rem monkeydoc Gets the extension component from a filesystem path.

@param path The filesystem path.

@return The extension component of `path`, including  the '.' if any.

#end
Function GetExtension:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return ""
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( i )
	
	Return ""
End

#rem monkeydoc Strips the extension component from a filesystem path

@param path The filesystem path.

@return The path with the extension stripped.

#end
Function StripExtension:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return path
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( 0,i )
	
	Return path
End

#rem monkeydoc Converts a path to an absolute path.

@param path The filesystem path.

@return The absolute path of `path`, taking the process current directory into account.

#end
Function GetAbsolutePath:String( path:String )

	path=GetRealPath( path )
	
	If IsAbsolutePath( path ) Return path
	
	Return GetCurrentDirectory()+path
End

#rem monkeydoc Converts a relative path to a real path.

A real path is a path with any internal './' or '../' references collapsed.

If `path` is a relative path, it is first converted to an absolute path relative to the current directory.

@param path The filesystem path.

@param The path with any './', '../' components collapsed.

#end
Function GetRealPath:String( path:String )

	Local rpath:=GetRootDirectory( path )
	If rpath path=path.Slice( rpath.Length )
	
	While path
		Local i:=path.Find( "/" )
		If i=-1 Return rpath+path
		Local t:=path.Slice( 0,i )
		path=path.Slice( i+1 )
		Select t
		Case ""
		Case "."
		Case ".."
			If Not rpath rpath=GetCurrentDirectory()
			rpath=GetParentDirectory( rpath )
		Default
			rpath+=t+"/"
		End
	Wend
	
	Return rpath
End

#rem monkeydoc Gets the time a file was most recently modified.

@param path The filesystem path.

@return The time the file at `path` was most recently modified.

#end
Function GetFileTime:Long( path:String )

	path=StripSlashes( path )

	Local st:stat_t
	
	If stat( path,Varptr st )<0 Return 0
	
	Return st.st_mtime
End

#rem monkeydoc Gets the type of the file at a filesystem path.

@param path The filesystem path.

@return The file type of the file at `path`, one of: FileType.None, FileType.File or FileType.Directory.

#end
Function GetFileType:FileType( path:String )

	path=StripSlashes( path )

	Local st:stat_t

	If stat( path,Varptr st )<0 Return FileType.None
	
	Select st.st_mode & S_IFMT
	Case S_IFREG Return FileType.File
	Case S_IFDIR Return FileType.Directory
	End
	
	Return FileType.File	'?!?
End

#rem monkeydoc Gets the current directory.

@return The current directory for the running process.

#end
Function GetCurrentDirectory:String()

	Local sz:=4096
	Local buf:=Cast<CChar Ptr>( malloc( sz ) )
	getcwd( buf,sz )
	Local path:=String.FromCString( buf )
	free( buf )
	
	path=path.Replace( "\","/" )
	If path.EndsWith( "/" ) Return path
	Return path+"/"
End

#rem monkeydoc Sets the current directory.

@param path The file system directory to make current.

#end
Function SetCurrentDirectory( path:String )

	path=StripSlashes( path )
	
	chdir( path )
End

#rem monkeydoc Loads a directory.

@param path The filesystem path of the directory to load.

@return An array containing all filenames in the `path`, excluding '.' and '..' entries.

#end
Function LoadDirectory:String[]( path:String )

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

#rem monkeydoc Creates a directory at a filesystem path.

@param path The filesystem path.

@param recursive If true, any required parent directories are also created.

@return True if a directory at `path` was successfully created or already existed.

#end
Function CreateDirectory:Bool( path:String,recursive:Bool=True )

	path=StripSlashes( path )

	If recursive
		Local parent:=GetParentDirectory( path )
		If parent And Not IsRootDirectory( parent )
			Select GetFileType( parent )
			Case FileType.None
				If Not CreateDirectory( parent,True ) Return False
			Case FileType.File
				Return False
			Case FileType.Directory
			End
		Endif
	Endif

	mkdir( path,$1ff )
	Return GetFileType( path )=FileType.Directory
End

#rem monkeydoc Deletes everything at a filesystem path.

Warning! As it's name suggests, this function recursively deletes all files and directories - use carefully!

@param path The filesystem path.

@return True if succesful.

#end
Function DeleteEverything:Bool( path:String )

	path=StripSlashes( path )

	Select GetFileType( path )
	Case FileType.None
	
		Return True
		
	Case FileType.File
	
		Return DeleteFile( path )
		
	Case FileType.Directory
	
		For Local f:=Eachin LoadDirectory( path )
			If Not DeleteEverything( path+"/"+f ) Return False
		Next
		
		rmdir( path )
		Return GetFileType( path )=FileType.None
	End
	
	Return False
End

Function DeleteDirectory:Bool( path:String,recursive:Bool=False )

	path=StripSlashes( path )

	Select GetFileType( path )
	Case FileType.None

		Return True
		
	Case FileType.File
	
		Return False
		
	Case FileType.Directory
	
		If recursive Return DeleteEverything( path )
		
		rmdir( path )
		Return GetFileType( path )=FileType.None
	End
	
	Return False
End

#rem monkeydoc Deletes a file at a filesystem path.

@path The filesystem path.

@return true if the file was successfully deleted.

#end
Function DeleteFile:Bool( path:String )

	remove( path )
	
	Return GetFileType( path )=FileType.None
End

