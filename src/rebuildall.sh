
source common.sh

echo ""
echo "***** Rebuilding mx2cc with old mx2cc *****"
echo ""

$mx2cc_old makeapp -clean -target=desktop -config=release mx2new/mx2cc.monkey2

echo ""
echo "***** Rebuilding modules with new mx2cc *****"
echo ""

$mx2cc_v001 makemods -clean -verbose -target=desktop -config=release monkey libc miniz stb std hoedown
$mx2cc_v001 makemods -clean -verbose -target=desktop -config=debug monkey libc miniz stb std hoedown

echo ""
echo "***** Rebuilding mx2cc with new mx2cc *****"
echo ""

# Make new mx2cc with new mx2cc
#
$mx2cc_v001 makeapp -clean -verbose -target=desktop -config=release mx2new/mx2cc.monkey2
cp $mx2cc_v002 $mx2cc

echo ""
echo "***** Finished! *****"
echo ""

