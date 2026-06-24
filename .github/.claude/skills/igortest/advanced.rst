.. vim: set et sts=3 sw=3 tw=79:

.. _advanced:

Advanced Usage
==============

.. _TestHooks:

Test Hooks
----------

A Test Run can be extended with user-defined code at specific points during its
execution. These pre-defined injection points are at the beginning and
respectively at the end of a complete :ref:`Test Run<RunTest>`, a
:ref:`TestSuite`, and a :ref:`TestCase`.

The following functions are reserved for user code injections:

.. cpp:function:: TEST_BEGIN_OVERRIDE()

Executed at the **begin** of a :cpp:func:`Test Run<RunTest>`.

.. cpp:function:: TEST_END_OVERRIDE()

Executed at the **end** of a :cpp:func:`Test Run<RunTest>`.

.. cpp:function:: TEST_SUITE_BEGIN_OVERRIDE()

Executed at the **begin** of a :ref:`TestSuite`.

.. cpp:function:: TEST_SUITE_END_OVERRIDE()

Executed at the **end** of a :ref:`TestSuite`.

.. cpp:function:: TEST_CASE_BEGIN_OVERRIDE()

Executed at the **begin** of a :ref:`TestCase`.

.. cpp:function:: TEST_CASE_END_OVERRIDE()

Executed at the **end** of a :ref:`TestCase`.

.. note::

   :cpp:func:`TEST_END_OVERRIDE()` is executed at the very end of a test run
   so that the Igor debugger state is already reset to the state it had before
   :cpp:func:`RunTest()` was executed.

.. note::

   The functions :cpp:func:`TEST_SUITE_BEGIN_OVERRIDE()` and
   :cpp:func:`TEST_SUITE_END_OVERRIDE()` as well as
   :cpp:func:`TEST_CASE_BEGIN_OVERRIDE()` and
   :cpp:func:`TEST_CASE_END_OVERRIDE()` can also be defined locally in a test
   suite with the `static` keyword. :ref:`example2` shows how `static`
   functions are called the framework.

These functions are executed automatically if they are defined anywhere in
global or local context. For example, :cpp:func:`TEST_CASE_BEGIN_OVERRIDE` gets
executed at the beginning of each :ref:`TestCase`. Locally defined functions
always override globally defined ones of the same name. To visualize this
behavior, take a look at the following scenario: A user would like to have code
executed only in a specific :ref:`TestSuite`. Then the functions
:cpp:func:`TEST_SUITE_BEGIN_OVERRIDE` and :cpp:func:`TEST_SUITE_END_OVERRIDE`
can be defined locally within the current :ref:`TestSuite` by declaring them
`static` to the current Test Suite. The local (`static`) functions then replace
any previously defined global functions. The functionality with additional user
code at certain points of a Test Run is demonstrated in :ref:`example5`.

To give a possible use case, take a look at the following scenario: By default,
each :ref:`TestCase` is executed in its own temporary data folder.
:cpp:func:`TEST_CASE_BEGIN_OVERRIDE` can be used to set the data folder to
`root:`. This will result that each Test Case gets executed in `root:` and no
cleanup is done afterward. The *next* Test Case then starts with the data the
*previous* Test Case left in `root:`.

.. note::
   By default the Igor debugger is disabled during the execution of a test run.

Assertions can be used in test hooks. However it is enforced by the IUTF that
the test case itself must contain at least one assertion. If a CHECK or WARN
assertion in a test hook fails the test run is still executed normally. If a
test hook exits with a pending RTE (runtime exception) or an abort the execution
of the test run will be cancelled as this is considered an invalid test setup.

.. _JUNITOutput:

JUNIT Output
------------

All common continuous integration frameworks support input as JUNIT XML files.
The Igor Pro Universal Testing Framework supports output of test run results in
JUNIT XML format. The output can be enabled by adding the optional parameter
:code:`enableJU=1` to :cpp:func:`RunTest()`.

The XML output files are written to the experiments `home` directory with naming
`JU_Experiment_Date_Time.xml`. If a file with the same name already exists a
three digit number is added to the name. The JUNIT Output includes the results
and history log of each test case and test suite.

The format reference that the IUTF uses is described in the section
:ref:`junit_reference`.

If the function tag ``// IUTF_SKIP`` is preceding the test case function then the test case is skipped (not executed)
and counted for JUNIT as `skipped`.

Test Anything Protocol Output
-----------------------------

Output according to the `Test Anything Protocol (TAP) standard 13
<https://testanything.org/tap-version-13-specification.html>`__ can be enabled
with the optional parameter `enableTAP = 1` of :cpp:func:`RunTest()`.

.. todo::

   reference function parameters with their breathe links

The output is written into a file in the experiment folder with a unique
generated name `tap_'time'.log`. This prevents accidental overwrites of
previous test runs. A TAP output file combines all Test Cases from all Test
Suites given in :cpp:func:`RunTest()`. Additional TAP compliant descriptions
and directives for each Test Case can be added in the lines preceeding the
function of a Test Case (all lines above :code:`Function` up to the previous
:code:`Function` are considered as tags, every tag in separate line):

.. code-block:: igor

   // TAPDescription: My description here
   // TAPDirective: My directive here

For directives two additional keywords are defined that can be written at the
beginning of the directive message.

- `TODO` indicates a Test that includes a part of the program still in
  development. Failures here will be ignored by a TAP consumer.

- `SKIP` indicates a Test that should be skipped. A Test with this directive
  keyword is not executed and reported always as 'ok'.

If the function tag ``// IUTF_SKIP`` is preceding the test case function then the test case is skipped (not executed)
and evaluated for TAP the same as if ``// TAPDirective: SKIP`` was set.

Examples:
^^^^^^^^^

.. code-block:: igor

   // TAPDirective: TODO routine that should be tested is still under development

or

.. code-block:: igor

   // TAPDirective: SKIP this test gets skipped

See the Experiment in the TAP_Example folder for reference.

.. todo::

   add reference to the example, include example code

.. _automate:

Automate Test Runs
------------------

To further simplify test execution it is possible to automate test runs from
the command line.

Steps to do that include:

- Implement a function called `run()` in `ProcGlobal` context (or an independent
  module with IUTF included) taking no parameters. This function must perform
  all necessary steps for test execution, which is at least one call to
  :cpp:func:`RunTest`.

- Put the test experiment together with your :ref:`Test Suites<TestSuite>` and
  the script `helper/autorun-test.bat` into its own folder.

- Run the batch file `autorun-test.bat`.

- Inspect the created log file.

The example batch files for autorun create a file named `DO_AUTORUN.TXT` before
starting Igor Pro. This enables autorun mode. After the `run()` function is
executed and returned the log is saved in a file on disk and Igor Pro quits.

A different autorun mode is enabled if the file is named
`DO_AUTORUN_PLAIN.TXT`. In this mode no log file is saved after the test
execution and Igor Pro does not quit. This mode also does not use the Operation
Queue.

See also :ref:`example6`.

Running in an Independent Module
--------------------------------

The universal testing framework can be run itself in an independent module.
This can be required in very rare cases when the `ProcGlobal` procedures
might not always be compiled.

See also :ref:`example9`.

Handling of Abort Code
----------------------

The universal testing framework continues with the next test case after catching
`Abort` and logs the abort code. Currently differentiation of different abort
conditions include manual user aborts, stack overflow and an encountered
`Abort` in the code. The framework is terminated when manually pressing the
Abort button.

.. note::

   Igor Pro 6 can not differentiate between manual user aborts and programmatic
   abort codes. Pressing the Abort button in Igor Pro 6 will therefore
   terminate only the current test case and continue with the next queued test
   case.

.. _tests_with_background_activity:

Test Cases with Background Activity
-----------------------------------

There exist situations where a test case needs to return temporary to the Igor
command prompt and continue after a background task has finished. A real world
use case is for example a testing code that runs data acquisition in a
background task and the test case should continue after the acquisition finished.

The universal testing framework supports such cases with a feature that allows to
register one or more background tasks that should be monitored. A procedure name
can be given that is called when the monitored background tasks finish. After the
current test case procedure finishes the framework will return to Igors command
prompt. This allows the users background task(s) to do its job. After the
task(s) finish the framework continues the test case with the registered procedure.

The registration is done by calling :cpp:func:`RegisterIUTFMonitor()` from a
test case or a BEGIN hook. The registration allows to give a list of
background tasks that should be monitored. The mode parameter sets if all or one
task has to finish to continue test execution. Optional a timeout can be set
after the test continues independently of the user task(s) state.

It might happen that while a test case executes it turns out that a previously
registered background monitor is not needed any more, e.g. if requirements for
further parts of the test case are not met. Then an already registered background
monitor can be unregistered by calling :cpp:func:`UnRegisterIUTFMonitor()` from
the test case or BEGIN hook. The function takes no arguments.

See also :ref:`flags_IUTFBackgroundMonModes`.

Function definition of RegisterIUTFMonitor
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. doxygenfunction:: RegisterIUTFMonitor

The function that is registered to continue the test execution must have the
same format as a test case function and the name has to end with `_REENTRY`.
When the universal testing framework temporary drops to Igors command line and
resumes later no begin/end hooks are executed. Logically the universal testing
frame work stays in the same test case. It is allowed to register another
monitoring in the `_REENTRY` function.

Multiple subsequent calls to :cpp:func:`RegisterIUTFMonitor()` in the same
function overwrite the previous registration.

Test Cases with background activity are supported from multi data test cases, see
`Multi Data Test Cases with Background Activity`_.

 See also :ref:`example11`.

 See also :ref:`example12`.

.. _multi_data_test_cases:

Multi Data Test Cases
---------------------

Often the same test should be run multiple times with different sets of data.
The universal testing framework offers direct support for such tests. Test cases
that are run with multiple data take one optional argument. To the test case a
data generator function is attributed that returns a wave. For each element of
that wave the test case is run. This sketches a simple multi data test case:

.. code-block:: igor

   // IUTF_TD_GENERATOR DataGeneratorFunction
   Function myTestCase([arg])
     variable arg
     // add checks here
   End

   Function/WAVE DataGeneratorFunction()
     Make/FREE data = {1, 2, 3, 4}
     return data
   End

To the test case `myTestCase` a data generator function name is attributed with the
comment line above following the tag word `IUTF_TD_GENERATOR`.
All lines above :code:`Function` up to the previous :code:`Function` are considered
as tags with every tag in separate line.
If the data generator function is not found in the current procedure file it is searched
in all procedure files of the current compilation unit as a non-static function. (ProcGlobal context)
Also a static data generator function in another procedure file can be specified by
adding the Module name in the specification. There is no search in other procedure
files if such specified function is not found.

.. code-block:: igor

   // IUTF_TD_GENERATOR GeneratorModule#DataGeneratorFunction

The data generator `DataGeneratorFunction` returns a wave of numeric type and the
test case takes one optional argument of numeric type. When run `myTestCase` is
executed four times with argument arg 1, 2, 3 and 4.

Supported types for `arg` are variable, string, complex, Integer64, data folder
references and wave references. The type of the returned wave of the attributed
data generator function must fit to the argument type that the multi data test
case takes.
The data generator function name must be attributed with a comment within four
lines above the test cases Function line. The key word is `IUTF_TD_GENERATOR` with
the data generators function name following as seen in the simple example here.
If no data generator is given or the format of the test case function does not fit
to the wave type then a error message is printed and the test run is aborted.

The test case names are by default extended with `:num` where num is the index
of the wave returned from the data generator. For convenience in the data generator
dimension labels can be set for each wave element that are used instead of the index.

.. code-block:: igor

   Function/WAVE DataGeneratorFunction()
     Make/FREE data = {1, 2, 3, 4}
     SetDimLabel 0, 0, first, data
     SetDimLabel 0, 1, second, data
     SetDimLabel 0, 2, third, data
     SetDimLabel 0, 3, fourth, data
     return data
   End

The test case names would now be `myTestCase:first`, `myTestCase:second` and so on.

The optional argument of the test case function is always given from the data
generator wave elements. Thus the case that `ParamIsDefault(arg)` is true never
happens.

When setting up a multi data test case with a data generator returning wave
references then the test case can also use typed waves. Supported are
text waves (``WAVE/T``), waves with data folder references (``WAVE/DF``) and
waves with wave references (``WAVE/WAVE``). For such a test case or reentry
function the associated data generator must return a wave reference wave where
each wave element refers to a wave of the fitting type.
For a test case setup with the generic ``WAVE`` the type is not fixed for all
elements of from the data generator.

 See also :ref:`example13`.

Assertions can be used in data generators. If a CHECK or WARN assertion in a
data generator fails the test run is still executed normally. If a data
generator exits with a pending RTE (runtime exception) or an abort the
execution of the test run will be cancelled as this is considered an invalid
test setup.

Multi Data Test Cases with Background Activity
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Multi data test cases that register a background task to be monitored are
supported. For a multi data test case each reentry function can have one of two
different formats:

- Function fun_REENTRY() with no argument as described in `Test Cases with Background Activity`_
- Function fun_REENTRY([arg]) with the same argument type as the originating multi data test case.

For the second case, the reentry function is called with the same wave element as argument as
when the multi data test case was started.

If the reentry function uses a different argument type than the test case entry
function then on reentry to the universal testing framework an error is printed
and further test execution is aborted.

.. code-block:: igor

   // IUTF_TD_GENERATOR DataGeneratorFunction
   Function myTestCase([var])
     variable var

     CtrlNamedBackGround testtask, proc=UserTask, period=1, start
     RegisterIUTFMonitor("testtask", 1, "testCase_REENTRY")
     CHECK(var == 1 || var == 5)
   End

   Function UserTask(s)
     STRUCT WMBackgroundStruct &s

     return !mod(trunc(datetime), 5)
   End

   Function/WAVE DataGeneratorFunction()
     Make/FREE data = {5, 1}
     SetDimLabel 0, 0, first, data
     SetDimLabel 0, 1, second, data
     return data
   End

   Function testCase_REENTRY([var])
     variable var

     print "Reentered test case with argument ", var
     PASS()
   End

.. _multi_multi_data_test_cases:

Multi-Multi Data Test Cases
---------------------------

Multi-Multi-Data test cases are an extension of multi-data test cases. They allow to specify more than one variable with corresponding data generator.

.. code-block:: igor

   Function/WAVE GeneratorStr()

	   Make/FREE/T/N=2 data = num2istr(p)
	   SetDimlabel UTF_ROW, 0, ROW0, data
	   SetDimlabel UTF_ROW, 1, ROW1, data

	   return data
   End

   Function/WAVE GeneratorVar()

	   Make/FREE/N=2 data = p
	   SetDimlabel UTF_ROW, 0, ROW0, data
	   SetDimlabel UTF_ROW, 1, ROW1, data

	   return data
   End

   // IUTF_TD_GENERATOR v0:GeneratorVar
   // IUTF_TD_GENERATOR s2:GeneratorStr
   // IUTF_TD_GENERATOR v1:GeneratorVar
   // IUTF_TD_GENERATOR v2:GeneratorVar
   // IUTF_TD_GENERATOR v3:GeneratorVar
   static Function TC_MMD_Part1([md])
	   STRUCT IUTF_mData &md

      CHECK(md.v0 >= 0 && md.v0 < 2)
      print md.v0, md.v1, md.v2, md.v3
      print md.s2
   End

The basic functionality works the same as for the regular multi-data test cases.
In Multi-Multi-Data test cases the changing variables are elements of the structure ``IUTF_mData``. Each variable can have a data generator function set with the
``IUTF_TD_GENERATOR`` directive. The tag syntax is ``varName:DataGeneratorName``. The test case is called for all permutations of setup data generators values of all variables.
In the upper example these are 32 test case calls. The structure defines the following variables:

.. code-block:: igor

   Structure IUTF_mData
	   variable v0
	   variable v1
	   variable v2
	   variable v3
	   variable v4
	   string s0
	   string s1
	   string s2
	   string s3
	   string s4
	   DFREF dfr0
	   DFREF dfr1
	   DFREF dfr2
	   DFREF dfr3
	   DFREF dfr4
	   WAVE/WAVE w0
	   WAVE/WAVE w1
	   WAVE/WAVE w2
	   WAVE/WAVE w3
	   WAVE/WAVE w4
	   variable/C c0
	   variable/C c1
	   variable/C c2
	   variable/C c3
	   variable/C c4
	   int64 i0
	   int64 i1
	   int64 i2
	   int64 i3
	   int64 i4
   EndStructure

Note: The int64 variables are only available for Igor Pro 7+.

Any combination of v, s, c, w, dfr and i variables can be set. Currently for each type the structure offers 5 different variables.
Variables that are not set by a data generator have their respective default value, 0 or null.
The test case name is suffixed by the current index of the data generator wave or if set by the current dimension label.
The order of the suffixes equals the order of the variables in the structure ``IUTF_mData``.
The indices are changed for all setup variables. The first variables changes fastest, that is in the upper example for ``v0``.
If Multi-Multi-Data test cases are combined with functions with background activity the reentry function must have the same
signature.

.. _code_coverage:

Code Coverage Determination
---------------------------

When running Igor Pro 9 or newer the Igor Pro Universal Testing Framework offers
the feature to obtain code coverage information. When enabled the IUTF adds to
functions in target procedure files code to track execution. At the end of the
test run the IUTF outputs files in HTML format with coverage information.

This feature is enabled when the optional parameter ``traceWinList`` is set and non-empty when calling ``RunTest``.
Before the actual tests are executed the given procedure files are modified on disk where additional function calls are inserted.
The additional code does not change the execution of the original code. This step is named ``Instrumentation``.
The coverage results are output as HTML files in the experiments folder for each procedure file in the form:

..
   To create htmloutput.txt run the tests from Various.pxp. Then a file test-tracing2.htm is created in the folder of the experiment file.
   For htmloutput.txt the content from the first function Workload is taken and from the second function TracingTest the first
   Make/MultiThread block as well as the second if block with if/elseif/else/endif.

.. literalinclude:: htmloutput.txt

The code is prefixed with three columns where the number in the first column is the count how many times the line was executed.
In second and third column is counted, when the code contained an ``if`` conditional. For that case the second column counts
the execution for the case the condition was ``true`` and the third column counts when the condition was ``false`` respectively.

IUTF does also support the output in `Cobertura format <https://cobertura.github.io/cobertura/>`_. To do this you have to add
``COBERTURA:1`` to ``traceOptions`` in ``RunTest``. This will output an xml file for each instrumented procedure file.

Details
^^^^^^^

The optional parameter ``traceOptions`` for ``RunTest`` allows to tune execution with code coverage. This parameter is a list
with key-value pairs that can be set using the Igor functions ``ReplaceNumberByKey`` or ``ReplaceStringByKey`` respectively.
For each settings key a constant is defined in ``TraceOptionKeyStrings``. The following keys are available:

* ``UTF_KEY_REGEXP`` (``REGEXP:boolean``) When set the parameter ``traceWinList`` is parsed as a regular expression for all procedure window names.
* ``UTF_KEY_HTMLCREATION`` (``HTMLCREATION:boolean``) When set to zero no HTML files are created after the test run.
  HTML files can be created by calling ``IUTF_Tracing#AnalyzeTracingResult()`` manually after a test run.
* ``UTF_KEY_INSTRUMENTATIONONLY`` (``INSTRUMENTONLY:boolean``) When set the IUTF will only do the code instrumentation and then return. No tests get executed.
* ``UTF_KEY_COBERTURA``(``COBERTURA:boolean``) When set IUTF will additionally output the reports in Cobertura format.
* ``UTF_KEY_COBERTURA_SOURCES`` (``COBERTURA_SOURCES:string``) A comma ``,`` delimited
  list of directory paths that should be used as source paths for the procedure files. If this list
  is empty or this option not set IUTF will use the current home directory of the experiment as the
  source path for all procedure files.
* ``UTF_KEY_COBERTURA_OUT`` (``COBERTURA_OUT:string``) The output directory where all generated
  cobertura file should be written to. This helps to organize your project directory. You have to
  provide the absolute path to the directory with a trailing directory delimiter (``\`` in Windows,
  ``:`` with Macintosh). If this option is not defined or empty IUTF will store all generated files
  in the home directory at the start of ``RunTest`` which is usually the same directory as your
  experiment file.

Additionally function and macros can be excluded from instrumentation by adding the special comment ``// IUTF_NOINSTRUMENTATION`` before the first line of the function.
Excluding basic functions or macros that are called very often can speed up the execution of instrumented code.

Static functions in procedure files can only be instrumented, if the procedure file has the pragma ModuleName set, e.g. ``#pragma ModuleName=myUtilities``.
For static functions that exist in a given procedure file without ModuleName a warning is printed to history. These function are not instrumented and
appear in the coverage result file with zero executions.

Instrumented code runs roughly 30% slower. In special cases a stronger slowdown can occur. In such cases it should be considered to exclude
very often called functions from the instrumentation with the special comment ``// IUTF_NOINSTRUMENTATION`` as described above.

Coverage logging also works for threadsafe functions and functions that are executed in preemptive threads.

The instrumented code that is written to disk and executed with code coverage logging is based on the current code within Igor Pro at the time when ``RunTest`` is called.
The evaluation of gathered coverage data refers to the procedure file content on disk when ``RunTest`` was called. Thus, unsaved changes
in procedure files that are targeted for instrumentation will result in incorrect result files. It is strongly recommended to save all
procedure file changes to disk before running a test with code coverage logging.

At the end of a run with code coverage determination Igor Pro outputs the global coverage to stdout in the form ``Coverage: 12.3%``.
The following regular expression can be used in CI services (e.g. in GitLab) to retrieve the number
``(?:^Coverage: )(\d+.\d+)(?:%$)``.

After the test run the user can call ``IUTF_RestoreTracing()`` to restore the
instrumented procedure files back to their original version. It is recommended
to call this manually after the test run.

.. _coverage_statistics:

Statistics
^^^^^^^^^^

After running the code coverage the user can print a table with the most called functions to the history using
``ShowTopFunctions``. This function accepts as the first parameter the maximum number of entries that should be
printed. If all entries should be printed this parameter should be set to to a large number or ``Inf``.

The optional parameter ``mode`` can be set to ``UTF_ANALYTICS_LINES`` to print the statistics for each line instead of
each function (``UTF_ANALYTICS_FUNCTIONS``). The optional parameter ``sorting`` defines the column that should be
sorted for. Currently supported are ``UTF_ANALYTICS_CALLS`` (default) to sort for all direct calls and
``UTF_ANALYTICS_SUM`` to sort for the sum of all called lines inside the function. ``UTF_ANALYTICS_SUM`` can not
combined with the mode ``UTF_ANALYTICS_LINES``.

The data is also available as a global wave in ``root:Packages:igortest:TracingAnalyticResult``.

Limitations
^^^^^^^^^^^

The function that calls RunTest with tracing enabled must return to the Igor Pro
command line afterwards to allow recompilation of the instrumented code. It is
not allowed to have another RunTest call in between. The Igor Pro Universal
Testing Framework will abort with an error in that case.

If the full autorun feature is enabled through ``DO_AUTORUN.TXT`` the RunTest call with instrumentation must be the only call in the experiment.
Specifically, if a RunTest call without tracing is placed before then the RunTest call with tracing will not execute tests.

The output of the statistics can currently not be automated as such as the automation requires the return to the Igor
Pro command line.

Examples
^^^^^^^^

.. literalinclude:: ../../examples/CoverageDemoCode.ipf
   :caption: Sets up a test, enables coverage determination for all procedure files that start with ``CODE_``.
   :name: IUTF_Coverage_example1
   :language: igor
   :start-after: // IUTF_Coverage_example1_begin
   :end-before: // IUTF_Coverage_example1_end
   :dedent:
   :tab-width: 4

.. literalinclude:: ../../examples/CoverageDemoCode.ipf
   :caption: Enables coverage determination for all procedure files that start with ``CODE_``, but stops after instrumentation of the code.
   :name: IUTF_Coverage_example2
   :language: igor
   :start-after: // IUTF_Coverage_example2_begin
   :end-before: // IUTF_Coverage_example2_end
   :dedent:
   :tab-width: 4

.. literalinclude:: ../../examples/CoverageDemoCode.ipf
   :caption: Output the results of coverage determination as Cobertura and disables the HTML output. Only the test suite will be instrumented.
   :name: IUTF_Coverage_example3
   :language: igor
   :start-after: // IUTF_Coverage_example3_begin
   :end-before: // IUTF_Coverage_example3_end
   :dedent:
   :tab-width: 4

.. _flaky_tests:

Flaky Tests
-----------

Certainly a flaky test is something that needs to be avoided and fixed. Tests
should always pass and if not they need to be worked on. However we don't live
in a perfect world and thus it might be helpful to identify tests that fail
every now and then.

To allow rerun failed flaky tests in the Igor Universal Testing Framework you
have to call ``RunTest`` with the optional ``retry`` parameter set to
``IUTF_RETRY_FAILED_UNTIL_PASS``. After that all flaky tests need to be marked
with the function tag ``IUTF_RETRY_FAILED``. IUTF will now rerun these test
cases up to 10 times if they exits with a failed CHECK assertion.

You can also set the ``IUTF_RETRY_MARK_ALL_AS_RETRY`` flag in the ``retry``
parameter of ``RunTest`` to rerun all failed tests in the test run. This treats
all tests cases as if they are marked with the function tag
``IUTF_RETRY_FAILED``.

If you want that all failed REQUIRE assertions will be retried as well you have
to set the ``IUTF_RETRY_REQUIRES`` flag in the ``retry`` parameter of
``RunTest``. Be careful as this will also retry other cases which would normally
abort the test run like invalid reentry function signatures. The best thing is
not to use REQUIRE assertions for conditions that are flaky.

You can also change the maximum number of retries to a lower limit using the
optional parameter ``retryMaxCount``. However it is not possible to set this
number to a higher value than 10 (``IUTF_MAX_SUPPORTED_RETRY``).

Rerunning a flaky test case will also re-execute the test case begin and end
hook each time. If a multi-data testcase or a multi-multi-data testcase is
marked as flaky and one iteration failed it will retry the single failed
iteration with the same arguments and not all previous runs.

.. code-block:: igor

   // IUTF_RETRY_FAILED
   Function FlakyTest()
      // doing some stuff that can fail for some reasons but will succeed if it
      // will be retried some times.
      variable err = SetupTestWhichIsFlaky()
      CHECK_EQUAL_VAR(err, 0)
      if(err)
         return NaN
      endif

      // perform the real test
      // ...
   End

.. _shuffle_test_case_order:

Shuffle test case order
-----------------------

The Igor universal testing framework executes all test suites one by one by
their appearance in the ``RunTest`` call. If the optional parameter
``enableRegExp`` was set it will execute the found test suites alphabetically.
If you want a random order each time you execute ``RunTest`` you have to set the
flag ``IUTF_SHUFFLE_TEST_SUITES`` of the optional parameter ``shuffle`` in the
``RunTest`` call.

When a test suite is executed it will execute all of its test cases. There is no
interleaving with other test suites. By default are all test cases executed in
order of their line number in the procedure file. To randomize the order of the
execution of test cases you have to set the flag ``IUTF_SHUFFLE_TEST_CASES`` of
the optional parameter ``shuffle`` in the ``RunTest`` call. This will shuffle
all test cases for each test suite. If this is not intended for single test
suites (e.g. the test cases depend on each other) you can opt-out these test
suites by setting the procedure tag ``// IUTF_NO_SHUFFLE_TEST_CASE`` somewhere
in the file.

.. caution::
   Procedure tags can only be placed in the first 20 lines of a file. They are
   one-line comments like function tags (e.g. ``// IUTF_SKIP``) and ignore any
   conditional compilation with ``#if``.

If you want to shuffle everything you can set the optional parameter ``shuffle``
to ``IUTF_SHUFFLE_ALL``.

.. _Jenkins XUnit plugin: https://github.com/jenkinsci/xunit-plugin/blob/master/src/main/resources/org/jenkinsci/plugins/xunit/types/model/xsd/junit-10.xsd

.. _junit_reference:

JUNIT Reference
---------------

The JUNIT implementation in the IUTF is based on the XML scheme definition from `Jenkins XUnit plugin`_.

Example XML reference file.

.. literalinclude:: junit.xml
   :caption: Example XML file with attributes used also supported by the Jenkins JUnit plugin based on the file published at <https://llg.cubic.org/docs/junit/>.
   :name: JUNIT_XML_Example
   :language: xml
   :force:
   :dedent:
   :tab-width: 4

.. literalinclude:: junit.xsd
   :caption: XSD (XML scheme definition) file for JUNIT
   :name: JUNIT_XSD
   :language: xml
   :dedent:
   :tab-width: 4

.. _cobertura_reference:

Cobertura Reference
-------------------

The Cobertura implementation in the IUTF is based on the DTD scheme definition
`coverage-04.dtd <https://cobertura.sourceforge.net/xml/coverage-04.dtd>`_.

.. literalinclude:: coverage-04.dtd
   :caption: Cobertura DTD schema ``coverage-04.dtd``
   :name: COBERTURA_DTD
   :language: dtd
   :dedent:
   :tab-width: 4
