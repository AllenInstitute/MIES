#pragma rtGlobals=1		// Use modern global access method.
/// @todo switch to rtGlobals=3

/// @file MIES_EventDetectionCode.ipf
/// @brief __EDC__ Event detection code

/// @brief Find Minis either with template or derivative method
/// Removes template minis which overlap
/// Displays them in a graph
Function EDC_FindMinis(workDFR, data)
	DFREF workDFR
	WAVE data

	variable duration, numIndices, i, j
	variable int = 100 /// @todo seems to be some kind of sampling interval in ms
	string wvName

	variable threshold = 10
	variable method    = 1
	variable rise      = 0.5
	variable decay     = 1

	Prompt threshold, "Detection threshold (try 10):"
	Prompt method   , "Detecton method (0 for template, 1 for derivative):"
	Prompt rise     , "Template rise time (ms):"
	Prompt decay    , "Template decay tau (ms):"
	DoPrompt "Enter settings for event searching algorithm", threshold, method, rise, decay

	if(V_flag)
		return NaN
	endif

	duration = 7 * decay

	wvName = NameOfWave(data) + "_peaks"
	Duplicate/O data, workDFR:$wvName/Wave=peaks
	FastOp peaks = 0
	wvName = NameOfWave(data) + "_indices"
	Duplicate/O data, workDFR:$wvName/Wave=indices
	FastOp indices = 0

	if(method == 1)
		EDC_MiniDeriv(data, peaks, indices, threshold, duration)
	else
		EDC_MiniTemplate(data, peaks, indices, int, rise, decay, duration, threshold)
		Duplicate/FREE indices, tempindices

		numIndices = DimSize(indices, ROWS)
		for(i = 1; i < numIndices; i += 1)
			// takes out indices where minis overlap
			if(indices[i + 1] - indices[i] < duration/int || indices[i] - indices[i - 1] < duration/int)
				tempindices[i] = 0
			else
				j += 1
			endif
			i += 1
		endfor

		indices = tempindices
		Sort/R indices, indices
		Redimension/N=(j) indices
		Sort indices, indices
	endif

	Display data
	ModifyGraph axisEnab(left)={0, 0.75}
	AppendToGraph/R peaks
	ModifyGraph axisEnab(right)={0.80, 1}
	ModifyGraph nticks(right)=2
End

/// @brief Find minis with derivative method
static Function EDC_MiniDeriv(data, peaks, indices, threshold, duration)
	WAVE data, peaks, indices
	variable threshold, duration

	variable numPeaks

	Duplicate/FREE data, deriv
	Differentiate deriv
	Smooth 10, deriv

	numPeaks = EDC_PeakFinder(deriv, peaks, indices, threshold)
	Redimension/N=(numPeaks) indices
End

/// @brief Find peaks in the wave `data` this wave must be the derivative of the original data
static Function EDC_PeakFinder(data, peaks, indices, threshold)
	WAVE data, peaks, indices
	variable threshold

	variable i, j, numRows

	numRows = DimSize(data, ROWS)
	for(i = 0; i < numRows; i += 1)
		if(data[i] < data[i + 1] && data[i] < data[i - 2] && data[i] < data[i - 1] && data[i] < -threshold)
			peaks[i]   = -10 // TB: 10 is the default value of threshold. Coincidence?
			indices[j] = i
			j += 1
		endif
	endfor

	return j
End

/// @brief Find peaks in the wave `data` using the sliding template method
static Function EDC_MiniTemplate(data, peaks, indices, int, rise, decay, duration, threshold)
	WAVE data, peaks, indices
	variable int, rise, decay, duration, threshold

	variable numPeaks

	duration *= 1/int // creates template from alpha function

	Make/FREE/D/N=(duration) template
	SetScale/P x 0, int, "", template

	template[] = (1 - exp(-x/rise)) * exp(-x/decay)

	WAVE DC = EDC_SlidingTemplate(data, template)
	numPeaks = EDC_PeakFinder(DC, peaks, indices, threshold)
	Redimension/N=(numPeaks) indices
End

/// @brief Sliding template algorithm
/// @todo fix out-of-bounds accesses
///
/// Implemented from the paper:
///	Clements JD, Bekkers JM.<br>
///	Detection of spontaneous synaptic events with an optimally scaled template.<br>
///	Biophysical Journal. 1997;73(1):220-229.<br>
///	http://dx.doi.org/10.1016%2FS0006-3495(97)78062-7<br>
static Function/WAVE EDC_SlidingTemplate(events, template)
	WAVE events
	WAVE template

	variable scl, offset, N, loops, sum_temp, sum_temp_sq, sum_data, std_err, SSE, d_c, i, j

	N = DimSize(template, ROWS)	  // how many points of raw data to take at once?
	loops = DimSize(events, ROWS) // how many times to shift template?
	Duplicate/FREE events, DC
	DC = 0

	Duplicate/FREE template fit_temp, data, temp_X_data, temp_sq, d_m_f_t_s // Make waves, constants for scaling
	temp_sq[] = template[p] * template[p]
	sum_temp_sq = sum(temp_sq)
	sum_temp = sum(template)

	for(i = 0; i < loops; i += 2)
		data = events[i + p] // takes a chunk of mini data
		Smooth/B 5, data
		sum_data      = sum(data)
		temp_X_data[] = template[p] * data[p]
		scl           = (sum(temp_X_data) - sum_temp * sum_data / N) / (sum_temp_sq - sum_temp * sum_temp / N)
		offset        = (sum_data - scl * sum_temp) / N
		fit_temp[]    = template * scl + offset
		d_m_f_t_s     = (data - fit_temp) * (data - fit_temp) // starts to calculate detection criterion

		SSE     = sum(d_m_f_t_s)
		std_err = sqrt(SSE / (N - 1))
		d_c     = scl / std_err

		DC[i]     = d_c
		/// @todo the following line of code is *not* in the paper
		DC[i - 1] = (DC[i - 2] + d_c) / 2
	endfor

	return DC
End

/// @todo not cleanuped and ported
/// we might need it later on, so we keep it
///
//Macro AnalyzeMinis(minis, auto, length, block)
//	string minis= "minis"
//	string auto= "no"
//	variable length = 7, block = 80
//	Prompt minis, "Mini WAVE:"
//	Prompt auto, "Accept all marked minis (yes or no)?"
//	Prompt length, "Averaged mini length (ms):"
//	Prompt block, "Block size (ms):"
//	Silent 1
//
//	variable/G root:V_fitmaxiters=500
//
//	variable zeropeaks
//	variable i, j, k, l, m, start, peak
//
//	length/=int
//	Wavestats/Q $minis
//	zeropeaks = (abs(V_avg) - 10) // takes average of concatenated mini WAVE and subtracts 10 from it??????
//	Duplicate/O $minis+"_peaks" Displaypeaks
//	Displaypeaks-=(zeropeaks) // Makes a WAVE equal to zero peaks variable
//	Make/O/N=(length) isolated_mini, average_mini // Makes waves who's length is the "length"/sampling int.
//	SetScale/P x 0, int, "", isolated_mini, average_mini
//	Make/O/N=(numpnts($minis+"_indices"))/D miniloc, miniamp, discarded_indices, minirise, minipos
//	Make/O/N=1 a, b, c, d
//	Display a vs b
//	Append c vs d
//	ModifyGraph mode = 3, marker=19, rgb=(0, 0, 0)
//	ModifyGraph rgb(c)=(0, 39168, 19712)
//	Make/O/N=(10/int) view1, view2, view3
//	Append view1, view2, view3
//	ModifyGraph rgb(view3)=(0, 0, 65280)
//
//	do
//		Duplicate/O/R=[$minis+"_indices"[i] - (0.3 * length), $minis+"_indices"[i] + (1.7 * length)]$minis view1
//		Duplicate/O/R=[$minis+"_indices"[i] - (0.3 * length), $minis+"_indices"[i] + (1.7 * length)]Displaypeaks view2
//		Duplicate/O/R=[$minis+"_indices"[i] - (.5/int), $minis+"_indices"[i] + (.8/int)]$minis view3
//		Duplicate/O view1 deriv1
//		Smooth 3, deriv1
//		Differentiate deriv1
//		deriv1[0, (0.3 * length)] = 0
//		deriv1[(0.4 * length), (2 * length)] = 0
//		Duplicate/O view3 deriv2
//		Smooth 3, deriv2
//		Differentiate deriv2
//		Differentiate deriv2
//		WaveStats/Q deriv2
//		a = (View3(V_minloc - (2 * int)) + View3(V_minloc - int) + View3(V_minloc))/3
//		b = V_minloc
//		c = (View3(V_maxloc + .2) + View3(V_maxloc + int) + View3(V_maxloc + int))/3
//		d = V_maxloc
//		if(cmpstr(auto, "no")==0)
//			DoAlert 2, "Keep Mini? Cancel = Back"
//				if(V_flag==1)
//					miniloc[j] = $minis+"_indices"[i]
//					minipos[j] = mod($minis+"_indices"[i], block)
//					miniamp[j] = (c[0] - a[0])
//					Smooth 3, deriv1
//					CurveFit/Q/N gauss deriv1 /D
//					minirise[j] = W_coef[3]/0.56				//.0.56 is slope factor for HW to RT conversion
//					j+=1
//					if (($minis+"_indices"[i + 1] - $minis+"_indices"[i])>length) & ($minis+"_indices"[i] - $minis+"_indices"[i - 1])>length))
//						isolated_mini = $minis[($minis+"_indices"[i] - 11) + p]
//						average_mini+=isolated_mini
//						m+=1
//					endif
//					i+=1
//				else
//					if(V_flag==3)
//						i-=1
//						j-=1
//						m-=1
//					else
//						discarded_indices[k] = $minis+"_indices"[i]
//						k+=1
//						i+=1
//					endif
//				endif
//		else
//			PauseUpdate
//			miniloc[j] = $minis+"_indices"[i]
//			minipos[j] = mod($minis+"_indices"[i], block)
//			miniamp[j] = (c[0] - a[0])
//			Smooth 3, deriv1
//			CurveFit/Q/N gauss deriv1 /D
//			minirise[j] = W_coef[3]/0.56				//.0.56 is slope factor for HW to RT conversion
//			j+=1
//			if (($minis+"_indices"[i + 1] - $minis+"_indices"[i])>length) & ($minis+"_indices"[i] - $minis+"_indices"[i - 1])>length))
//				isolated_mini = $minis[($minis+"_indices"[i] - 11) + p]
//				average_mini+=isolated_mini
//				m+=1
//			endif
//			i+=1
//		endif
//	while(i < numpnts($minis+"_indices"))
//	ResumeUpdate
//	print "Of" , i, "minis, " , j, "were accepted and" , m, "were averaged"
//	average_mini/=m
//	remove view1, view2, view3, a, c
//	Append average_mini
//	Redimension/N=(j) miniloc, miniamp, minirise, minipos
//	Redimension/N=(k) discarded_indices
//
//	Duplicate/O miniloc miniint
//	do
//		miniint[l] = int * (miniloc[l + 1] - miniloc[l])
//		l+=1
//	while (l < j)
//
//	Duplicate/O discarded_indices $minis+"_discarded_indices"
//	KillWaves discarded_indices
//	Duplicate/O miniloc $minis+"_locations"
//	KillWaves miniloc
//	Duplicate/O minipos $minis+"_positions"
//	KillWaves minipos
//	Duplicate/O miniamp $minis+"_amplitudes", $minis+"_amp_hist"
//	KillWaves miniamp
//	Duplicate/O miniint $minis+"_intervals", $minis+"_int_hist"
//	KillWaves miniint
//	Duplicate/O minirise $minis+"_rise", $minis+"_rise_hist"
//	KillWaves minirise
//	Duplicate/O average_mini $minis+"_average"
//	Append $minis+"_average"
//	remove average_mini
//	KillWaves average_mini
//
//	Histogram/B={0, -2, 40} $minis+"_amplitudes", $minis+"_amp_hist"
//	Display $minis+"_amp_hist"
//	ModifyGraph width = 144, height=100
//	ModifyGraph mode=5
//	Histogram/B={0, 5, 200} $minis+"_intervals", $minis+"_int_hist"
//	Display $minis+"_int_hist"
//	ModifyGraph width=144, height=100
//	ModifyGraph mode=5
//	Histogram/B={0, .05, 20} $minis+"_rise", $minis+"_rise_hist"
//	Display $minis+"_rise_hist"
//	ModifyGraph width=144, height=100
//	ModifyGraph mode=5
//
//	KillWaves deriv1, deriv2, isolated_mini, a, b, c, d, view1, view2, view3, W_coef, fit_deriv1, W_sigma, W_ParamConfidenceInterval, Displaypeaks
//EndMacro
