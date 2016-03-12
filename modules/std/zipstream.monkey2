
Namespace std

#Import "<miniz.monkey2>"

Using libc
Using miniz

Class ZipStream Extends DataStream

	Method New( buf:DataBuffer )
		Super.New( buf )
	End
	
	Function Open:ZipStream( path:String,mode:String )
	
		If mode<>"r" Return Null
	
		Local i:=path.FindLast( "//" )
		If i=-1 Return Null
		
		Local stream:ZipStream
		
		Local src:=DataBuffer.Load( path.Slice( 0,i ) )
		If src

			Local zip:mz_zip_archive
			memset( Varptr zip,0,sizeof( zip ) )
			
			If mz_zip_reader_init_mem( Varptr zip,src.Data,src.Length,0 )
			
				Local index:=mz_zip_reader_locate_file( Varptr zip,path.Slice( i+2 ),"",0 )
				
				If index>=0
		
					Local stat:mz_zip_archive_file_stat
					memset( Varptr stat,0,sizeof( stat ) )
					
					If mz_zip_reader_file_stat( Varptr zip,index,Varptr stat )
					
						Local buf:=New DataBuffer( stat.m_uncomp_size )
						
						If mz_zip_reader_extract_to_mem( Varptr zip,index,buf.Data,buf.Length,0 )
						
							stream=New ZipStream( buf )
							
						Else
						
							buf.Discard()

						Endif
					
					End
				
				End
			
				mz_zip_reader_end( Varptr zip )
			End
			
			src.Discard()
			
		Endif
		
		Return stream
	End
	
End
