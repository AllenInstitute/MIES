#pragma rtGlobals = 1
#pragma version = 1.0
#pragma IgorVersion = 6.0

//==============================================================================
// tango_loader.ipf
//------------------------------------------------------------------------------
// N.Leclercq - SOLEIL
//==============================================================================

//==============================================================================
// DEPENDENCIES
//==============================================================================
#include "tango_panel"
#include "tango_monitor"
#include "tango_code_generator"

//==============================================================================
// Menu: Tango
//==============================================================================
Menu "Tango"
	"TANGO Browser...",Execute/P/Q "tango_panel()"
	"-"
	"Kill all Monitors",Execute/P/Q "tmon_kill_all_monitors()"
end

//==============================================================================
// fonction : IgorStartOrNewHook
//------------------------------------------------------------------------------
// IgorStartOrNewHook is a user-defined function that Igor calls when Igor is 
// first launched and then whenever a new experiment is being created. Igor 
// ignores the value returned by IgorStartOrNewHook.
//==============================================================================
static function IgorStartOrNewHook(igorAppNameStr)
	String igorAppNameStr
 	SetIgorHook IgorBeforeNewHook=tango_cleanup
 	SetIgorHook IgorQuitHook=tango_cleanup
 	tools_df_make("root:tango:common", 0);
 	print "Tango-Binding::welcome!"
 	tango_load_prefs()
 	print "Tango-Binding::initialization done!"
end

//==============================================================================
// function: tango_cleanup
//==============================================================================
static function tango_cleanup (igorAppNameStr)
 String igorAppNameStr
 tmon_kill_all_monitors()
 tango_monitor_stop("*","*")
 print "Tango-Binding::monitors killed"
 tango_save_prefs()
 print "Tango-Binding::preferences saved"
 print "Tango-Binding::bye!"
end

