//
// The big comment thing is meant to go here
//

#ifdef SCAFFOLD_BASE_FILE_4DM_INCLUDED
#error Do not include the base file!
#endif
#define SCAFFOLD_BASE_FILE_4DM_INCLUDED

#include "src/build.4dm"

void main()
// --------------------------------------------------------
// Entry point for this macro
// --------------------------------------------------------
{
    Integer ret = main_panel();
    if (ret == Shutdown_code) {
        return;
    }
}