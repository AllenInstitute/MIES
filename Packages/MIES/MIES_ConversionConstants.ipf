#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3 // Use modern global access method and strict wave access.
#pragma rtFunctionErrors=1

#ifdef AUTOMATED_TESTING
#pragma ModuleName=MIES_CONV
#endif

/// @name Conversion constants for decimal multiples
///
/// These must be used only with `*` to avoid confusion, the inverse exists
/// as well, so this is no limitation.
///
/// Example:
///
/// \rst
/// .. code-block:: igorpro
///
///    // pA -> A
///    value_A = value_pA * PICO_TO_ONE
///
///    // V -> mV
///    value_mV = value_V * ONE_TO_MILLI
/// \endrst
///
/// Generated code from GenerateMultiplierConstants().
/// @{
Constant   ONE_TO_YOTTA = 1e-24
Constant   ONE_TO_ZETTA = 1e-21
Constant   ONE_TO_EXA   = 1e-18
Constant   ONE_TO_PETA  = 1e-15
Constant   ONE_TO_TERA  = 1e-12
Constant   ONE_TO_GIGA  = 1e-09
Constant   ONE_TO_MEGA  = 1e-06
Constant   ONE_TO_KILO  = 1e-03
Constant   ONE_TO_HECTO = 1e-02
Constant   ONE_TO_DECA  = 1e-01
Constant   ONE_TO_DECI  = 1e+01
Constant   ONE_TO_CENTI = 1e+02
Constant   ONE_TO_MILLI = 1e+03
Constant   ONE_TO_MICRO = 1e+06
Constant   ONE_TO_NANO  = 1e+09
Constant   ONE_TO_PICO  = 1e+12
Constant   ONE_TO_FEMTO = 1e+15
Constant   ONE_TO_ATTO  = 1e+18
Constant   ONE_TO_ZEPTO = 1e+21
Constant   ONE_TO_YOCTO = 1e+24
Constant YOTTA_TO_ONE   = 1e+24
Constant YOTTA_TO_ZETTA = 1e+03
Constant YOTTA_TO_EXA   = 1e+06
Constant YOTTA_TO_PETA  = 1e+09
Constant YOTTA_TO_TERA  = 1e+12
Constant YOTTA_TO_GIGA  = 1e+15
Constant YOTTA_TO_MEGA  = 1e+18
Constant YOTTA_TO_KILO  = 1e+21
Constant YOTTA_TO_HECTO = 1e+22
Constant YOTTA_TO_DECA  = 1e+23
Constant YOTTA_TO_DECI  = 1e+25
Constant YOTTA_TO_CENTI = 1e+26
Constant YOTTA_TO_MILLI = 1e+27
Constant YOTTA_TO_MICRO = 1e+30
Constant YOTTA_TO_NANO  = 1e+33
Constant YOTTA_TO_PICO  = 1e+36
Constant YOTTA_TO_FEMTO = 1e+39
Constant YOTTA_TO_ATTO  = 1e+42
Constant YOTTA_TO_ZEPTO = 1e+45
Constant YOTTA_TO_YOCTO = 1e+48
Constant ZETTA_TO_ONE   = 1e+21
Constant ZETTA_TO_YOTTA = 1e-03
Constant ZETTA_TO_EXA   = 1e+03
Constant ZETTA_TO_PETA  = 1e+06
Constant ZETTA_TO_TERA  = 1e+09
Constant ZETTA_TO_GIGA  = 1e+12
Constant ZETTA_TO_MEGA  = 1e+15
Constant ZETTA_TO_KILO  = 1e+18
Constant ZETTA_TO_HECTO = 1e+19
Constant ZETTA_TO_DECA  = 1e+20
Constant ZETTA_TO_DECI  = 1e+22
Constant ZETTA_TO_CENTI = 1e+23
Constant ZETTA_TO_MILLI = 1e+24
Constant ZETTA_TO_MICRO = 1e+27
Constant ZETTA_TO_NANO  = 1e+30
Constant ZETTA_TO_PICO  = 1e+33
Constant ZETTA_TO_FEMTO = 1e+36
Constant ZETTA_TO_ATTO  = 1e+39
Constant ZETTA_TO_ZEPTO = 1e+42
Constant ZETTA_TO_YOCTO = 1e+45
Constant   EXA_TO_ONE   = 1e+18
Constant   EXA_TO_YOTTA = 1e-06
Constant   EXA_TO_ZETTA = 1e-03
Constant   EXA_TO_PETA  = 1e+03
Constant   EXA_TO_TERA  = 1e+06
Constant   EXA_TO_GIGA  = 1e+09
Constant   EXA_TO_MEGA  = 1e+12
Constant   EXA_TO_KILO  = 1e+15
Constant   EXA_TO_HECTO = 1e+16
Constant   EXA_TO_DECA  = 1e+17
Constant   EXA_TO_DECI  = 1e+19
Constant   EXA_TO_CENTI = 1e+20
Constant   EXA_TO_MILLI = 1e+21
Constant   EXA_TO_MICRO = 1e+24
Constant   EXA_TO_NANO  = 1e+27
Constant   EXA_TO_PICO  = 1e+30
Constant   EXA_TO_FEMTO = 1e+33
Constant   EXA_TO_ATTO  = 1e+36
Constant   EXA_TO_ZEPTO = 1e+39
Constant   EXA_TO_YOCTO = 1e+42
Constant  PETA_TO_ONE   = 1e+15
Constant  PETA_TO_YOTTA = 1e-09
Constant  PETA_TO_ZETTA = 1e-06
Constant  PETA_TO_EXA   = 1e-03
Constant  PETA_TO_TERA  = 1e+03
Constant  PETA_TO_GIGA  = 1e+06
Constant  PETA_TO_MEGA  = 1e+09
Constant  PETA_TO_KILO  = 1e+12
Constant  PETA_TO_HECTO = 1e+13
Constant  PETA_TO_DECA  = 1e+14
Constant  PETA_TO_DECI  = 1e+16
Constant  PETA_TO_CENTI = 1e+17
Constant  PETA_TO_MILLI = 1e+18
Constant  PETA_TO_MICRO = 1e+21
Constant  PETA_TO_NANO  = 1e+24
Constant  PETA_TO_PICO  = 1e+27
Constant  PETA_TO_FEMTO = 1e+30
Constant  PETA_TO_ATTO  = 1e+33
Constant  PETA_TO_ZEPTO = 1e+36
Constant  PETA_TO_YOCTO = 1e+39
Constant  TERA_TO_ONE   = 1e+12
Constant  TERA_TO_YOTTA = 1e-12
Constant  TERA_TO_ZETTA = 1e-09
Constant  TERA_TO_EXA   = 1e-06
Constant  TERA_TO_PETA  = 1e-03
Constant  TERA_TO_GIGA  = 1e+03
Constant  TERA_TO_MEGA  = 1e+06
Constant  TERA_TO_KILO  = 1e+09
Constant  TERA_TO_HECTO = 1e+10
Constant  TERA_TO_DECA  = 1e+11
Constant  TERA_TO_DECI  = 1e+13
Constant  TERA_TO_CENTI = 1e+14
Constant  TERA_TO_MILLI = 1e+15
Constant  TERA_TO_MICRO = 1e+18
Constant  TERA_TO_NANO  = 1e+21
Constant  TERA_TO_PICO  = 1e+24
Constant  TERA_TO_FEMTO = 1e+27
Constant  TERA_TO_ATTO  = 1e+30
Constant  TERA_TO_ZEPTO = 1e+33
Constant  TERA_TO_YOCTO = 1e+36
Constant  GIGA_TO_ONE   = 1e+09
Constant  GIGA_TO_YOTTA = 1e-15
Constant  GIGA_TO_ZETTA = 1e-12
Constant  GIGA_TO_EXA   = 1e-09
Constant  GIGA_TO_PETA  = 1e-06
Constant  GIGA_TO_TERA  = 1e-03
Constant  GIGA_TO_MEGA  = 1e+03
Constant  GIGA_TO_KILO  = 1e+06
Constant  GIGA_TO_HECTO = 1e+07
Constant  GIGA_TO_DECA  = 1e+08
Constant  GIGA_TO_DECI  = 1e+10
Constant  GIGA_TO_CENTI = 1e+11
Constant  GIGA_TO_MILLI = 1e+12
Constant  GIGA_TO_MICRO = 1e+15
Constant  GIGA_TO_NANO  = 1e+18
Constant  GIGA_TO_PICO  = 1e+21
Constant  GIGA_TO_FEMTO = 1e+24
Constant  GIGA_TO_ATTO  = 1e+27
Constant  GIGA_TO_ZEPTO = 1e+30
Constant  GIGA_TO_YOCTO = 1e+33
Constant  MEGA_TO_ONE   = 1e+06
Constant  MEGA_TO_YOTTA = 1e-18
Constant  MEGA_TO_ZETTA = 1e-15
Constant  MEGA_TO_EXA   = 1e-12
Constant  MEGA_TO_PETA  = 1e-09
Constant  MEGA_TO_TERA  = 1e-06
Constant  MEGA_TO_GIGA  = 1e-03
Constant  MEGA_TO_KILO  = 1e+03
Constant  MEGA_TO_HECTO = 1e+04
Constant  MEGA_TO_DECA  = 1e+05
Constant  MEGA_TO_DECI  = 1e+07
Constant  MEGA_TO_CENTI = 1e+08
Constant  MEGA_TO_MILLI = 1e+09
Constant  MEGA_TO_MICRO = 1e+12
Constant  MEGA_TO_NANO  = 1e+15
Constant  MEGA_TO_PICO  = 1e+18
Constant  MEGA_TO_FEMTO = 1e+21
Constant  MEGA_TO_ATTO  = 1e+24
Constant  MEGA_TO_ZEPTO = 1e+27
Constant  MEGA_TO_YOCTO = 1e+30
Constant  KILO_TO_ONE   = 1e+03
Constant  KILO_TO_YOTTA = 1e-21
Constant  KILO_TO_ZETTA = 1e-18
Constant  KILO_TO_EXA   = 1e-15
Constant  KILO_TO_PETA  = 1e-12
Constant  KILO_TO_TERA  = 1e-09
Constant  KILO_TO_GIGA  = 1e-06
Constant  KILO_TO_MEGA  = 1e-03
Constant  KILO_TO_HECTO = 1e+01
Constant  KILO_TO_DECA  = 1e+02
Constant  KILO_TO_DECI  = 1e+04
Constant  KILO_TO_CENTI = 1e+05
Constant  KILO_TO_MILLI = 1e+06
Constant  KILO_TO_MICRO = 1e+09
Constant  KILO_TO_NANO  = 1e+12
Constant  KILO_TO_PICO  = 1e+15
Constant  KILO_TO_FEMTO = 1e+18
Constant  KILO_TO_ATTO  = 1e+21
Constant  KILO_TO_ZEPTO = 1e+24
Constant  KILO_TO_YOCTO = 1e+27
Constant HECTO_TO_ONE   = 1e+02
Constant HECTO_TO_YOTTA = 1e-22
Constant HECTO_TO_ZETTA = 1e-19
Constant HECTO_TO_EXA   = 1e-16
Constant HECTO_TO_PETA  = 1e-13
Constant HECTO_TO_TERA  = 1e-10
Constant HECTO_TO_GIGA  = 1e-07
Constant HECTO_TO_MEGA  = 1e-04
Constant HECTO_TO_KILO  = 1e-01
Constant HECTO_TO_DECA  = 1e+01
Constant HECTO_TO_DECI  = 1e+03
Constant HECTO_TO_CENTI = 1e+04
Constant HECTO_TO_MILLI = 1e+05
Constant HECTO_TO_MICRO = 1e+08
Constant HECTO_TO_NANO  = 1e+11
Constant HECTO_TO_PICO  = 1e+14
Constant HECTO_TO_FEMTO = 1e+17
Constant HECTO_TO_ATTO  = 1e+20
Constant HECTO_TO_ZEPTO = 1e+23
Constant HECTO_TO_YOCTO = 1e+26
Constant  DECA_TO_ONE   = 1e+01
Constant  DECA_TO_YOTTA = 1e-23
Constant  DECA_TO_ZETTA = 1e-20
Constant  DECA_TO_EXA   = 1e-17
Constant  DECA_TO_PETA  = 1e-14
Constant  DECA_TO_TERA  = 1e-11
Constant  DECA_TO_GIGA  = 1e-08
Constant  DECA_TO_MEGA  = 1e-05
Constant  DECA_TO_KILO  = 1e-02
Constant  DECA_TO_HECTO = 1e-01
Constant  DECA_TO_DECI  = 1e+02
Constant  DECA_TO_CENTI = 1e+03
Constant  DECA_TO_MILLI = 1e+04
Constant  DECA_TO_MICRO = 1e+07
Constant  DECA_TO_NANO  = 1e+10
Constant  DECA_TO_PICO  = 1e+13
Constant  DECA_TO_FEMTO = 1e+16
Constant  DECA_TO_ATTO  = 1e+19
Constant  DECA_TO_ZEPTO = 1e+22
Constant  DECA_TO_YOCTO = 1e+25
Constant  DECI_TO_ONE   = 1e-01
Constant  DECI_TO_YOTTA = 1e-25
Constant  DECI_TO_ZETTA = 1e-22
Constant  DECI_TO_EXA   = 1e-19
Constant  DECI_TO_PETA  = 1e-16
Constant  DECI_TO_TERA  = 1e-13
Constant  DECI_TO_GIGA  = 1e-10
Constant  DECI_TO_MEGA  = 1e-07
Constant  DECI_TO_KILO  = 1e-04
Constant  DECI_TO_HECTO = 1e-03
Constant  DECI_TO_DECA  = 1e-02
Constant  DECI_TO_CENTI = 1e+01
Constant  DECI_TO_MILLI = 1e+02
Constant  DECI_TO_MICRO = 1e+05
Constant  DECI_TO_NANO  = 1e+08
Constant  DECI_TO_PICO  = 1e+11
Constant  DECI_TO_FEMTO = 1e+14
Constant  DECI_TO_ATTO  = 1e+17
Constant  DECI_TO_ZEPTO = 1e+20
Constant  DECI_TO_YOCTO = 1e+23
Constant CENTI_TO_ONE   = 1e-02
Constant CENTI_TO_YOTTA = 1e-26
Constant CENTI_TO_ZETTA = 1e-23
Constant CENTI_TO_EXA   = 1e-20
Constant CENTI_TO_PETA  = 1e-17
Constant CENTI_TO_TERA  = 1e-14
Constant CENTI_TO_GIGA  = 1e-11
Constant CENTI_TO_MEGA  = 1e-08
Constant CENTI_TO_KILO  = 1e-05
Constant CENTI_TO_HECTO = 1e-04
Constant CENTI_TO_DECA  = 1e-03
Constant CENTI_TO_DECI  = 1e-01
Constant CENTI_TO_MILLI = 1e+01
Constant CENTI_TO_MICRO = 1e+04
Constant CENTI_TO_NANO  = 1e+07
Constant CENTI_TO_PICO  = 1e+10
Constant CENTI_TO_FEMTO = 1e+13
Constant CENTI_TO_ATTO  = 1e+16
Constant CENTI_TO_ZEPTO = 1e+19
Constant CENTI_TO_YOCTO = 1e+22
Constant MILLI_TO_ONE   = 1e-03
Constant MILLI_TO_YOTTA = 1e-27
Constant MILLI_TO_ZETTA = 1e-24
Constant MILLI_TO_EXA   = 1e-21
Constant MILLI_TO_PETA  = 1e-18
Constant MILLI_TO_TERA  = 1e-15
Constant MILLI_TO_GIGA  = 1e-12
Constant MILLI_TO_MEGA  = 1e-09
Constant MILLI_TO_KILO  = 1e-06
Constant MILLI_TO_HECTO = 1e-05
Constant MILLI_TO_DECA  = 1e-04
Constant MILLI_TO_DECI  = 1e-02
Constant MILLI_TO_CENTI = 1e-01
Constant MILLI_TO_MICRO = 1e+03
Constant MILLI_TO_NANO  = 1e+06
Constant MILLI_TO_PICO  = 1e+09
Constant MILLI_TO_FEMTO = 1e+12
Constant MILLI_TO_ATTO  = 1e+15
Constant MILLI_TO_ZEPTO = 1e+18
Constant MILLI_TO_YOCTO = 1e+21
Constant MICRO_TO_ONE   = 1e-06
Constant MICRO_TO_YOTTA = 1e-30
Constant MICRO_TO_ZETTA = 1e-27
Constant MICRO_TO_EXA   = 1e-24
Constant MICRO_TO_PETA  = 1e-21
Constant MICRO_TO_TERA  = 1e-18
Constant MICRO_TO_GIGA  = 1e-15
Constant MICRO_TO_MEGA  = 1e-12
Constant MICRO_TO_KILO  = 1e-09
Constant MICRO_TO_HECTO = 1e-08
Constant MICRO_TO_DECA  = 1e-07
Constant MICRO_TO_DECI  = 1e-05
Constant MICRO_TO_CENTI = 1e-04
Constant MICRO_TO_MILLI = 1e-03
Constant MICRO_TO_NANO  = 1e+03
Constant MICRO_TO_PICO  = 1e+06
Constant MICRO_TO_FEMTO = 1e+09
Constant MICRO_TO_ATTO  = 1e+12
Constant MICRO_TO_ZEPTO = 1e+15
Constant MICRO_TO_YOCTO = 1e+18
Constant  NANO_TO_ONE   = 1e-09
Constant  NANO_TO_YOTTA = 1e-33
Constant  NANO_TO_ZETTA = 1e-30
Constant  NANO_TO_EXA   = 1e-27
Constant  NANO_TO_PETA  = 1e-24
Constant  NANO_TO_TERA  = 1e-21
Constant  NANO_TO_GIGA  = 1e-18
Constant  NANO_TO_MEGA  = 1e-15
Constant  NANO_TO_KILO  = 1e-12
Constant  NANO_TO_HECTO = 1e-11
Constant  NANO_TO_DECA  = 1e-10
Constant  NANO_TO_DECI  = 1e-08
Constant  NANO_TO_CENTI = 1e-07
Constant  NANO_TO_MILLI = 1e-06
Constant  NANO_TO_MICRO = 1e-03
Constant  NANO_TO_PICO  = 1e+03
Constant  NANO_TO_FEMTO = 1e+06
Constant  NANO_TO_ATTO  = 1e+09
Constant  NANO_TO_ZEPTO = 1e+12
Constant  NANO_TO_YOCTO = 1e+15
Constant  PICO_TO_ONE   = 1e-12
Constant  PICO_TO_YOTTA = 1e-36
Constant  PICO_TO_ZETTA = 1e-33
Constant  PICO_TO_EXA   = 1e-30
Constant  PICO_TO_PETA  = 1e-27
Constant  PICO_TO_TERA  = 1e-24
Constant  PICO_TO_GIGA  = 1e-21
Constant  PICO_TO_MEGA  = 1e-18
Constant  PICO_TO_KILO  = 1e-15
Constant  PICO_TO_HECTO = 1e-14
Constant  PICO_TO_DECA  = 1e-13
Constant  PICO_TO_DECI  = 1e-11
Constant  PICO_TO_CENTI = 1e-10
Constant  PICO_TO_MILLI = 1e-09
Constant  PICO_TO_MICRO = 1e-06
Constant  PICO_TO_NANO  = 1e-03
Constant  PICO_TO_FEMTO = 1e+03
Constant  PICO_TO_ATTO  = 1e+06
Constant  PICO_TO_ZEPTO = 1e+09
Constant  PICO_TO_YOCTO = 1e+12
Constant FEMTO_TO_ONE   = 1e-15
Constant FEMTO_TO_YOTTA = 1e-39
Constant FEMTO_TO_ZETTA = 1e-36
Constant FEMTO_TO_EXA   = 1e-33
Constant FEMTO_TO_PETA  = 1e-30
Constant FEMTO_TO_TERA  = 1e-27
Constant FEMTO_TO_GIGA  = 1e-24
Constant FEMTO_TO_MEGA  = 1e-21
Constant FEMTO_TO_KILO  = 1e-18
Constant FEMTO_TO_HECTO = 1e-17
Constant FEMTO_TO_DECA  = 1e-16
Constant FEMTO_TO_DECI  = 1e-14
Constant FEMTO_TO_CENTI = 1e-13
Constant FEMTO_TO_MILLI = 1e-12
Constant FEMTO_TO_MICRO = 1e-09
Constant FEMTO_TO_NANO  = 1e-06
Constant FEMTO_TO_PICO  = 1e-03
Constant FEMTO_TO_ATTO  = 1e+03
Constant FEMTO_TO_ZEPTO = 1e+06
Constant FEMTO_TO_YOCTO = 1e+09
Constant  ATTO_TO_ONE   = 1e-18
Constant  ATTO_TO_YOTTA = 1e-42
Constant  ATTO_TO_ZETTA = 1e-39
Constant  ATTO_TO_EXA   = 1e-36
Constant  ATTO_TO_PETA  = 1e-33
Constant  ATTO_TO_TERA  = 1e-30
Constant  ATTO_TO_GIGA  = 1e-27
Constant  ATTO_TO_MEGA  = 1e-24
Constant  ATTO_TO_KILO  = 1e-21
Constant  ATTO_TO_HECTO = 1e-20
Constant  ATTO_TO_DECA  = 1e-19
Constant  ATTO_TO_DECI  = 1e-17
Constant  ATTO_TO_CENTI = 1e-16
Constant  ATTO_TO_MILLI = 1e-15
Constant  ATTO_TO_MICRO = 1e-12
Constant  ATTO_TO_NANO  = 1e-09
Constant  ATTO_TO_PICO  = 1e-06
Constant  ATTO_TO_FEMTO = 1e-03
Constant  ATTO_TO_ZEPTO = 1e+03
Constant  ATTO_TO_YOCTO = 1e+06
Constant ZEPTO_TO_ONE   = 1e-21
Constant ZEPTO_TO_YOTTA = 1e-45
Constant ZEPTO_TO_ZETTA = 1e-42
Constant ZEPTO_TO_EXA   = 1e-39
Constant ZEPTO_TO_PETA  = 1e-36
Constant ZEPTO_TO_TERA  = 1e-33
Constant ZEPTO_TO_GIGA  = 1e-30
Constant ZEPTO_TO_MEGA  = 1e-27
Constant ZEPTO_TO_KILO  = 1e-24
Constant ZEPTO_TO_HECTO = 1e-23
Constant ZEPTO_TO_DECA  = 1e-22
Constant ZEPTO_TO_DECI  = 1e-20
Constant ZEPTO_TO_CENTI = 1e-19
Constant ZEPTO_TO_MILLI = 1e-18
Constant ZEPTO_TO_MICRO = 1e-15
Constant ZEPTO_TO_NANO  = 1e-12
Constant ZEPTO_TO_PICO  = 1e-09
Constant ZEPTO_TO_FEMTO = 1e-06
Constant ZEPTO_TO_ATTO  = 1e-03
Constant ZEPTO_TO_YOCTO = 1e+03
Constant YOCTO_TO_ONE   = 1e-24
Constant YOCTO_TO_YOTTA = 1e-48
Constant YOCTO_TO_ZETTA = 1e-45
Constant YOCTO_TO_EXA   = 1e-42
Constant YOCTO_TO_PETA  = 1e-39
Constant YOCTO_TO_TERA  = 1e-36
Constant YOCTO_TO_GIGA  = 1e-33
Constant YOCTO_TO_MEGA  = 1e-30
Constant YOCTO_TO_KILO  = 1e-27
Constant YOCTO_TO_HECTO = 1e-26
Constant YOCTO_TO_DECA  = 1e-25
Constant YOCTO_TO_DECI  = 1e-23
Constant YOCTO_TO_CENTI = 1e-22
Constant YOCTO_TO_MILLI = 1e-21
Constant YOCTO_TO_MICRO = 1e-18
Constant YOCTO_TO_NANO  = 1e-15
Constant YOCTO_TO_PICO  = 1e-12
Constant YOCTO_TO_FEMTO = 1e-09
Constant YOCTO_TO_ATTO  = 1e-06
Constant YOCTO_TO_ZEPTO = 1e-03
/// @}

Constant ONE_TO_PERCENT = 1e+02
Constant PERCENT_TO_ONE = 1e-02