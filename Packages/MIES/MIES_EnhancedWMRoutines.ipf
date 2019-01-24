#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method and strict wave access.

/// @file MIES_EnhancedWMRoutines.ipf
/// @brief Routines packaged with IGOR PRO but enhanced from us
///
/// Everthing in this file is copyrighted by WaveMetrics Inc.

/// @name Functions taken from `Waves Average.ipf` from Igor Pro 6.3.6.4
/// @{

Function MIES_fWaveAverage(ListOfWaves, ListOfXWaves, ErrorType, ErrorInterval, AveName, ErrorName)
	String ListOfWaves		// Y waves
	String ListOfXWaves		// X waves list. Pass "" if you don't have any.
	Variable ErrorType		// 0 = none; 1 = S.D.; 2 = Conf Int; 3 = Standard Error
	Variable ErrorInterval	// if ErrorType == 1, # of S.D.'s; ErrorType == 2, Conf. Interval
	String AveName, ErrorName

	Variable numWaves = ItemsInList(ListOfWaves)
	if (numWaves < 2 )
		ErrorType= 0	// don't generate any errors when "averaging" one wave.
	endif

	// our tweaks might have broken some unusual setups, don't allow these
	ASSERT(ErrorType == 0 , "ErrorTypes are not properly tested")
	ASSERT(isEmpty(ListOfXWaves), "X waves are not properly tested")
	ASSERT(!isEmpty(ListOfWaves), "ListOfWaves must not be empty")

	if ( ErrorType == 2)
		if ( (ErrorInterval>100) || (ErrorInterval < 0) )
			DoAlert 0, "Confidence interval must be between 0 and 100"
			return -1
		endif
		ErrorInterval /= 100
	endif

	// check the input waves, and choose an appropriate algorithm
	Variable maxLength = 0
	Variable differentLengths= 0
	Variable differentXRanges= 0
	Variable rawDeltaX=NaN			// 6.35: keep track of common deltaX for waveforms.
	Variable differentDeltax= 0	// 6.35: use interpolation if deltax's are different, even if simply reversed in sign.
	Variable thisXMin, thisXMax, thisDeltax
	Variable minXmin, maxXmax, minDeltax
	Variable numXWaves=0
	String firstXWavePath = StringFromList(0,ListOfXWaves)
	Variable XWavesAreSame=1	// assume they are until proven differently. Irrelevant if	numXWaves!=numWaves
	Variable i
	Make/D/N=(numWaves,2)/FREE xRange	// [i][0] is xMin, [i][1] is xMax

	for (i = 0; i < numWaves; i += 1)
		String theWaveName=StringFromList(i,ListOfWaves)
		Wave/Z w=$theWaveName
		if (!WaveExists(w))
			DoAlert 0, "A wave in the list of waves ("+theWaveName+") cannot be found."
			return -1
		endif
		Variable thisLength= numpnts(w)
		String theXWavePath=StringFromList(i,ListOfXWaves)
		Wave/Z theXWave= $theXWavePath
		if( WaveExists(theXWave) )
			Variable isMonotonicX = MonotonicCheck(theXWave,thisDeltax)	// thisDeltax is set to min difference in the x wave
			if( !isMonotonicX )
				DoAlert 0, theXWavePath+" is not sorted (or has duplicate x values) and cannot be used to compute the average. You should sort both "+theXWavePath+" and "+theWaveName+"."
				return -1
			endif
			WaveStats/Q/M=0 theXWave
			thisXMin= V_Min
			thisXMax= V_Max
			numXWaves += 1
			if( CmpStr(theXWavePath,firstXWavePath) != 0 )	//comparing full paths, not wave values
				XWavesAreSame=0
			endif
		else
			thisDeltax= deltax(w)
			thisXMin= leftx(w)
			thisXMax= rightx(w)-thisDeltax	// SetScale/I values.
			XWavesAreSame=0	// at least 1 y wave has no x wave
			// 6.35: point-for-point averaging requires the deltaX of all waves to be identical.
			if( numtype(rawDeltaX) != 0 )
				rawDeltaX = thisDeltaX	// remember first deltaX before abs() below
			elseif( thisDeltax != rawDeltaX )
				differentDeltax= 1	// don't do point-for-point averaging.
			endif
		endif
		xRange[i][0]= thisXMin
		xRange[i][1]= thisXMax
		if( i > 0 )
			if( thisLength != maxLength )
				differentLengths= 1
			endif
			if( (thisXMin != minXmin) || (thisXMax != maxXmax) )
				differentXRanges= 1	// this also includes the case where identical ranges but one or more is swapped
			endif
			if( i == 1 )
				// handle case where first wave's x range is swapped.
				if( minXmin > maxXmax )	// swapped X range (X values decrease with increasing point number)
					Variable tmp= minXmin
					minXmin= maxXmax
					maxXmax= tmp
				endif
			endif
			if( thisXMin > thisXMax )	// swapped X range (X values decrease with increasing point number)
				tmp= thisXMin
				thisXMin= thisXMax
				thisXMax= tmp
			endif
			// accumulate x ranges
			minXmin= min(minXmin, thisXMin)
			maxXmax= max(maxXmax, thisXMax)
			// find smallest deltax
			thisDeltax= abs(thisDeltax)
			if( thisDeltax > 0 && (thisDeltax < minDeltax) )
				minDeltax= thisDeltax
			endif
		else
			minXmin= thisXMin
			maxXmax= thisXMax
			minDeltax= abs(thisDeltax)
			if( minDeltax == 0 )
				thisDeltax= inf
			endif
		endif
		maxLength = max(maxLength, thisLength)
	endfor

	Variable doPointForPoint
	if( numXWaves && !XWavesAreSame )
		doPointForPoint= 0
	else
		doPointForPoint = (!differentXRanges && !differentLengths && !differentDeltax) || numtype(minDeltaX) != 0 || minDeltaX == 0
	endif

	if( doPointForPoint )
		Make/N=(maxLength)/D/FREE AveW, TempNWave

#if (IgorVersion() >= 8.00)
		Concatenate/FREE ListOfWaves, fullWave
		MatrixOP/FREE AveW      = sumRows(replaceNaNs(fp64(fullWave), 0))
		MatrixOP/FREE TempNWave = sumRows(equal(numtype(fullWave), 0))
		WaveClear fullWave
#endif

		Wave w=$StringFromList(0,ListOfWaves)
		CopyScales/P w, AveW, TempNWave

#if (IgorVersion() < 8.00)
		for (i = 0; i < numWaves; i += 1)
			WAVE w=$StringFromList(i,ListOfWaves)
			MultiThread AveW[]      += !numtype(w[p]) * w[p]
			MultiThread TempNWave[] += !numtype(w[p])
		endfor
#endif

		MultiThread AveW /= TempNWave
		Duplicate/O AveW, $AveName

		if (ErrorType)
			Duplicate/O AveW, $ErrorName
			Wave/Z SDW=$ErrorName
			SDW = 0
			i=0
			for (i = 0; i < numWaves; i += 1)
				WAVE w = $StringFromList(i,ListOfWaves)
				variable npnts = numpnts(w)
				variable j
				for (j = 0; j < npnts; j += 1)
					if (numtype(w[j]) == 0)
						SDW[j] += (w[j]-AveW[j])^2
					endif
				endfor
			endfor
			SDW /= (TempNWave-1)
			SDW = sqrt(SDW)			// SDW now contains s.d. of the data for each point
			if (ErrorType > 1)
				SDW /= sqrt(TempNWave)	// SDW now contains standard error of mean for each point
				if (ErrorType == 2)
					SDW *= StudentT(ErrorInterval, TempNWave-1) // CLevel confidence interval width in each point
				endif
			else
				SDW *= ErrorInterval
			endif
		endif
	else
		// can't do point-for-point because of different point range or scaling or there are multiple X waves
		Variable firstAvePoint,lastAvePoint,point,xVal,yVal

		Variable newLength= 1 + round(abs(maxXmax - minXmin) / minDeltaX)
		maxLength= min(maxLength*4,newLength)	// avoid the case where one very small deltaX in an XY pair causes a huge wave to be created.

		Make/N=(maxLength)/D/FREE AveW, TempNWave, TempYWave
		Wave w=$StringFromList(0,ListOfWaves)
		CopyScales w, AveW // just to get the data and x units
		SetScale/I x, minXmin, maxXmax, AveW	// set X scaling to all-encompassing range

		for (i = 0; i < numWaves; i += 1)
			thisXMin= xRange[i][0]
			thisXMax= xRange[i][1]
			if( thisXMin > thisXMax )	// swapped X range (X values decrease with increasing point number)
				tmp= thisXMin
				thisXMin= thisXMax
				thisXMax= tmp
			endif
			firstAvePoint= ceil(x2pntWithFrac(AveW,thisXMin))	// truncate the partial point numbers...
			lastAvePoint= floor(x2pntWithFrac(AveW,thisXMax))	// ... by indenting slightly
			WAVE wy=$StringFromList(i,ListOfWaves)
			Wave/Z wx= $StringFromList(i,ListOfXWaves)
			if(WaveExists(wx))
				MultiThread TempYWave[firstAvePoint, lastAvePoint] = interp(pnt2x(AveW, p), wx, wy)
			else
				MultiThread TempYWave[firstAvePoint, lastAvePoint] = wy(pnt2x(AveW, p))
			endif

			MultiThread AveW[firstAvePoint, lastAvePoint]      += !numtype(TempYWave[p]) * TempYWave[p]
			MultiThread TempNWave[firstAvePoint, lastAvePoint] += !numtype(TempYWave[p])
		endfor

		//  points with no values added are set to NaN here:
		MultiThread AveW= (TempNWave[p] == 0) ? NaN : AveW[p] / TempNWave[p]
		Duplicate/O AveW, $AveName

		if (ErrorType)
			Duplicate/O AveW, $ErrorName
			Wave/Z SDW=$ErrorName
			SDW = 0

			for (i = 0; i < numWaves; i += 1)
				thisXMin= xRange[i][0]
				thisXMax= xRange[i][1]
				if( thisXMin > thisXMax )	// swapped X range (X values decrease with increasing point number)
					tmp= thisXMin
					thisXMin= thisXMax
					thisXMax= tmp
				endif
				firstAvePoint= ceil(x2pntWithFrac(AveW,thisXMin))	// truncate the partial point numbers...
				lastAvePoint= floor(x2pntWithFrac(AveW,thisXMax))	// ... by indenting slightly
				WAVE wy=$StringFromList(i,ListOfWaves)
				Wave/Z wx= $StringFromList(i,ListOfXWaves)
				for (point = firstAvePoint; point <= lastAvePoint; point += 1)
					xVal= pnt2x(AveW, point)
					if( WaveExists(wx) )
						yVal= interp(xVal, wx, wy)
					else
						yVal= wy(xVal)
					endif
					if (numtype(yVal) == 0)
						SDW[point] += (yVal-AveW[point]) * (yVal-AveW[point])
					endif
				endfor
			endfor
			MultiThread SDW= (TempNWave[p] <= 1) ? NaN : sqrt(SDW[p] / (TempNWave[p] -1))	// SDW now contains s.d. of the data for each point
			if (ErrorType > 1)
				MultiThread SDW= (TempNWave[p] == 0) ? NaN : SDW[p] / sqrt(TempNWave[p])	// SDW now contains standard error of mean for each point
				if (ErrorType == 2)
					MultiThread SDW = (TempNWave[p] <= 1) ? NaN : SDW[p] * StudentT(ErrorInterval, TempNWave[p]-1) // Confidence Level confidence interval width in each point
				endif
			else
				MultiThread SDW = SDW[p] * ErrorInterval	// ???
			endif
		endif

	endif
	return doPointForPoint
End

static Function MonotonicCheck(wx,smallestXIncrement)
	Wave wx
	Variable &smallestXIncrement	// output

	Variable isMonotonic=0

	Duplicate/Free wx, diff
	Differentiate/DIM=0/EP=0/METH=1/P diff
	WaveStats/Q/M=0 diff
	isMonotonic= (V_min > 0) == (V_max > 0)

	diff= abs(diff[p])
	WaveStats/Q/M=0 diff
	smallestXIncrement= V_Min

	return isMonotonic && smallestXIncrement != 0
End

// We need the fractional point number but x2pnt
// doesn't return that.
static Function x2pntWithFrac(wv, scaledDim)
	WAVE wv
	variable scaledDim

	return (scaledDim - DimOffset(wv, 0)) / DimDelta(wv,0)
End
/// @}
