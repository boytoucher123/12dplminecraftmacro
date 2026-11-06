#ifndef INCLUDE_BUILD_4DM
#define INCLUDE_BUILD_4DM

// Build settings

#define RELEASE
//#define DEBUG


// Build logic
#if defined(DEBUG) && defined(RELEASE)
#warning Conflicting build modes enabled <RELEASE|DEBUG>
#elif !defined(DEBUG) && !defined(RELEASE)
#warning Build mode unspecified : <RELEASE|DEBUG>
#endif

#ifdef RELEASE
#undef DEBUG
#endif


// Source files
#include "scaffold_panel.4dm"
#include "scaffold.4dm"


// Error for multiple inclusions of build.4dm
#else
#error Don't include build.4dm more than once
#endif
