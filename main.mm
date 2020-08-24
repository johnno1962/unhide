//
//  main.mm
//  unhide
//
//  $Id: //depot/unhide/main.mm#19 $
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

#import <mach-o/loader.h>
#import <mach-o/nlist.h>
#import <mach-o/stab.h>

#import <string>
#import <map>

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        if ( argc < 3 ) {
            fprintf( stderr, "Usage: unhide framework link_file_list\n" );
            exit(1);
        }

        std::map<std::string,int> seen;

        const char *framework = argv[1];
        framework = [[NSString stringWithFormat:@"%zu%@", strlen(framework),
                      [NSString stringWithUTF8String:framework]] UTF8String];

        const char *linkFileList = argv[2];
        FILE *linkFiles = fopen(linkFileList, "r");
        if ( !linkFiles ) {
           fprintf( stderr, "unhide: Could not open link file list %s\n", linkFileList );
           exit(1);
        }

        char buffer[PATH_MAX];

        while ( fgets(buffer, sizeof buffer, linkFiles) ) {
            buffer[strlen(buffer)-1] = '\000';
            NSString *file = [NSString stringWithUTF8String:buffer];
            NSData *data = [[NSData alloc] initWithContentsOfFile:file];
            NSData *patched = [data mutableCopy];

            if ( !patched ) {
                fprintf( stderr, "unhide: Could not read %s\n", [file UTF8String] );
                exit(1);
            }

            struct mach_header_64 *object = (struct mach_header_64 *)[patched bytes];

            if ( object->magic != MH_MAGIC_64 ) {
                fprintf( stderr, "unhide: Invalid magic 0x%x != 0x%x (bad arch?)\n",
                        object->magic, MH_MAGIC_64 );
                exit(1);
            }

            struct symtab_command *symtab = NULL;
            struct dysymtab_command *dylib = NULL;

            for ( struct load_command *cmd = (struct load_command *)((char *)object + sizeof *object) ;
                 cmd < (struct load_command *)((char *)object + object->sizeofcmds) ;
                 cmd = (struct load_command *)((char *)cmd + cmd->cmdsize) ) {

                if ( cmd->cmd == LC_SYMTAB )
                    symtab = (struct symtab_command *)cmd;
                else if ( cmd->cmd == LC_DYSYMTAB )
                    dylib = (struct dysymtab_command *)cmd;
            }

            if ( !symtab || !dylib ) {
                fprintf( stderr, "unhide: Missing symtab or dylib cmd %s: %p & %p\n",
                        strrchr( [file UTF8String], '/' )+1, symtab, dylib );
                continue;
            }
            struct nlist_64 *all_symbols64 = (struct nlist_64 *)((char *)object + symtab->symoff);
#if 1
            struct nlist_64 *end_symbols64 = all_symbols64 + symtab->nsyms;

            printf( "%s.%s: local: %d %d ext: %d %d undef: %d %d extref: %d %d indirect: %d %d extrel: %d %d localrel: %d %d symlen: 0%lo\n",
                   framework, strrchr( [file UTF8String], '/' )+1,
                   dylib->ilocalsym, dylib->nlocalsym,
                   dylib->iextdefsym, dylib->nextdefsym,
                   dylib->iundefsym, dylib->nundefsym,
                   dylib->extrefsymoff, dylib->nextrefsyms,
                   dylib->indirectsymoff, dylib->nindirectsyms,
                   dylib->extreloff, dylib->nextrel,
                   dylib->locreloff, dylib->nlocrel,
                   (char *)&end_symbols64->n_un - (char *)object );

//            dylib->iextdefsym -= dylib->nlocalsym;
//            dylib->nextdefsym += dylib->nlocalsym;
//            dylib->nlocalsym = 0;
#endif
            for ( int i=0 ; i<symtab->nsyms ; i++ ) {
                struct nlist_64 &symbol = all_symbols64[i];
                const char *symname = (char *)object + symtab->stroff + symbol.n_un.n_strx, *symend;

//                printf( "symbol: #%d 0%lo 0x%x 0x%x %3d %s\n", i,
//                       (char *)&symbol.n_type - (char *)object,
//                       symbol.n_type, symbol.n_desc,
//                       symbol.n_sect, symname );
                if ( strncmp( symname, "_$s", 3 ) == 0 &&
//                        strstr( symname, framework ) != NULL &&
                    // unhide only default argument functions
                    // for now i.e. functions ending /A\d*_$/
                    (symend = symname + strlen(symname)) && symend[-1] == '_' &&
                    (symend[-2] == 'A' || (symend[-3] == 'A' && isdigit(symend[-2])) ||
                    (symend[-4] == 'A' && isdigit(symend[-3]) && isdigit(symend[-2]))) &&
                    symbol.n_sect && (argc == 2 || !seen[symname]++) ) {
                    if (!(symbol.n_type & N_PEXT))
                        continue;
                    symbol.n_type |= N_EXT;
                    symbol.n_type &= ~N_PEXT;
                    symbol.n_type = 0xf;
                    symbol.n_desc = N_GSYM;
                    printf( "exported: #%d 0%lo 0x%x 0x%x %3d %s\n", i,
                           (char *)&symbol.n_type - (char *)object,
                           symbol.n_type, symbol.n_desc,
                           symbol.n_sect, symname );
                }
            }

            if (![patched isEqualToData:data] &&
                ![patched writeToFile:file atomically:NO]) {
                fprintf( stderr, "unhide: Could not write %s\n", [file UTF8String] );
                exit(1);
            }
        }
    }

    return 0;
}
