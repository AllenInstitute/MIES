.. vim: set et sts=3 sw=3 tw=79:

.. _introduction:

What is a Universal Testing Framework?
======================================

The purpose of every program is to ensure that a specific task is performed
reliably in a defined matter. Therefore, programming is all about testing and
quality control of the produced source code. These two workflow tasks are
entirely optional but are especially important when it comes to hazard and
risk-sensitive tasks, as well as security-relevant features of software with
critical to catastrophic consequences. More generally speaking, it contributes
to a clean, professional look and better working experience if software works
in a defined way and unit tests help to define this way.

Testing
-------

A program gets tested in various ways during development: A first test usually
involves the syntactic correctness and the correct usage of external libraries.
It ensures that the program compiles and that it produces output for a given
task. Complex scenarios typically afford a much larger codebase and a more
profound investigation of the involved interfaces. The more complex the
scenarios a program can handle, the more time is involved in its production.
Therefore it is crucial to define the program's interface to indicate what it
is capable of, and what not, to prevent it getting used in the wrong context.

One standard in quality control is the four-eyes-check by two persons.  Writing
professional code in a lean and agile, continuous delivery software
environment, usually involves this additional peer review step. The review step
is an attempt to separate code production, and testing to separate persons as
the perception of the tester adds valuable input to the code leading to quicker
deployment of quality software.

A review typically involves testing the functionality of the code output for
different inputs. These tests are equally performed during code production and
review stages. The problem, this review step is targeting onto, is that a
programmer typically does not think of all critical test situations. The
tester, in turn, does not know about the code and its context and therefore the
reviewer needs time to understand the context of the program. In an attempt to
save valuable time, review and code production have to be based on a definition
for the produced functionality which can be for example the creation of a valid
file format. Such a definition allows the tester to perform tests without
necessarily needing to hack into the code base. Defining these tests somewhere
records the current functionality of the program and protects it against
changes.

Even though, the review process guarantees a higher level of quality, the
additional assessment requires an assignment of double the developing resources
and those resources are usually considered precious. In this context, automated
test environments minimize production time and ensure a consistent level of
quality. This level of quality can then consistently get maintained over time
when further changes are introduced to the unit.

Unit Tests
----------

To be able to perform automated tests, the code is typically organized in
functional units. A unit is a part of software inside a project that performs a
particular task. Typically this unit is isolated and runs on a linearly
independent path inside the code. The unit communicates via an interface which
accepts inputs and produces outputs.

.. code::

             ########
   input --> # unit # --> output
             ########

In the most simple case, a unit is a function. The parameters which get passed
to the function define the input interface, and the return value is the output
interface. In a more complex scenario, such a unit could be responsible for
converting one file to another format.

A unit can be checked for valid output by defining a :ref:`suite of tests
<TestSuite>`. The test suite is further grouped into atomically small tests
which are called :ref:`Test Cases <TestCase>`. A test case typically checks
that an entity fulfills specific properties and a unit produces valid output
for a given input. Within these checks, the result of defined inputs is
compared against defined outputs. The comparisons are performed using different
types of :ref:`Assertions <AssertionTypes>`. As long as all test cases inside a
test suite are executed correctly, the tested functionality of the unit is maintained.
Performing these checks on a regular basis also ensures that a consistent level
of quality and a defined functionality is maintained upon changes to the code.

Agile Development
-----------------

When using version control systems like `git <https://git-scm.com/>`_, the
introduced changes are typically tested with test pipelines before applying
the changes by using apps like `jenkins <https://jenkins.io/>`_ or `gitlab
<https://docs.gitlab.com/ee/ci/>`_. These automated tests introduce a step prior
to the review process which makes the review more clear and transparent and
allow a quicker code review. `This Framework
<https://www.wavemetrics.com/project/unitTesting>`_ enables unit tests for
continuous integration and continuous delivery environments in `Igor Pro
<https://www.wavemetrics.com/>`_. Do not hesitate to `contact us
<https://www.byte-physics.de/en/kontakt.html>`_ if you need further assistance
in creating a professional CI/CD workflow for your Igor Pro project to ensure a
higher level of quality in your code.
