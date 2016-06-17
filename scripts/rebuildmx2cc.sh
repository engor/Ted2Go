
source common.sh

echo ""
echo "***** Rebuilding mx2cc *****"
echo ""

$mx2cc makeapp -apptype=console -clean -config=release ../src/mx2new/mx2cc.monkey2
cp "$mx2cc_new" "$mx2cc"
