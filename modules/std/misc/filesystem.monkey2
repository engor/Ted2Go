
Namespace std.filesystem

Using libc

#Import "native/filesystem.h"
#Import "native/filesystem.cpp"

Extern

#rem monkeydoc Gets application directory.

@return The directory containing the application executable.

#end
Function AppDir:String()="bbFileSystem::appDir"

#rem monkeydoc Gets the application file path.

@return The path of the application executable.

#end
Function AppPath:String()="bbFileSystem::appPath"

#rem monkeydoc Gets application command line arguments.

@return The application command line arguments.
#end
Function AppArgs:String[]()="bbFileSystem::appArgs"

#rem monkeydoc Copies a file.

@return True if the file was successfully copied.

#end
Function CopyFile:Bool( srcPath:String,dstPath:String )="bbFileSystem::copyFile"

Public

#rem monkeydoc FileType enumeration.

| FileType		| Description
|:--------------|:-----------
| `None`		| File does not exist.
| `File`		| File is a normal file.
| `Directory`	| File is a directory.
| `Unknown`		| File is of unknown type.

#end
Enum FileType
	None=0
	File=1
	Directory=2
	Unknown=3
End

'For backward compatibility - don't use!
'
#rem monkeydoc @hidden
#end
Const FILETYPE_NONE:=FileType.None

#rem monkeydoc @hidden
#end
Const FILETYPE_FILE:=FileType.File

#rem monkeydoc @hidden
#end
Const FILETYPE_DIR:=FileType.Directory

#rem monkeydoc @hidden
#end
Const FILETYPE_UNKNOWN:=FileType.Unknown

#rem monkeydoc Gets the filesystem directory of the assets folder.

@return The directory app assets are stored in.

#end
Function AssetsDir:String()

#If __TARGET__="desktop" And __HOSTOS__="macos"
	Return AppDir()+"../Resources/"
#Else
	Return AppDir()+"assets/"
#Endif

End

#rem monkeydoc Extracts the root directory from a file system path.

@param path The filesystem path.

@return The root directory of `path`, or an empty string if `path` is not an absolute path.
 
#end
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

#rem monkeydoc Checks if a path is a root directory.

@param path The filesystem path to check.

@return True if `path` is a root directory path.

#end
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

#rem monkeydoc Strips any trailing slashes from a filesystem path.

This function will not strip slashes from a root directory path.

@param path The filesystem path.

@return The path stripped of trailing slashes.

#end
Function StripSlashes:String( path:String )

	If Not path.EndsWith( "/" ) Return path
	
	Local root:=ExtractRootDir( path )
	
	Repeat
	
		If path=root Return path

		path=path.Slice( 0,-1 )
		
	Until Not path.EndsWith( "/" )
	
	Return path
End

#rem monkeydoc Extracts the directory component from a filesystem path.

If `path` is a root directory it is returned without modification.

If `path` does not contain a directory component, an empty string is returned.

@param path The filesystem path.

@return The directory component of `path`.

#end
Function ExtractDir:String( path:String )

	path=StripSlashes( path )
	If IsRootDir( path ) Return path
	
	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( 0,i+1 )
	
	Return ""
End

#rem monkeydoc Strips the directory component from a filesystem path.

If `path` is a root directory an empty string is returned.

If `path` does not contain a directory component, `path` is returned without modification.

@param path The filesystem path.

@return The path with the directory component stripped.

#end
Function StripDir:String( path:String )

	path=StripSlashes( path )
	If IsRootDir( path ) Return ""

	Local i:=path.FindLast( "/" )
	If i>=0 Return path.Slice( i+1 )
	
	Return path
End

#rem monkeydoc Extracts the extension component from a filesystem path.

@param path The filesystem path.

@return The extension component of `path` including  the '.' if any.

#end
Function ExtractExt:String( path:String )

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
Function StripExt:String( path:String )

	Local i:=path.FindLast( "." )
	If i=-1 Return path
	
	Local j:=path.Find( "/",i+1 )
	If j=-1 Return path.Slice( 0,i )
	
	Return path
End

#rem monkeydoc Converts a path to a real path.

If `path` is a relative path, it is first converted into an absolute path by prefixing the current directory.

Then, any internal './' or '../' references in the path are collapsed.

@param path The filesystem path.

@return An absolute path with any './', '../' references collapsed.

#end
Function RealPath:String( path:String )

	Local rpath:=ExtractRootDir( path )
	If rpath 
		path=path.Slice( rpath.Length )
	Else
		rpath=CurrentDir()
	Endif
	
	While path
		Local i:=path.Find( "/" )
		If i=-1 Return rpath+path
		Local t:=path.Slice( 0,i )
		path=path.Slice( i+1 )
		Select t
		Case ""
		Case "."
		Case ".."
			If Not rpath rpath=CurrentDir()
			rpath=ExtractDir( rpath )
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
	
	Return libc.tolong( st.st_mtime )
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
	
	Return FileType.Unknown
End

#rem monkeydoc Gets the process current directory.

@return The current directory for the running process.

#end
Function CurrentDir:String()

	Local sz:=4096
	Local buf:=Cast<char_t Ptr>( malloc( sz ) )
	getcwd( buf,sz )
	Local path:=String.FromCString( buf )
	free( buf )
	
	path=path.Replace( "\","/" )
	If path.EndsWith( "/" ) Return path
	Return path+"/"
End

#rem monkeydoc Changes the process current directory.

@param path The filesystem path of the directory to make current.

#end
Function ChangeDir( path:String )

	path=StripSlashes( path )
	
	chdir( path )
End

#rem monkeydoc Loads a directory.

@param path The filesystem path of the directory to load.

@return An array containing all filenames in the `path`, excluding '.' and '..' entries.

#end
Function LoadDir:String[]( path:String )

	path=StripSlashes( path )

	Local dir:=opendir( path )
	If Not dir Return Null
	
	Local files:=New StringStack
	
	Repeat
		Local ent:=readdir( dir )
		If Not ent Exit
		
		Local file:=String.FromCString( ent[0].d_name )
		If file="." Or file=".." Continue
		
		files.Push( file )
	Forever
	
	closedir( dir )
	
	Return files.ToArray()
End

#rem monkeydoc Creates a directory at a filesystem path.

@param path The filesystem path of ther directory to create.

@param recursive If true, any required parent directories are also created.

@return True if a directory at `path` was successfully created or already existed.

#end
Function CreateDir:Bool( path:String,recursive:Bool=True )

	path=StripSlashes( path )

	If recursive
		Local parent:=ExtractDir( path )
		If parent And Not IsRootDir( parent )
			Select GetFileType( parent )
			Case FileType.None
				If Not CreateDir( parent,True ) Return False
			Case FileType.File
				Return False
			Case FileType.Directory
			End
		Endif
	Endif

	mkdir( path,$1ff )
	Return GetFileType( path )=FileType.Directory
End

Private

Function DeleteAll:Bool( path:String )

	Select GetFileType( path )
	Case FileType.None
	
		Return True
		
	Case FileType.File
	
		Return DeleteFile( path )
		
	Case FileType.Directory
	
		For Local f:=Eachin LoadDir( path )
			If Not DeleteAll( path+"/"+f ) Return False
		Next
		
		rmdir( path )
		Return GetFileType( path )=FileType.None
	End
	
	Return False
End

Public

#rem monkeydoc Deletes a directory at a filesystem path.

@param path The filesystem path.

@param recursive True to delete subdirectories too.

@return True if the directory was successfully deleted or never existed.

#end
Function DeleteDir:Bool( path:String,recursive:Bool=False )

	path=StripSlashes( path )

	Select GetFileType( path )
	Case FileType.None

		Return True
		
	Case FileType.File
	
		Return False
		
	Case FileType.Directory
	
		If recursive Return DeleteAll( path )
		
		rmdir( path )
		Return GetFileType( path )=FileType.None
	End
	
	Return False
End

#rem monkeydoc Deletes a file at a filesystem path.

@param path The filesystem path.

@return True if the file was successfully deleted.

#end
Function DeleteFile:Bool( path:String )

	remove( path )
	Return GetFileType( path )=FileType.None
End

