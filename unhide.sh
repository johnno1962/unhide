#!/bin/bash -x
#
#  unhide.sh
#  unhide
#
#  Created by John Holdsworth on 15/05/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.
#

if [ "$CONFIGURATION" = "Debug" ]; then
    NORMAL_ARCH_FILE="$OBJECT_FILE_DIR_normal/$ARCHS/$PRODUCT_NAME"
    LINK_FILE_LIST="$NORMAL_ARCH_FILE.LinkFileList"
    echo "Exporting any \"hidden\" Swift internal symbols in $PRODUCT_NAME" &&
    `dirname $0`/unhide "$PRODUCT_NAME" "$LINK_FILE_LIST" `find $(dirname $SYMROOT) -name '*.LinkFileList'`> /tmp/unhide_$USER.log &&
    exit $?
fi
