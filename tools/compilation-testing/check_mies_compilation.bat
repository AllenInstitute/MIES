del/Q *.txt *.log

echo MIES_Include > input.txt
call autorun-test.bat
move compilationState.txt IncludeState.txt

echo MIES_AnalysisBrowser > input.txt
call autorun-test.bat
move compilationState.txt AnalysisBrowserState.txt

echo MIES_Databrowser > input.txt
call autorun-test.bat
move compilationState.txt dataBrowserState.txt

echo MIES_WavebuilderPanel > input.txt
call autorun-test.bat
move compilationState.txt WaveBuilderPanelState.txt

echo MIES_Downsample > input.txt
call autorun-test.bat
move compilationState.txt DownsampleState.txt

cls

@echo Results (4 means compiles, everything else not)
type IncludeState.txt
echo :Include
type AnalysisBrowserState.txt
echo :AnalysisBrowser
type DatabrowserState.txt
echo :Databrowser
type WaveBuilderPanelState.txt
echo :WavebuilderPanel
type DownsampleState.txt
echo :Downsample

pause
