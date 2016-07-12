
#import "<libc>"

#import "native/stb-vorbis.c"
#import "native/stb-vorbis.h"

Namespace stb.vorbis

Extern

#rem

extern int stb_vorbis_decode_memory(const unsigned char *mem, int len, int *channels, int *sample_rate, short **output);

// decode an entire file and output the data interleaved into a malloc()ed
// buffer stored in *output. The return value is the number of samples
// decoded, or -1 if the file could not be opened or was not an ogg vorbis file.
// When you're done with it, just free() the pointer returned in *output.

#end

Function stb_vorbis_decode_memory:Int( mem:UByte Ptr,len:Int,channels:Int Ptr,sample_rate:Int Ptr,output:Short Ptr Ptr )
