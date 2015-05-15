#!/bin/bash
#
#  unhide.sh
#  unhide
#
#  Created by John Holdsworth on 15/05/2015.
#  Copyright (c) 2015 John Holdsworth. All rights reserved.
#

if [ "$CONFIGURATION" = "Debug" ]; then
    export NORMAL_ARCH_FILE="$OBJECT_FILE_DIR_normal/$CURRENT_ARCH/$PRODUCT_NAME"
    export LINK_FILE_LIST="$NORMAL_ARCH_FILE.LinkFileList"

    # this exports any "hidden" Swift internal symbols in $PRODUCT_NAME framework
    `dirname $0`/unhide "$PRODUCT_NAME" `cat $LINK_FILE_LIST`> /tmp/unhide_$USER.log

    # relink with the patched object files
    cd "$PROJECT_ROOT"
    export PATH="$PLATFORM_DEVELOPER_BIN_DIR:$SYSTEM_DEVELOPER_BIN_DIR:/usr/bin:/bin:/usr/sbin:/sbin"
    "$DT_TOOLCHAIN_DIR/usr/bin/clang" -arch "$CURRENT_ARCH" -dynamiclib -isysroot "$SDKROOT" -L"$TARGET_BUILD_DIR" -F"$TARGET_BUILD_DIR" -filelist "$LINK_FILE_LIST" -install_name "@rpath/$PRODUCT_NAME.framework/$PRODUCT_NAME" -Xlinker -rpath -Xlinker "@executable_path/Frameworks" -Xlinker -rpath -Xlinker "@loader_path/Frameworks" -dead_strip -L"$DT_TOOLCHAIN_DIR/usr/lib/swift/$PLATFORM_NAME" -Xlinker -add_ast_path -Xlinker "$NORMAL_ARCH_FILE.swiftmodule" -miphoneos-version-min=8.0 -single_module -compatibility_version 1 -current_version 1 -Xlinker -dependency_info -Xlinker "$LD_DEPENDENCY_INFO_FILE" -o "$CODESIGNING_FOLDER_PATH/$PRODUCT_NAME"
fi
