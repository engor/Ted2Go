
source common.sh

echo ""
echo "***** Updating mx2cc *****"
echo ""

$mx2cc makeapp -apptype=console -config=release ../src/mx2cc/mx2cc.monkey2
cp "$mx2cc_new" "$mx2cc"
