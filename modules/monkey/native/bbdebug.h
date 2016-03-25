
#ifndef BB_DEBUG_H
#define BB_DEBUG_H

#include "bbstring.h"

struct bbDBFrame;

struct bbDBVar{
	const char *decl;
	void *ptr;
	
	bbString ident()const;
	
	bbString typeName()const;
	
	bbString getValue()const;
};

namespace bbDB{
	extern bbDBFrame *frames;
	extern bbDBVar *locals;
	extern bool stopper;
	
	void stop();
	
	void stopped();
	
	bbArray<bbString> *stack();
}

struct bbDBFrame{
	bbDBFrame *succ;
	bbDBVar *locals;
	const char *decl;
	const char *srcFile;
	int srcPos;
	
	bbDBFrame( const char *decl,const char *srcFile ):succ( bbDB::frames ),locals( bbDB::locals ),decl( decl ),srcFile( srcFile ){
		bbDB::frames=this;
	}
	
	~bbDBFrame(){
		bbDB::locals=locals;
		bbDB::frames=succ;
	}
};

struct bbDBBlock{
	bbDBVar *locals;
	bbDBBlock():locals( bbDB::locals ){
	}
	~bbDBBlock(){
		bbDB::locals=locals;
	}
};

inline void bbDBStmt( int srcPos ){
	bbDB::frames->srcPos=srcPos;
	if( bbDB::stopper ) bbDB::stopped();
}

inline void bbDBLocal( const char *decl,void *ptr ){
	bbDB::locals->decl=decl;
	bbDB::locals->ptr=ptr;
	++bbDB::locals;
}

#endif
