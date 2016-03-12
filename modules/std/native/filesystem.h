
#ifndef BB_FILESYSTEM_H
#define BB_FILESYSTEM_H

#include <bbmonkey.h>

namespace bbFileSystem{

	bbString appDir();
	
	bbString appPath();
	
	bbArray<bbString> *appArgs();
	
	bbBool copyFile( bbString srcPath,bbString dstPath );
}

#endif
