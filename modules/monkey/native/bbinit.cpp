
#include "bbinit.h"

#include <stdio.h>

bbInit *bbInit::first;

bbInit::bbInit( const char *ident,void(*init)() ):info( info ),init( init ){
//	printf( "Registering initializer '%s'\n",info );fflush( stdout );
	succ=first;
	first=this;
}
