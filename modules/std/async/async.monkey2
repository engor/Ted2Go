
Namespace std.async

#import "native/async.cpp"
#import "native/async.h"

#If __TARGET__="raspbian" Or __TARGET__="linux"
#Import "<libpthread.a>"	'WTH? Didn't used to need this!
#Endif

Extern

#rem monkeydoc @hidden

Internal struct used to deliver events from remote threads.

Probably best to just forget you even saw this...

#end
Struct AsyncEvent="bbAsync::Event"

	Method Dispatch()="dispatch"

End

Public
