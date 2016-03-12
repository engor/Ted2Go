
source common.sh

echo ""
echo "***** Rebuilding mx2cc *****"
echo ""

$mx2cc makeapp -clean -config=release mx2new/mx2cc.monkey2
cp $mx2cc_v002 $mx2cc
