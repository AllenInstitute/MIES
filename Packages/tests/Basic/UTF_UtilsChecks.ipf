#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1
#pragma ModuleName=UtilsChecksTest

static Function BetweenZeroAndOneX()

	FUNCREF SFH_NumericChecker_Prototype f = BetweenZeroAndOne
	CHECK(FuncRefIsAssigned(FuncRefInfo(f)))

	CHECK_EQUAL_VAR(BetweenZeroAndOne(-2.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOne(0.0), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(0 + 1e-15), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOne(0.1), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(1.0 - 1e-14), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOne(1.0), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOne(2.0), 0)

	FUNCREF SFH_NumericChecker_Prototype f = BetweenZeroAndOneExc
	CHECK(FuncRefIsAssigned(FuncRefInfo(f)))

	// excluding the borders
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(-2.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(0 + 1e-15), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(0.1), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(1.0 - 1e-14), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(1.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneExc(2.0), 0)
End

static Function BetweenZeroAndOneHoundredX()

	FUNCREF SFH_NumericChecker_Prototype f = BetweenZeroAndOneHoundred
	CHECK(FuncRefIsAssigned(FuncRefInfo(f)))

	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundred(-2.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundred(0.0), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(0 + 1e-15), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundred(0.1), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(100.0 - 1e-14), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundred(1.0), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundred(102.0), 0)

	FUNCREF SFH_NumericChecker_Prototype f = BetweenZeroAndOneHoundredExc
	CHECK(FuncRefIsAssigned(FuncRefInfo(f)))

	// excluding the borders
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(-2.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(0 + 1e-15), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(0.1), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(100.0 - 1e-14), 1)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(100.0), 0)
	CHECK_EQUAL_VAR(BetweenZeroAndOneHoundredExc(102.0), 0)
End

static Function TestIsStrictlyPositiveAndFinite()

	CHECK(IsStrictlyPositiveAndFinite(1))
	CHECK(!IsStrictlyPositiveAndFinite(0))
	CHECK(!IsStrictlyPositiveAndFinite(-1))
End

// UTF_TD_GENERATOR InfiniteValues
static Function TestIsStrictlyPositiveAndFiniteInfinite([variable var])

	CHECK(!IsStrictlyPositiveAndFinite(var))
End

static Function TestIsNullOrPositiveAndFinite()

	CHECK(IsNullOrPositiveAndFinite(1))
	CHECK(IsNullOrPositiveAndFinite(0))
	CHECK(!IsNullOrPositiveAndFinite(-1))
End

// UTF_TD_GENERATOR InfiniteValues
static Function TestIsNullOrPositiveAndFiniteInfinite([variable var])

	CHECK(!IsNullOrPositiveAndFinite(var))
End
