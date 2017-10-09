del/Q *.txt *.log *.xml

echo MIES_Include          >> input.txt
echo MIES_AnalysisBrowser  >> input.txt
echo MIES_Databrowser      >> input.txt
echo MIES_WavebuilderPanel >> input.txt
echo MIES_Downsample       >> input.txt

call autorun-test.bat
pause
