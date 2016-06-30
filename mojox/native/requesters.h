
#ifndef BB_REQUESTERS_H
#define BB_REQUESTERS_H

#include <bbmonkey.h>

namespace bbRequesters{

	void Notify( bbString title,bbString text,bbBool serious );

	bbBool Confirm( bbString title,bbString text,bbBool serious );

	bbInt Proceed( bbString title,bbString text,bbBool serious );

	bbString RequestFile( bbString title,bbString filters,bbBool save,bbString path );

	bbString RequestDir( bbString title,bbString dir );
}

#endif
