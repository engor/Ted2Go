
source common.sh

echo ""
echo "***** Updating mx2cc *****"
echo ""

$mx2cc makeapp -config=release mx2new/mx2cc.monkey2
cp $mx2cc_v002 $mx2cc
