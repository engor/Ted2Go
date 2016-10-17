
***** SETUP *****

You will need to install LLVM binaries into c2mx2/LLVM directory:

http://llvm.org/releases/download.html

For windows, use 32 bit binaries.

You will also need mingw-64 in your system PATH.

To launch, just run src/c2mx2/c2mx2.monkey2 from inside Ted2.

There are some sample cmx2.json config files in the chipmunk and sqlite module dirs.


***** USAGE *****

C2mx2 is a simple C header to Monkey2 'Extern' convertor that uses the libclang library.

When you run C2mx2, you will be prompted for a json config file. Once selected, conversion will start. The config file should contain:

"inputFile" (string) The 'root' file to convert.

"outputFile" (string) The output monkey2 file.

"clangArgs" (string array) array of clang cmd line arguments.

"includeFiles" (string array) array of files to process. If missing, all files are processed. Mutually exclusive with "excludeFiles".

"excludeFiles" (string array) array of files to ignore. If missing, no files are ignored. Mutually exclusive with "includeFiles".

"cstringTypes" (string array) Array of C types to treat as Monkey2 CString types. Each element must be one of: "const char *", "const signed char *", "const unsigned char *", "char *", "signed char *", "unsigned char *". If missing, defaults to ["const char *"].

"anonEnumType" (string) Monkey2 type to use for anonymous enums, defaults to "Int".

"externStructs" (string array) Array of 'undeclared' structs that are referenced but not defined in C code. C2mx2 will create 'empty' structs for each of these unless it finds a definition for them somewhere in the C code.

"header" (string array) Array of lines to emit at the top of the output code.

"footer" (string array) Array of lines to emit at the bottom of the output code.


***** LIMITATIONS *****

* Can't do C++.

* Can't do #define's.

* Can't do structs in structs.

* C2mx2 tries its best, but monkey2 is NOT C and there may be some things that need tweaking in the output file.
