
Namespace std.async

#import "native/async.cpp"
#import "native/async.h"

Extern

#rem monkeydoc @hidden

Internal struct used to deliver events from remote threads.

#end
Struct AsyncEvent="bbAsync::Event"
	
	Method Dispatch()="dispatch"

End

Public
