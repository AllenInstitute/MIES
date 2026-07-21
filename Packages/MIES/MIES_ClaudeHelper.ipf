#pragma TextEncoding     = "UTF-8"
#pragma rtGlobals        = 3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors = 1

#ifdef AUTOMATED_TESTING
#pragma ModuleName = MIES_CH
#endif // AUTOMATED_TESTING

/// @file MIES_ClaudeHelper.ipf
/// @brief Helper functions for the Igor Pro Bridge MCP server (tools/igor-mcp-bridge)

#ifdef IGOR_PRO_BRIDGE

/// AfterCompiledHook() is a predefined Igor hook: Igor calls it after ALL procedure
/// windows have compiled successfully (confirmed from Igor Pro Folder/Igor Help
/// Files/Advanced Topics.ihf). It is declared static so it coexists with any other
/// file's own static AfterCompiledHook() (e.g. the one in MIES_Include.ipf used only
/// for the too-old-Igor warning panel) without colliding.
///
/// It records a monotonically increasing counter in root:gClaudeHelperCompileCounter
/// each time it fires. This gives the Igor Pro Bridge bridge a compile confirmation
/// driven by Igor itself, rather than only inferred by polling FunctionInfo() for a
/// non-existing function -- which can read stale state before Igor's operation queue
/// (RELOAD CHANGED PROCS / COMPILEPROCEDURES) has actually drained. There is no
/// equivalent Igor hook for a *failed* compile, so this only helps confirm success,
/// not detect failure.

static Function AfterCompiledHook()

	// Bare Variable/G (no initializer) is safe to call unconditionally: per Igor
	// Reference.ihf, /G "overwrites any existing variable" but "the variable is
	// initialized when it is created if you supply the initial value" -- i.e. the
	// overwrite-to-a-value only happens when an initializer is given. Without one,
	// this creates the global at 0 the first time and leaves an existing value
	// alone on every call after that, so no NVAR_Exists guard is needed.
	variable/G root:gClaudeHelperCompileCounter
	NVAR gClaudeHelperCompileCounter = root:gClaudeHelperCompileCounter

	gClaudeHelperCompileCounter += 1

	return 0
End
#endif // IGOR_PRO_BRIDGE
