
#ifndef BB_STD_PROCESS_H
#define BB_STD_PROCESS_H

#include <bbmonkey.h>

class bbProcess : public bbObject{
public:

	bbProcess();
	~bbProcess();
	
	void discard();
	
	bbFunction<void()> finished;
	bbFunction<void()> stdoutReady;
	
	bbBool start( bbString cmd );
	
	bbInt exitCode();
	
	bbInt stdoutAvail();
	
	bbString readStdout();
	
	bbInt readStdout( void *buf,bbInt count );
	
	void writeStdin( bbString str );
	
	void sendBreak();
	
	void terminate();
	
private:
	struct Rep;
	
	Rep *_rep;
};

#endif
