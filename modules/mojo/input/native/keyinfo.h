
#ifndef BB_MOJO_INPUT_KEYINFO_H
#define BB_MOJO_INPUT_KEYINFO_H

struct bbKeyInfo{
	const char *name;
	int scanCode;
	int keyCode;
};

extern bbKeyInfo bbKeyInfos[];

#endif
