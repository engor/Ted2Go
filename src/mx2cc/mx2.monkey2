
Namespace mx2

#Import "util"

#Import "scope"
#Import "value"
#Import "type"
#Import "node"
#Import "stmt"
#Import "filescope"
#Import "block"

#Import "errors"
#Import "toker"
#Import "parser"
#Import "decl"
#Import "expr"
#Import "eval"
#Import "stmtexpr"
#Import "class"
#Import "func"
#Import "var"
#Import "enum"
#Import "property"
#Import "alias"
#Import "namespace"
#Import "overload"
#Import "balance"
#Import "module"
#Import "nodefinder"

#Import "translator"
#Import "translator_cpp"
#Import "mung"

#Import "builder"
#Import "buildproduct"

Using std
Using std.stringio
Using std.filesystem
Using std.collections
Using libc

' Messy, but to update version:
'
' 1) Update MX2CC_VERSION below
' 2) ./updatemx2cc
' 3) edit .sh and .bat files to use new version (common.sh, common.bat)
' 4) ./rebuildall
'
Const MX2CC_VERSION:="1.0.91"
