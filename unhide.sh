#!/bin/bash -x
#
#  unhide.sh
#  unhide
#
#  Created by John Holdsworth on 15/05/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.
#

if [ "$CONFIGURATION" = "Debug" ]; then
    UNHIDE_LDFLAGS=${1:-$UNHIDE_LDFLAGS}
    NORMAL_ARCH_FILE="$OBJECT_FILE_DIR_normal/$ARCHS/$PRODUCT_NAME"
    LINK_FILE_LIST="$NORMAL_ARCH_FILE.LinkFileList"
    if [[ "$CODESIGNING_FOLDER_PATH" =~ ".framework" ]]; then
        DYNAMICLIB="-dynamiclib -install_name @rpath/$PRODUCT_NAME.framework/$PRODUCT_NAME"
        VERSIONS="-Xlinker -rpath -Xlinker @loader_path/Frameworks -dead_strip -single_module -compatibility_version 1 -current_version 1"
    else
        VERSIONS="-Xlinker -objc_abi_version -Xlinker 2 -fobjc-arc -fobjc-link-runtime -Xlinker -no_implicit_dylibs"
    fi

    echo "Exporting any \"hidden\" Swift internal symbols in $PRODUCT_NAME framework" &&
    `dirname $0`/unhide "$PRODUCT_NAME" "$LINK_FILE_LIST"> /tmp/unhide_$USER.log &&
    exit $?
fi
