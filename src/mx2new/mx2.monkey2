
Namespace mx2

#Import "util.monkey2"

#Import "scope.monkey2"
#Import "value.monkey2"
#Import "type.monkey2"
#Import "node.monkey2"
#Import "stmt.monkey2"

#Import "errors.monkey2"
#Import "toker.monkey2"
#Import "parser.monkey2"
#Import "decl.monkey2"
#Import "expr.monkey2"
#Import "eval.monkey2"
#Import "typeexpr.monkey2"
#Import "stmtexpr.monkey2"
#Import "class.monkey2"
#Import "func.monkey2"
#Import "var.monkey2"
#Import "enum.monkey2"
#Import "property.monkey2"
#Import "alias.monkey2"
#Import "namespace.monkey2"
#Import "overload.monkey2"
#Import "module.monkey2"

#Import "translator.monkey2"
#Import "translator_cpp.monkey2"
#Import "mung.monkey2"

#Import "builder.monkey2"

Using std
Using std.stringio
Using std.chartype
Using std.filesystem
Using std.collections
Using lib.c

' Messy, but to update version:
'
' 1) Update MX2CC_VERSION below
' 2) ./updatemx2cc
' 3) edit .sh and .bat files to use new version (common.sh, updatemx2cc.bat, rebuildmx2cc.bat)
' 4) ./rebuildall
'
Const MX2CC_VERSION:="004"
