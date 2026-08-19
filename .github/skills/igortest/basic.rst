.. vim: set et sts=3 sw=3 tw=79:

.. _basic:

Basic Structure
===============

The interface design and naming is inspired by the `Boost Test Library
<http://www.boost.org/libs/test>`__. Following this naming scheme, the universal
testing package consists of three basic structural elements:

- :ref:`Test Suites <TestSuite>`
- :ref:`Test Cases <TestCase>`
- :ref:`Assertions <AssertionTypes>`

The basic building blocks of this Igor Pro Universal Testing Framework are
assertions. Assertions are used for checking if a condition is true. See
:ref:`AssertionTypes` for a clarification of the difference between the three
assertion types. Assertions are grouped into single test cases and test cases
are organized in test suites.

A :ref:`test suite <TestSuite>` is a group of test cases that live in a single
procedure file. You can group multiple test suites in a named test environment
by using the optional parameter :code:`name` of :cpp:func:`RunTest()`.

For a list of all objects see :ref:`genindex` or use the :ref:`search`.

.. _RunTest:

Test Run
--------

A Test Run is executed using :cpp:func:`RunTest` with only a single mandatory
parameter which is the :ref:`TestSuite`.

Function definition of RunTest
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. doxygenfunction:: RunTest

.. _TestSuite:

Test Suite
----------

A Test Suite is a group of :ref:`Test Cases<TestCase>` which should belong
together. All :ref:`test functions<TestCase>` are defined in a single
procedure file, :cpp:func:`RunTest` calls them from top to bottom. Generally speaking,
a Test Suite is equal to a procedure file.
Therefore tests suites can not be nested, although multiple test suites can be
run with one command by supplying a list to the parameter :code:`procWinList` in
:cpp:func:`RunTest`.

.. note::

   Although possible, a test suite should not live inside the main program. It
   should be separated from the rest of the project into its own procedure
   file. This also allows to load only the necessary parts of your program
   into the unit test.

.. _TestCase:

Test Case
---------

A Test Case is one of the basic building blocks grouping :ref:`assertions
<AssertionTypes>` together. A function is considered a test case if it
fulfills all of the following properties:

1. It takes no parameters.
2. It returns a numeric value (Igor Pro default).
3. Its name does not end with `_IGNORE` or `_REENTRY`.
4. It is either non-static, or static and part of a regular module.

The first rule is making the test case callable in automated test environments.

The second rule is reserving the `_IGNORE` namespace to allow advanced users to
add their own helper functions. It is advised to define all test cases as
static functions and to create one regular distinctive module per procedure
file. This will keep the Test Cases in their own namespace and thus not
interfere with user-defined functions in `ProcGlobal`.

A defined list of test cases in a test suite can be run using the optional
parameter :code:`testCase` of :cpp:func:`RunTest`. When executing multiple test
suites and a test case is found in more than one test suite, it is executed in
every matching test suite.

Test cases can be marked to expect failures. The assertions are executed as
normal and the error counter is reset to zero if one or more assertions failed
during the execution of this test case. Only if the test case finished without
any failed assertion the test case itself is considered as failed. To mark a
test case as expected failure write the keyword in the comment above (all lines
above :code:`Function` up to the previous :code:`Function` are considered as
tags, every tag in separate line):

.. code-block:: igor

   // IUTF_EXPECTED_FAILURE
   Function TestCase_NotWorkingYet()

All assertions in a test case are marked as expected failures. If the test case
ends due to an :code:`Abort`, :code:`AbortOnRTE` or pending RTE this is also
considered as expected failure and neither the error counter is increased or
test case failed.

Example:
^^^^^^^^

In Test Suite `TestSuite_1.ipf` the Test Cases `static Duplicate()` and `static Unique_1()`
are defined. In Test Suite `TestSuite_2.ipf` the Test Cases `static Duplicate()`,
`static Unique_2()` are defined.

.. code-block:: igor

   Runtest("TestSuite_1.ipf;TestSuite_2.ipf", testCase="Unique_1;Unique_2;Duplicate")

The command will run the two test suites `TestSuite_1.ipf` and
`TestSuite_2.ipf` separately. Within every test suites two test cases are
execute: the `Unique*` test case and the `Duplicate` test case. The `Duplicate`
test cases do not interfere with each other since they are static to the
corresponding procedure files. Since the duplicate test cases are found in both
test suites, they are also executed in both.

.. note::

   The Test Run will not execute if the one of the specified test cases can not be
   found in the given list of test suites. This is also applies if no test case
   could be found using a regular expression pattern.

.. _AssertionTypes:

Assertion Types
---------------

An assertion checks that a given condition is true or in more general terms
that an entity fulfills specific properties. Test assertions are defined for
strings, variables and waves and have :code:`ALL_CAPS` names. The assertion
group is specified with a prefix to the assertion name using one of `WARN`,
`CHECK` or `REQUIRE`. Assertions usually come in these triplets which differ
only in how they react on a failed assertion. The following table clarifies the
difference between the three assertion prefix groups:

+-----------+----------------------+-------------------------+-------------------------------+
| Type      | Create Log Message   | Increment Error Count   | Abort execution immediately   |
+===========+======================+=========================+===============================+
| WARN      | YES                  | NO                      | NO                            |
+-----------+----------------------+-------------------------+-------------------------------+
| CHECK     | YES                  | YES                     | NO                            |
+-----------+----------------------+-------------------------+-------------------------------+
| REQUIRE   | YES                  | YES                     | YES                           |
+-----------+----------------------+-------------------------+-------------------------------+

The most simple assertion is :cpp:func:`CHECK` which tests if its argument is
true. If you do not want to increase the error count, you could use the
corresponding :cpp:func:`WARN` function and if you want to Abort the execution
of the current test case if the supplied argument is false, you can use the
:cpp:func:`REQUIRE` variant for this.

Similar to these simple assertions there are many different checks for typical
use cases. Comparing two variables, for example, can be done with
:cpp:func:`WARN_EQUAL_VAR`, or :cpp:func:`REQUIRE_EQUAL_VAR`. Take a look at
:ref:`example10` for a test case with various assertions.

.. note::

   See :ref:`group_assertions` for a complete list of all available checks. If
   in doubt use the `CHECK` variant.

Assertions with only one variant are :cpp:func:`PASS` and :cpp:func:`FAIL`.
If you want to know more about how to use these two special assertions, take a
look at :ref:`example7`.

.. _AbortingTestRun:

Aborting the test run
---------------------

You can abort the execution of the test run by clicking the Abort button in the
status bar or pressing the following user abort key combinations:

+--------------+----------------+
| Command-dot  | Macintosh only |
+--------------+----------------+
| Ctrl+Break   | Windows only   |
+--------------+----------------+
| Shift+Escape | All Platforms  |
+--------------+----------------+
