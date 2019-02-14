#! /bin/bash

echo "*** file lists for $1 ***"
echo $1

JOURNAL=`echo $1 | sed s@_content/@@`
echo $JOURNAL
ls $1 | sed -e s/^/\\tevis:${JOURNAL}-/ #| sed -e s/$/\\t\\t/

#tab.evis:hawd-dirname.tab.tab.dirname
exit 0
