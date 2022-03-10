Thirty six hints for writing analysis functions
===============================================

#. Create an issue with the description of the new analysis function.
   Also define its name and two letter abbreviation (which must not collide with existing ones).

#. Always track *any* open items in task lists in the issue or the PR itself.

#. Think about what should happen at each event. As a rule of thumb we want
   to do only what is really needed in ``MID_SWEEP_EVENT`` (if that is used at
   all). The common QC entries are determined in the following events:
   - Sweep QC in ``POST_SWEEP_EVENT``
   - Set QC in ``POST_SET_EVENT``
   - Baseline QC in ``MID_SWEEP_EVENT``/``POST_SWEEP_EVENT``.

#. Create a list of used labnotebook keys. The question which labnotebook keys
   are required can be answered by thinking about how the dashboard will interpret
   the analysis function run results. Only if it can decide, by looking at
   labnotebook entries, for each possible outcome exactly why the run failed, all
   labnotebook keys were thought of.

#. Create a list of used user epochs.

#. Create a list of analysis function parameters including required/optional
   state and for the latter also the default values.

#. Units for labnotebook keys should be added if possible. For physical units we
   tend to prefer base units without prefix, i.e. Ω instead of GΩ.

#. Decide if the new labnotebook entries should be headstage dependent or not.
   The existing entries don't do a very good job in guiding you here. An
   ideal choice is that the ``DEPEND``/``INDEP`` type of a entry would not
   have to be changed if the analysis function would need to support more or
   fewer headstages.

#. Make a list of additional features and/or changes in common ``PSQ_``/``MSQ_`` functions you
   need.

#. Draw a preliminary flowchart, on paper is fine. This serves as a way to think the behaviour through.
   Have a look at existing flowcharts for inspiration.

#. Create a stimulus set for testing. The test stimsets can be loaded via
   ``LoadStimsets`` and saved via ``SaveStimsets`` available in
   HardwareTests.pxp.

#. At this point you should have a pretty good idea what needs to be done.
   Discuss what you think you need to do with your boss.

#. Add a skeleton analysis function, see `here <https://alleninstitute.github.io/MIES/file/_m_i_e_s___analysis_functions_8ipf.html>`__,
   and add all analysis parameters, their help messages and check code.

#. Add documentation for labnotebook keys and user epochs to the tables at the
   top of ``MIES_AnalysisFunctions_PatchSeq.ipf``/``MIES_AnalysisFunctions_MultiPatchSeq.ipf``

#. Implement the test override entries in
   :cpp:func:`PSQ_CreateOverrideResults`/:cpp:func:`MSQ_CreateOverrideResults` with
   documentation.

#. Implement the behaviour for each event. Going from easy to difficult has proven to work.

#. Now you should have a first version. Congratulation! Pad yourself on the
   back and take a break, because now the real fun starts.

#. Add preliminary dashboard support. We do check for every testcase that
   the dashboard works.

#. Create a new test suite and add it to ``UTF_HardwareMain.ipf``. Be sure to
   base it on the test suite of the last added analysis function to avoid copying
   deprecated approaches.

#. Add a first test case were all test override entries result in failed QC.

#. As rule of thumb what to check in each test case; be sure to have test
   assertions for all added labnotebook entries (except standard baseline
   entries) and position checking of user epochs.

#. Make that first test case pass, this takes a surprisingly long time. The
   function :cpp:func:`LBV_PlotAllAnalysisFunctionLBNKeys` helps for debugging.

#. After this first test case passes, reassess the test assertions. Are you testing enough or too much?

#. Writeup a test matrix for determining what needs to be
   tested, first version in paper is fine. The columns are the inputs,
   usually these are test overrides and analysis parameters.

   See ``UTF_PatchSeqSealEvaluation.ipf`` for an example.

   We always have the following three test cases:

     - The first has all QC (except ``Sampling Interval QC``) failing.
     - The secon has all QC passing.
     - The last one only has ``Sampling Interval QC`` failing.

#. Implement all test cases, fixing bugs in the analysis function on the way.

#. Run all tests for this analysis function with instrumentation.

#. Check the coverage output to see if you still have relevant gaps in testing.

#. Add new test cases for filling coverage gaps.

#. Repeat the last three points until the coverage is good enough.

#. Check if some helper code etc. can/should be fleshed out into its own pull request.

#. Be sure to include documentation and tests if your analysis function
   publishes ZeroMQ messages. See ``CheckPipetteInBathPublishing`` and
   :cpp:func:`PSQ_PB_Publish` for an example. Add it also in
   ``CheckPublishedMessage``.

#. Tell your boss to test the current state.

#. Check and fill any gaps in the documentation:

   - Analysis function comment with ascii art stimulus sets
   - Labnotebook entries
   - User epochs

#. Create digital versions of the test matrix and the flowchart. For the
   latter see `here <https://github.com/AllenInstitute/MIES/tree/main/Packages/doc/dot#readme>`__.

#. Cleanup commits

#. Your done!
