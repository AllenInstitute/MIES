#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "unit-testing"

/// @brief test two jsonIDs for equal content
Function WARN_EQUAL_JSON(jsonID0, jsonID1)
	variable jsonID0, jsonID1

	string jsonDump0, jsonDump1

	JSONXOP_Dump/IND=2 jsonID0
	jsonDump0 = S_Value
	JSONXOP_Dump/IND=2 jsonID1
	jsonDump1 = S_Value

	WARN_EQUAL_STR(jsonDump0, jsonDump1)
End

Function primitiveOperations()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("1")
	jsonID1 = FormulaParser("1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1)

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = FormulaParser("1+2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"*\":[1,2]}")
	jsonID1 = FormulaParser("1*2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1*2)

	jsonID0 = JSON_Parse("{\"-\":[1,2]}")
	jsonID1 = FormulaParser("1-2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1-2)

	jsonID0 = JSON_Parse("{\"/\":[1,2]}")
	jsonID1 = FormulaParser("1/2")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1/2)
End

Function primitiveOperations2D()
	Variable jsonID
	String array2d

	array2d = "[[1,2],[3,4],[5,6]]"
	Make/FREE input = {{1, 3, 5}, {2, 4, 6}}
	REQUIRE_EQUAL_WAVES(input, FormulaExecutor(FormulaParser(array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input0
	input0[][] = input[p][q] - input[p][q]
	REQUIRE_EQUAL_WAVES(input0, FormulaExecutor(FormulaParser(array2d + "-" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input1
	input1[][] = input[p][q] + input[p][q]
	REQUIRE_EQUAL_WAVES(input1, FormulaExecutor(FormulaParser(array2d + "+" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input2
	input2[][] = input[p][q] / input[p][q]
	REQUIRE_EQUAL_WAVES(input2, FormulaExecutor(FormulaParser(array2d + "/" + array2d)), mode = WAVE_DATA)

	Duplicate/FREE input input3
	input3[][] = input[p][q] * input[p][q]
	REQUIRE_EQUAL_WAVES(input3, FormulaExecutor(FormulaParser(array2d + "*" + array2d)), mode = WAVE_DATA)
End

Function concatenationOfOperations()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"+\":[1,2,3,4]}")
	jsonID1 = FormulaParser("1+2+3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+2+3+4)

	jsonID0 = JSON_Parse("{\"-\":[1,2,3,4]}")
	jsonID1 = FormulaParser("1-2-3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1-2-3-4)

	jsonID0 = JSON_Parse("{\"/\":[1,2,3,4]}")
	jsonID1 = FormulaParser("1/2/3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1/2/3/4)

	jsonID0 = JSON_Parse("{\"*\":[1,2,3,4]}")
	jsonID1 = FormulaParser("1*2*3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1*2*3*4)
End

// + > - > * > /
Function orderOfCalculation()
	Variable jsonID0, jsonID1

	// + and -
	jsonID0 = JSON_Parse("{\"+\":[2,{\"-\":[3,4]}]}")
	jsonID1 = FormulaParser("2+3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2+3-4)

	jsonID0 = JSON_Parse("{\"+\":[{\"-\":[2,3]},4]}")
	jsonID1 = FormulaParser("2-3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2-3+4)

	// + and *
	jsonID0 = JSON_Parse("{\"+\":[2,{\"*\":[3,4]}]}")
	jsonID1 = FormulaParser("2+3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2+3*4)

	jsonID0 = JSON_Parse("{\"+\":[{\"*\":[2,3]},4]}")
	jsonID1 = FormulaParser("2*3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2*3+4)

	// + and /
	jsonID0 = JSON_Parse("{\"+\":[2,{\"/\":[3,4]}]}")
	jsonID1 = FormulaParser("2+3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2+3/4)

	jsonID0 = JSON_Parse("{\"+\":[{\"/\":[2,3]},4]}")
	jsonID1 = FormulaParser("2/3+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2/3+4)

	// - and *
	jsonID0 = JSON_Parse("{\"-\":[2,{\"*\":[3,4]}]}")
	jsonID1 = FormulaParser("2-3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2-3*4)

	jsonID0 = JSON_Parse("{\"-\":[{\"*\":[2,3]},4]}")
	jsonID1 = FormulaParser("2*3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2*3-4)

	// - and /
	jsonID0 = JSON_Parse("{\"-\":[2,{\"/\":[3,4]}]}")
	jsonID1 = FormulaParser("2-3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2-3/4)

	jsonID0 = JSON_Parse("{\"-\":[{\"/\":[2,3]},4]}")
	jsonID1 = FormulaParser("2/3-4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2/3-4)

	// * and /
	jsonID0 = JSON_Parse("{\"*\":[2,{\"/\":[3,4]}]}")
	jsonID1 = FormulaParser("2*3/4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2*3/4)

	jsonID0 = JSON_Parse("{\"*\":[{\"/\":[2,3]},4]}")
	jsonID1 = FormulaParser("2/3*4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2/3*4)

	jsonID1 = FormulaParser("5*1+2*3+4+5*10")
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 5*1+2*3+4+5*10)
End

Function brackets()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = FormulaParser("(1+2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"+\":[1,2]}")
	jsonID1 = FormulaParser("((1+2))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+2)

	jsonID0 = JSON_Parse("{\"+\":[{\"+\":[1,2]},{\"+\":[3,4]}]}")
	jsonID1 = FormulaParser("(1+2)+(3+4)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], (1+2)+(3+4))

	jsonID0 = JSON_Parse("{\"+\":[{\"+\":[4,3]},{\"+\":[2,1]}]}")
	jsonID1 = FormulaParser("(4+3)+(2+1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], (4+3)+(2+1))

	jsonID0 = JSON_Parse("{\"+\":[1,{\"+\":[2,3]},4]}")
	jsonID1 = FormulaParser("1+(2+3)+4")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+(2+3)+4)

	jsonID0 = JSON_Parse("{\"+\":[{\"*\":[3,2]},1]}")
	jsonID1 = FormulaParser("(3*2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], (3*2)+1)

	jsonID0 = JSON_Parse("{\"+\":[1,{\"*\":[2,3]}]}")
	jsonID1 = FormulaParser("1+(2*3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+(2*3))

	jsonID0 = JSON_Parse("{\"*\":[{\"+\":[1,2]},3]}")
	jsonID1 = FormulaParser("(1+2)*3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], (1+2)*3)

	jsonID0 = JSON_Parse("{\"*\":[3,{\"+\":[2,1]}]}")
	jsonID1 = FormulaParser("3*(2+1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 3*(2+1))

	jsonID0 = JSON_Parse("{\"*\":[{\"/\":[2,{\"+\":[3,4]}]},5]}")
	jsonID1 = FormulaParser("2/(3+4)*5")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 2/(3+4)*5)

	jsonID1 = FormulaParser("5*(1+2)*3/(4+5*10)")
	REQUIRE_CLOSE_VAR(FormulaExecutor(jsonID1)[0], 5*(1+2)*3/(4+5*10))
End

Function array()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("[1]")
	jsonID1 = FormulaParser("[1]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,3]")
	jsonID1 = FormulaParser("1,2,3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID1 = FormulaParser("[1,2,3]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[1,2],3,4]")
	jsonID1 = FormulaParser("[[1,2],3,4]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,[2,3],4]")
	jsonID1 = FormulaParser("[1,[2,3],4]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,2,[3,4]]")
	jsonID1 = FormulaParser("[1,2,[3,4]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[1,2],[2,3]]")
	jsonID1 = FormulaParser("[[0,1],[1,2],[2,3]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[4,5]]")
	jsonID1 = FormulaParser("[[0,1],[2,3],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0],[2,3],[4,5]]")
	jsonID1 = FormulaParser("[[0],[2,3],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2],[4,5]]")
	jsonID1 = FormulaParser("[[0,1],[2],[4,5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[[0,1],[2,3],[5]]")
	jsonID1 = FormulaParser("[[0,1],[2,3],[5]]")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"+\":[2,3]}]")
	jsonID1 = FormulaParser("1,2+3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[{\"+\":[1,2]},3]")
	jsonID1 = FormulaParser("1+2,3")
	WARN_EQUAL_JSON(jsonID0, jsonID1)

	jsonID0 = JSON_Parse("[1,{\"/\":[5,{\"+\":[6,7]}]}]")
	jsonID1 = FormulaParser("1,5/(6+7)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
End

// test functions with 1..N arguments
Function minimaximu()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"min\":[1]}")
	jsonID1 = FormulaParser("min(1)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1)

	jsonID0 = JSON_Parse("{\"min\":[1,2]}")
	jsonID1 = FormulaParser("min(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], min(1,2))

	jsonID0 = JSON_Parse("{\"max\":[1,2]}")
	jsonID1 = FormulaParser("max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1,2))

	jsonID0 = JSON_Parse("{\"min\":[1,2,3]}")
	jsonID1 = FormulaParser("min(1,2,3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], min(1,2,3))

	jsonID0 = JSON_Parse("{\"max\":[1,{\"+\":[2,3]}]}")
	jsonID1 = FormulaParser("max(1,(2+3))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1,(2+3)))

	jsonID0 = JSON_Parse("{\"min\":[{\"-\":[1,2]},3]}")
	jsonID1 = FormulaParser("min((1-2),3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], min((1-2),3))

	jsonID0 = JSON_Parse("{\"min\":[{\"max\":[1,2]},3]}")
	jsonID1 = FormulaParser("min(max(1,2),3)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], min(max(1,2),3))

	jsonID0 = JSON_Parse("{\"max\":[1,{\"+\":[2,3]},2]}")
	jsonID1 = FormulaParser("max(1,2+3,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1,2+3,2))

	jsonID0 = JSON_Parse("{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}")
	jsonID1 = FormulaParser("max(1+2,3+4,5+6/7)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1+2,3+4,5+6/7))

	jsonID0 = JSON_Parse("{\"max\":[{\"+\":[1,2]},{\"+\":[3,4]},{\"+\":[5,{\"/\":[6,7]}]}]}")
	jsonID1 = FormulaParser("max(1+2,3+4,5+(6/7))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1+2,3+4,5+(6/7)))

	jsonID0 = JSON_Parse("{\"max\":[{\"max\":[1,{\"/\":[{\"+\":[2,3]},7]},4]},{\"min\":[3,4]}]}")
	jsonID1 = FormulaParser("max(max(1,(2+3)/7,4),min(3,4))")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(max(1,(2+3)/7,4),min(3,4)))

	jsonID0 = JSON_Parse("{\"+\":[{\"max\":[1,2]},1]}")
	jsonID1 = FormulaParser("max(1,2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1,2)+1)

	jsonID0 = JSON_Parse("{\"+\":[1,{\"max\":[1,2]}]}")
	jsonID1 = FormulaParser("1+max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+max(1,2))

	jsonID0 = JSON_Parse("{\"+\":[1,{\"max\":[1,2]},1]}")
	jsonID1 = FormulaParser("1+max(1,2)+1")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], 1+max(1,2)+1)

	jsonID0 = JSON_Parse("{\"-\":[{\"max\":[1,2]},{\"max\":[1,2]}]}")
	jsonID1 = FormulaParser("max(1,2)-max(1,2)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[0], max(1,2)-max(1,2))
End

// test functions with aribitrary length array returns
Function merge()
	Variable jsonID0, jsonID1

	jsonID0 = JSON_Parse("{\"merge\":[1,[2,3],4]}")
	jsonID1 = FormulaParser("merge(1,[2,3],4)")
	WARN_EQUAL_JSON(jsonID0, jsonID1)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[2], 3)
	REQUIRE_EQUAL_VAR(FormulaExecutor(jsonID1)[3], 4)
	WAVE output = FormulaExecutor(jsonID1)
	Make/FREE/N=4/U/I numeric = p + 1
	REQUIRE_EQUAL_WAVES(numeric, output, mode = WAVE_DATA)

	jsonID0 = FormulaParser("[1,2,3,4]")
	jsonID1 = FormulaParser("merge(1,[2,3],4)")
	REQUIRE_EQUAL_WAVES(FormulaExecutor(jsonID0), FormulaExecutor(jsonID1))

	jsonID1 = FormulaParser("merge([1,2],[3,4])")
	REQUIRE_EQUAL_WAVES(FormulaExecutor(jsonID0), FormulaExecutor(jsonID1))

	jsonID1 = FormulaParser("merge(1,2,[3,4])")
	REQUIRE_EQUAL_WAVES(FormulaExecutor(jsonID0), FormulaExecutor(jsonID1))

	jsonID1 = FormulaParser("merge(4/4,4/2,9/3,4*1)")
	REQUIRE_EQUAL_WAVES(FormulaExecutor(jsonID0), FormulaExecutor(jsonID1))
End

Function average()
	Variable jsonID

	// row based evaluation
	jsonID = FormulaParser("avg([0,1,2,3,4,5,6,7,8,9])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_VAR(output[0], mean(testwave))

	jsonID = FormulaParser("mean([0,1,2,3,4,5,6,7,8,9])")
	WAVE output = FormulaExecutor(jsonID)
	REQUIRE_EQUAL_VAR(output[0], mean(testwave))

	// column based evaluation
	jsonID = FormulaParser("avg([[0,1,2,3,4],[5,6,7,8,9],[10,11,12,13,14]])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=(3)/U/I/FREE testwave = 2 + p * 5
	REQUIRE_EQUAL_WAVES(testwave, output, mode = WAVE_DATA)
End

Function statistical()
	Variable jsonID

	// row based evaluation
	jsonID = FormulaParser("variance([0,1,2,3,4,5,6,7,8,9])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=10/U/I/FREE testwave = p
	REQUIRE_EQUAL_VAR(output[0], variance(testwave))

	jsonID = FormulaParser("stdev([0,1,2,3,4,5,6,7,8,9])")
	WAVE output = FormulaExecutor(jsonID)
	REQUIRE_EQUAL_VAR(output[0], sqrt(variance(testwave)))

	// column based evaluation
	jsonID = FormulaParser("variance([[0,1],[1,2],[2,3]])")
	WAVE output = FormulaExecutor(jsonID)
	REQUIRE_EQUAL_VAR(output[0], output[1])
	Make/N=(3)/U/I/FREE testwave = p
	REQUIRE_EQUAL_VAR(output[0], variance(testwave))

	Make/N=(2,3)/U/I/FREE testwave = p + q
	MatrixOP/FREE input = varCols(testwave^t)^t
	REQUIRE_EQUAL_WAVES(input, output)
End


Function testDifferentiales()
	Variable jsonID, array
	String str

	// differntiate/integrate 1D waves along rows
	jsonID = FormulaParser("derivative([0,1,4,9,16,25,36,49,64,81])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=10/U/I/FREE sourcewave = p^2
	Differentiate/EP=0 sourcewave/D=testwave
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	jsonID = FormulaParser("derivative([" + RemoveEnding(str, ",") + "])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=10/FREE testwave = 2 * p
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=10/U/I/FREE input = 2 * p
	wfprintf str, "%d,", input
	jsonID = FormulaParser("integrate([" + RemoveEnding(str, ",") + "])")
	WAVE output = FormulaExecutor(jsonID)
	Make/N=10/FREE testwave = p^2
	Deletepoints 9, 1, testwave, output
	Deletepoints 0, 1, testwave, output
	REQUIRE_EQUAL_WAVES(output, testwave, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p
	wfprintf str, "%d,", input
	jsonID = FormulaParser("derivative(integrate([" + RemoveEnding(str, ",") + "]))")
	WAVE output = FormulaExecutor(jsonID)
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	Make/N=(128)/U/I/FREE input = p^2
	wfprintf str, "%d,", input
	jsonID = FormulaParser("integrate(derivative([" + RemoveEnding(str, ",") + "]))")
	WAVE output = FormulaExecutor(jsonID)
	output -= 0.5 // expected end point error from first point estimation
	Deletepoints 127, 1, input, output
	Deletepoints   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)

	// differentiate 2d waves along columns
	Make/N=(128,16)/U/I/FREE input = p + q
	array = JSON_New()
	JSON_AddWave(array, "", input)
	jsonID = FormulaParser("derivative(integrate(" + JSON_Dump(array) + "))")
	JSON_Release(array)
	WAVE output = FormulaExecutor(jsonID)
	Deletepoints/M=(ROWS) 127, 1, input, output
	Deletepoints/M=(ROWS)   0, 1, input, output
	REQUIRE_EQUAL_WAVES(output, input, mode = WAVE_DATA)
End
