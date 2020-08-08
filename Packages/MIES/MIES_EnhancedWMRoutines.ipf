#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=1		// Use modern global access method and strict wave access.

/// @file MIES_EnhancedWMRoutines.ipf
/// @brief Routines packaged with IGOR PRO but enhanced from us
///
/// Everthing in this file is copyrighted by WaveMetrics Inc.

/// @name Functions taken from `Waves Average.ipf` from Igor Pro 6.3.6.4
/// @{

/// @brief Average the given waves
///
/// @param yWaves          Y waves
/// @param ignoreNaNs      Ignoring NaNs means that the average does skip over NaNs.
/// @param averageWaveType wave type of the average wave. Currently supported
///                        are #IGOR_TYPE_64BIT_FLOAT and #IGOR_TYPE_32BIT_FLOAT.
///
/// @return free wave with the average
threadsafe Function/WAVE MIES_fWaveAverage(WAVE/Z yWaves, variable ignoreNaNs, variable averageWaveType)

	// check the input waves, and choose an appropriate algorithm
	Variable maxLength = 0
	Variable differentLengths= 0
	Variable differentXRanges= 0
	Variable rawDeltaX=NaN			// 6.35: keep track of common deltaX for waveforms.
	Variable differentDeltax= 0	// 6.35: use interpolation if deltax's are different, even if simply reversed in sign.
	Variable thisXMin, thisXMax, thisDeltax
	Variable minXmin, maxXmax, minDeltax
	Variable numXWaves=0
	Variable XWavesAreSame=1	// assume they are until proven differently. Irrelevant if	numXWaves!=numWaves
	Variable i

	ignoreNaNs = !!ignoreNaNs

	if(!WaveExists(yWaves))
		return $""
	endif

	Variable numWaves = DimSize(ywaves, ROWS)

	if(numWaves == 0)
		return $""
	endif

	WAVE/WAVE waves = yWaves

	Make/D/N=(numWaves,2)/FREE xRange	// [i][0] is xMin, [i][1] is xMax

	for (i = 0; i < numWaves; i += 1)
		Wave/Z w=waves[i]
		ASSERT_TS(WaveExists(w), "A wave in the list of waves cannot be found.")

		Variable thisLength= numpnts(w)
		thisDeltax= deltax(w)
		thisXMin= leftx(w)
		thisXMax= pnt2x(w, numpnts(w) - 1)
		XWavesAreSame=0	// at least 1 y wave has no x wave
		// 6.35: point-for-point averaging requires the deltaX of all waves to be identical.
		if( numtype(rawDeltaX) != 0 )
			rawDeltaX = thisDeltaX	// remember first deltaX before abs() below
		elseif( thisDeltax != rawDeltaX )
			differentDeltax= 1	// don't do point-for-point averaging.
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
	doPointForPoint = (!differentXRanges && !differentLengths && !differentDeltax) || numtype(minDeltaX) != 0 || minDeltaX == 0

	if(doPointForPoint)
		Concatenate/FREE {waves}, fullWave

		if(ignoreNaNs)
			if(averageWaveType == IGOR_TYPE_32BIT_FLOAT)
				MatrixOP/FREE AveW = fp32(sumRows(replaceNaNs(fp64(fullWave), 0)) / sumRows(equal(numtype(fullWave), 0)))
			elseif(averageWaveType == IGOR_TYPE_64BIT_FLOAT)
				MatrixOP/FREE AveW = sumRows(replaceNaNs(fp64(fullWave), 0)) / sumRows(equal(numtype(fullWave), 0))
			else
				ASSERT_TS(0, "Not supported")
			endif
		else
			Make/FREE/N=(maxLength)/Y=(averageWaveType) AveW
			if(averageWaveType == IGOR_TYPE_32BIT_FLOAT)
				MatrixOP/FREE AveW = fp32(sumRows(fullWave) / numWaves)
			elseif(averageWaveType == IGOR_TYPE_64BIT_FLOAT)
				MatrixOP/FREE AveW = fp64(sumRows(fullWave) / numWaves)
			endif
		endif

		CopyScales/P waves[0], AveW

		return AveW
	else
		// can't do point-for-point because of different point range or scaling
		Variable firstAvePoint,lastAvePoint,point,xVal,yVal

		Variable newLength= 1 + round(abs(maxXmax - minXmin) / minDeltaX)
		maxLength= min(maxLength*4,newLength)	// avoid the case where one very small deltaX in an XY pair causes a huge wave to be created.

		Make/FREE/N=(maxLength)/Y=(averageWaveType) AveW, TempNWave, TempYWave
		Wave w = waves[0]
		CopyScales w, AveW // just to get the data and x units
		SetScale/I x, minXmin, maxXmax, AveW // set X scaling to all-encompassing range

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
			WAVE wy = waves[i]
			MultiThread TempYWave[firstAvePoint, lastAvePoint] = wy(limit(pnt2x(AveW, p), thisXMin, thisXMax))

			if(ignoreNaNs)
				MultiThread AveW[firstAvePoint, lastAvePoint]      += !numtype(TempYWave[p]) ? TempYWave[p] : 0
				MultiThread TempNWave[firstAvePoint, lastAvePoint] += !numtype(TempYWave[p])
			else
				MultiThread AveW[firstAvePoint, lastAvePoint] += TempYWave[p]
				MultiThread TempNWave[firstAvePoint, lastAvePoint] += 1
			endif
		endfor

		//  points with no values added are set to NaN here:
		MultiThread AveW= (TempNWave[p] == 0) ? NaN : AveW[p] / TempNWave[p]

		return AveW
	endif
End

// We need the fractional point number but x2pnt
// doesn't return that.
threadsafe static Function x2pntWithFrac(wv, scaledDim)
	WAVE wv
	variable scaledDim

	return (scaledDim - DimOffset(wv, 0)) / DimDelta(wv,0)
End
/// @}
