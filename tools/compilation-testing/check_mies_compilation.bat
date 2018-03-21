del/Q *.txt *.log *.xml

echo MIES_Include     >> input.txt
echo UTF_Main         >> input.txt
echo UTF_HardwareMain >> input.txt

call autorun-test.bat
pause
