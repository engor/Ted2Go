
#include "bbthread.h"

#if BB_THREADED

//thread_local bbThread *bbThread::_current;
__thread bbThread *bbThread::_current;

#endif
