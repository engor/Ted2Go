
source common.sh

echo ""
echo "***** Updating modules *****"
echo ""

$mx2cc makemods -target=desktop -config=release
$mx2cc makemods -target=desktop -config=debug
