//
//  main.mm
//  unhide
//
//  $Id: //depot/unhide/main.m#1 $
//
//  exports "hidden" symbols in a set of object files allowing them
//  to be used to create a Swift framework that can be "injected".
//  This is required as dynamic loading a class in the framework can
//  require access to "internal" methods, functions and variables.
//  These symbols now have "hidden" visibility since Swift 1.2.
//
//  Created by John Holdsworth on 13/05/2015.
//  Copyright (c) 2015 John Holdsworth. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Unhide.h"

int main(int argc, const char * argv[]) {
    if ( argc < 3 ) {
        fprintf( stderr, "Usage: unhide framework link_file_list...\n" );
        exit(1);
    }

    static char fileListPath[PATH_MAX];

    for (int arg=2; arg<argc; arg++) {
        strcat(fileListPath, argv[arg]);
        if (unhide_symbols(argv[1], fileListPath))
            strcat(fileListPath, " ");
        else
            fileListPath[0] = '\000';
    }

    return 0;
}
