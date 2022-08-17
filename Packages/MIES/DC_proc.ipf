#pragma TextEncoding = "UTF-8"
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

Function make_psc_folder()
	if (Datafolderexists("root:psc_folder:")==0)
		newdatafolder root:psc_folder
		
	endif

end

Function make_psc_analysis_wave(AD)
	variable AD
	DFREF saveDFR = GetDataFolderDFR()
	SetDataFolder root:psc_folder
	string wave_name="PSC_analysis_AD_"+num2str(AD)
	Make/o/n=(1,6) $wave_name
	wave psc_analysis_wave=$wave_name
	psc_analysis_wave=NaN
	SetDimLabel 1, 0, sweep, psc_analysis_wave
	SetDimLabel 1, 1, baseline, psc_analysis_wave
	SetDimLabel 1, 2, sigma, psc_analysis_wave
	SetDimLabel 1, 3, count, psc_analysis_wave
	SetDataFolder saveDFR
end

Function/WAVE filter_sweep(sweep, AD, high, low)
	variable sweep, AD, high, low
	
	DFREF saveDFR=GetDataFolderDFR()
	string sweep_df_name="X_"+num2str(sweep)
	string AD_name = "AD_"+num2str(AD)
	string filtered_name=AD_name+"_filter"
	DFREF sweep_df = root:MIES:HardwareDevices:ITC1600:Device0:Data:$sweep_df_name
	SetDataFolder sweep_df
	wave ad_wave=$AD_name
	variable samp=1000/deltax(ad_wave)
	duplicate/o ad_wave $filtered_name
	wave filter_wave=$filtered_name
	FilterIIR/HI=(high / samp)/LO=(low / samp)/DIM=(ROWS) filter_wave
	string f_name=nameofwave(filter_wave)
	//ModifyGraph rgb($f_name)=(0,0,0)
	//setdatafolder saveDFR
	return filter_wave
end


Function make_psc_kernel(tau1, tau2, amp, dt) //from Ken Burke's deconvolution cdoe
	variable tau1, tau2, amp, dt
	DFREF saveDFR=GetDataFolderDFR()
	//setdatafolder root:psc_folder
	variable tau1_p = tau1/dt
	variable tau2_p = tau2/dt
	variable kernel_window = tau2_p*4
	Variable amp_prime = (tau2_p/tau1_p)^(tau1_p/(tau1_p-tau2_p))		// normalization factor
	make/O/N=(kernel_window) time_index=p
	SetScale/P x, 0, dt, time_index
	Make/o/N=(kernel_window) psc_kernel = (amp/amp_prime)*(-exp(-time_index/(tau1_p))+exp(-time_index/(tau2_p)))
	FFT/OUT=1/PAD={262144}/DEST=kernel_fft psc_kernel
	SetScale/P x, 0, dt, psc_kernel
	setdatafolder saveDFR
end

	
function/WAVE i_trace_all_p(i_trace, [bin_start, bin_end, bin_width])
	wave i_trace
	variable bin_start, bin_end, bin_width
	variable dt=deltax(i_trace)
	variable start_ms=100
	variable end_ms=rightx(i_trace)
	duplicate/o/r=(start_ms, end_ms) i_trace, temp
	if (ParamIsDefault(bin_start))
		bin_start=floor(wavemin(temp))
	endif
	if (ParamIsDefault(bin_end))
		bin_end=ceil(wavemax(temp))
	endif
	if (ParamIsDefault(bin_width))
		bin_width=0.1
	endif
	variable n_bins=ceil((bin_end-bin_start)/bin_width)
	string hist_name=nameofwave(i_trace)+"_Hist"
	Histogram/B={bin_start,bin_width, n_bins}/DEST=$hist_name temp
	wave hist=$hist_name
	Killwaves temp
	return hist
end




function offset_trace(i_trace,[overwrite])
	wave i_trace
	variable overwrite
	if (ParamIsDefault(overwrite))
		overwrite=0
	endif
	wave hist=i_trace_all_p(i_trace)
	wavestats/q hist
	variable off=V_maxloc
	if (overwrite==0)
		string off_name=nameofWave(i_trace)+"_off"
		duplicate/o i_trace $off_name
		wave off_wave=$off_name
		off_wave-=off
	else
		i_trace-=off
	endif
	return off
end



function deconv_k(i_wave,kernel,[reuseKernel]) //reuse Kernel not working
	wave i_wave, kernel
	variable reuseKernel
	DFREF saveDFR=GetDataFolderDFR()
	FFT/OUT=1/DEST=output_fft i_wave
	
	if (ParamIsDefault(reuseKernel))
		reuseKernel=1
	endif
	if (reuseKernel!=1)
		SetDatafolder root:psc_folder:
		FFT/OUT=1/PAD={numpnts(i_wave)}/DEST=kernel_fft kernel
	endif
	wave kernel_fft_wv=root:psc_folder:kernel_fft
	SetDataFolder saveDFR
	make/o/n=(numpnts(output_fft))/D/C DeconvFFT
	DeconvFFT=output_fft/kernel_fft_wv
	ifft/dest=deconv_raw deconvfft
	SetScale/P x 0,deltax(i_wave),"ms", deconv_raw
	duplicate/o deconv_raw deconv_filter
	
	variable samp=1000/0.04
	filterfir/lo={0.002, .004, 101} deconv_filter
	Killwaves output_fft, deconvfft, deconv_raw
	//display i_wave
	//appendtograph/l=l_dc deconv_filter
	
end

function deconv_v2(i_wave) //reuse Kernel not working
	wave i_wave
	DFREF saveDFR=GetDataFolderDFR()
	variable n_pnts_source=numpnts(i_wave)
	variable n_pnts_target=262144
	variable start_p=n_pnts_source-n_pnts_target
	if(n_pnts_source>n_pnts_target)
		Duplicate/o/r=[start_p,n_pnts_source] i_wave temp
		FFT/OUT=1/DEST=output_fft temp
	else
		Duplicate/o i_wave temp
		FFT/OUT=1/DEST=output_fft/PAD={n_pnts_target} i_wave
	endif

	wave kernel_fft_wv=root:psc_folder:kernel_fft
	SetDataFolder saveDFR
	make/o/n=(numpnts(output_fft))/D/C DeconvFFT
	DeconvFFT=output_fft/kernel_fft_wv
	ifft/dest=deconv_raw deconvfft
	SetScale/P x leftx(temp),deltax(i_wave),"ms", deconv_raw
	duplicate/o deconv_raw deconv_filter
	
	variable samp=1000/0.04
	filterfir/lo={0.002, .004, 101} deconv_filter
	Killwaves output_fft, deconvfft, deconv_raw
	//display i_wave
	//appendtograph/l=l_dc deconv_filter
	
end

function plot_i_dc(AD)
	variable ad
	string i_name="AD_"+num2str(AD)+"_filter"
	string dc_name="deconv_AD_"+num2str(AD)
	wave i_wave=$i_name
	wave dc_wave=$dc_name
	wave peakx, peaky
	display/l=l_i i_wave
	appendtograph/l=l_dc dc_wave
	SetAxis/A=2 l_i
	SetAxis/A=2 l_dc
	ModifyGraph axisEnab(l_dc)={0,0.49}, axisEnab(l_i)={0.51,1}
	appendtograph/l=l_dc peaky vs peakx
	ModifyGraph mode(peakY)=3,marker(peakY)=19,rgb(peakY)=(0,0,0)
	
end

function ipsc_sweep(sweep, ad)
	variable sweep, ad
	string wave_name="PSC_analysis_AD_"+num2str(AD)
	wave output_wave=root:psc_folder:$wave_name
	wave filt=filter_sweep(sweep,ad,0,550)
	
	variable off=offset_trace(filt,overwrite=1)
	string sweep_name="sweep_"+num2str(sweep)
	variable dimIndex=FindDimLabel(output_wave, 0, sweep_name)
	if(dimIndex==-2)
		variable row_c=dimsize(output_wave,0)
		InsertPoints/M=0 row_c, 1, output_wave
		SetDimLabel 0, row_c, $sweep_name, output_wave
		dimIndex=row_c	
	endif
	output_wave[dimIndex][0]=sweep
	output_wave[dimIndex][1]=off
	
	//make_psc_kernel(1,15,-5,deltax(filt))
	wave psc_kernel = root:psc_folder:psc_kernel
	//deconv_k(filt,psc_kernel)
	deconv_v2(filt)
	wave deconv_filter
	string dc_name="deconv_AD_"+num2str(AD)
	
	dc_trace_all_p(deconv_filter)
	wave deconv_filter_hist
	//K0 = 0
	//CurveFit/H="1000"/q/G gauss deconv_filter_Hist /D
	dc_hist_fit(deconv_filter_hist)
	wave W_coef
	variable sd=W_coef[3]
	variable base=W_coef[2]
	output_wave[dimIndex][2]=sd 
	Duplicate/o deconv_filter $dc_name
	KillWaves deconv_filter
	
end


function ipsc_sweep_ts(sweep, ad)
	variable sweep, ad
	string wave_name="PSC_analysis_AD_"+num2str(AD)
	wave output_wave=root:psc_folder:$wave_name
	wave filt=filter_sweep(sweep,ad,0,550)
	
	variable off=offset_trace(filt,overwrite=1)
	string sweep_name="sweep_"+num2str(sweep)
	variable dimIndex=FindDimLabel(output_wave, 0, sweep_name)
	if(dimIndex==-2)
		variable row_c=dimsize(output_wave,0)
		InsertPoints/M=0 row_c, 1, output_wave
		SetDimLabel 0, row_c, $sweep_name, output_wave
		dimIndex=row_c	
	endif
	output_wave[dimIndex][0]=sweep
	output_wave[dimIndex][1]=off
	wave psc_kernel = root:psc_folder:psc_kernel
	//deconv_k(filt,psc_kernel)
	
	
end 
	
	

function/WAVE dc_trace_all_p(dc_trace, [bin_start, bin_end, bin_width])
	wave dc_trace
	variable bin_start, bin_end, bin_width
	variable dt=deltax(dc_trace)
	variable start_ms=100
	variable end_ms=rightx(dc_trace)-500
	duplicate/o/r=(start_ms, end_ms) dc_trace, temp
	statsquantiles/q temp
	variable q75=V_Q75
	if (ParamIsDefault(bin_start))
		bin_start=q75*-3
	endif
	if (ParamIsDefault(bin_end))
		bin_end=q75*3
	endif
	if (ParamIsDefault(bin_width))
		bin_width=0.0005
	endif
	variable n_bins=ceil((bin_end-bin_start)/bin_width)
	string hist_name=nameofwave(dc_trace)+"_Hist"
	Histogram/B={bin_start,bin_width, n_bins}/DEST=$hist_name temp
	wave hist=$hist_name
	Killwaves temp
	return hist
end

Function dc_hist_fit(dc_hist)
	wave dc_hist

	K0 = 0
	CurveFit/H="1000"/Q gauss dc_hist /D 
	

end


function make_events_wave(AD, count)
	variable AD, count
	//print count
	string events_wave_name="AD_"+num2str(AD)+"_events"
	Make/o/n=(count,11)/D $events_wave_name
	wave events_wave=$events_wave_name
	SetDimLabel 1, 0, dc_peak_time, events_wave
	SetDimLabel 1, 1, dc_amp, events_wave

	SetDimLabel 1, 2, i_peak, events_wave
	SetDimLabel 1, 3, i_peak_t, events_wave
	SetDimLabel 1, 4, pre_min, events_wave
	SetDimLabel 1, 5, pre_min_t, events_wave
	SetDimLabel 1, 6, i_amp, events_wave
	SetDimLabel 1, 7, isi, events_wave
	SetDimLabel 1, 8, tau_d, events_wave
	SetDimLabel 1, 9, tau_r, events_wave
	SetDimLabel 1, 10, sweep, events_wave
	events_wave=NaN
end


function analyze_crossings(wave crossings, wave i_wave, wave dc_wave, variable AD, variable sweep)

	string events_wave_name="AD_"+num2str(AD)+"_events"
	string sweep_name="sweep_"+num2str(sweep)
	wave events_wave=$events_wave_name
	string out_name="PSC_analysis_AD_"+num2str(AD)
	wave output_wave=root:psc_folder:$out_name
	variable i, i_time, o_time, j_time, i_amp, dc_amp, dc_peak_t, isi, i_peak, i_peak_t, pre_min, pre_min_t
	variable num_crossings=numpnts(crossings)
	for (i=0;i<(num_crossings-1);i+=1)
		
		i_time=crossings[i]
		j_time=crossings[i+1]
		wavestats/q/r=(i_time,j_time) dc_wave
		dc_amp=V_max
		dc_peak_t=V_maxloc
		wavestats/q/r=(dc_peak_t,j_time) i_wave
		i_peak=V_min
		i_peak_t=V_minloc
		events_wave[i][2]=i_peak
		events_wave[i][3]=i_peak_t
		if (i==0)
			isi=NaN
			o_time=NaN
			pre_min=NaN
			pre_min_t=NaN
		else
			o_time=events_wave[i-1][4] //previous event's time of peak
			isi=i_time-o_time
			wavestats/q/r=(o_time,i_peak_t) i_wave
			pre_min=V_max
			pre_min_t=V_maxloc
			wavestats/q/r=(pre_min_t-0.1, pre_min_t+0.1) i_wave
			pre_min=V_avg
		endif

		
		events_wave[i][3]=i_time
		events_wave[i][1]=dc_amp
		events_wave[i][0]=dc_peak_t
		events_wave[i][4]=pre_min
		events_wave[i][5]=pre_min_t
		events_wave[i][6]=i_peak-pre_min
		events_wave[i][7]=isi
	endfor
	wavestats/q/rmd=[][7] events_wave
	variable avg_amp=V_avg
	wavestats/q/rmd=[][8] events_wave
	variable avg_isi=V_avg
	variable dimIndex=FindDimLabel(output_wave, 0, sweep_name)
	//print sweep_name
	if(dimIndex==-2)
		print "uh oh"
		variable row_c=dimsize(output_wave,0)
		InsertPoints/M=0 row_c, 1, output_wave
		SetDimLabel 0, row_c, $sweep_name, output_wave
		dimIndex=row_c
		
	endif
	//output_wave[dimIndex][0]=sweep
	output_wave[dimIndex][4]=avg_amp
	output_wave[dimIndex][5]=avg_isi
	output_wave[dimIndex][3]=num_crossings
end


function caller(sweep )
	variable sweep
	variable avg_isi, avg_amp
	wave crossings, ad_2_filter, deconv_filter
	
	[avg_isi, avg_amp]=analyze_crossings(crossings, ad_2_filter, deconv_filter,2, sweep)
	print avg_isi, avg_amp

	
end

function process_sweeps(start, stop)
	variable start, stop
	variable i
	variable length=stop-start+1
	Make/o/N=(0,3) root:output
	for (i=start;i<=stop;i+=1)
		ipsc_sweep(i,2)
		wave deconv_filter, ad_2_filter
		Make/o crossings
		FindLevels/B=10/Dest=crossings/EDGE=1/m=2/r=(100,10000) deconv_filter, 0.0089123*3
		
		wave crossings
		
		make_events_wave(2, (numpnts(crossings)))
		analyze_crossings(crossings, ad_2_filter, deconv_filter, 2, i)
		
	
	
	endfor
	
end


function test_loop(start, stop, AD)
	variable start, stop, AD
	variable i
	for (i=start; i<=stop; i+=1)
		ipsc_sweep(i, AD)
	endfor
end

function find_crossings(thresh)
	variable thresh
	wave deconv_filter, ad_2_filter
	FindLevels/B=10/Dest=crossings/EDGE=1/m=2/r=(100,10000)/q deconv_filter, 0.028
end


function find_peaks(trace, threshold, [max_crossings, start, stop] )
	wave trace
	variable threshold, max_crossings, start, stop
	if (ParamIsDefault(max_crossings))
		max_crossings=2000
	endif
	if (ParamIsDefault(start))
		start=leftx(trace)
	endif
	if (ParamIsDefault(stop))
		stop=rightx(trace)
	endif
	Make/O/N=(max_crossings) peakX = NaN, peakY = NaN
	variable count=0
	do
		FindPeak/B=10/M=(threshold)/Q/R=(start,stop) trace 
		if (V_Flag!=0)
			break
		elseif(numtype(V_TrailingEdgeLoc) == 2)
			break
		endif
		peakX[count]=V_peakLoc
		peakY[count]=V_PeakVal
		count+=1
		start = V_TrailingEdgeLoc
	while (count < max_crossings)
	Extract/O peakX, peakX, (numtype(peakX) != 2)
	Extract/O peakY, peakY, (numtype(peakY) != 2)

end

function check_crossings()

	wave crossings, deconv_raw
	duplicate/o crossings checks
	checks=0
	variable low_t = 0.03
	variable i
	for (i=1;i<numpnts(crossings);i+=1)
		variable i_time=crossings[i]
		variable pre_time=crossings[i-1]
		wavestats/q/r=(pre_time,i_time) deconv_raw
		if (V_min>low_t)
			checks[i]=1
		endif
	endfor
end


function check_peaks()
	wave peakx, peaky, deconv_raw
	duplicate/o peakx peak_label
	peak_label=0
	variable low_t=0.15
	variable i
	for (i=1;i<numpnts(peakx); i+=1)
		variable i_time=peakx[i]
		variable pre_time=peakx[i-1]
		variable pre_peak=peaky[i-1]
		wavestats/q/r=(pre_time, i_time) deconv_raw
		if (V_min>pre_peak*0.67 || V_min>low_t)
			peak_label[i]=1
		endif
	endfor
end

function fit_decay(event_i)
	variable event_i
	wave ad_2_filter, deconv_filter, ad_2_events
	variable i_peak_t=AD_2_events[event_i][3]
	variable n_min_t=AD_2_events[event_i+1][5]
	
	CurveFit/Q exp_XOffset AD_2_filter(i_peak_t, n_min_t)
	wave W_coef

	variable tau=W_coef[2]
	return tau
end

function analyze_peaks(variable AD, wave dc_wave, wave i_wave, variable sweep)

	string events_wave_name="AD_"+num2str(AD)+"_events"
	string sweep_name="sweep_"+num2str(sweep)
	wave events_wave=$events_wave_name
	string output_wave_name="PSC_analysis_AD_"+num2str(AD)
	wave output_wave=root:psc_folder:$output_wave_name
	variable i, i_time, h_time, j_time, i_amp, dc_amp, dc_peak_t, isi, i_peak, i_peak_t, pre_min, pre_min_t
	wave peakX, peakY
	variable num_crossings=numpnts(peakX)
	for (i=0;i<(num_crossings-1);i+=1)
		
		i_time=peakX[i]
		j_time=peakX[i+1]
		
		dc_amp=peakY[i]
		wavestats/q/r=(i_time,i_time+2) i_wave
		i_peak=V_min
		i_peak_t=V_minloc
		events_wave[i][2]=i_peak
		events_wave[i][3]=i_peak_t
		if (i==0)
			isi=NaN
			h_time=NaN
			pre_min=NaN
			pre_min_t=NaN
		else
			h_time=peakX[i-1] //previous event's time of peak
			isi=i_time-h_time
			h_time=events_wave[i-1][3] //update previous events time to be time of i peak
			wavestats/q/r=(i_time-2,i_time) i_wave
			pre_min=V_max
			pre_min_t=V_maxloc
			wavestats/q/r=(pre_min_t-0.1, pre_min_t+0.1) i_wave
			pre_min=V_avg
		endif

		
		events_wave[i][0]=i_time
		events_wave[i][1]=dc_amp
	
		events_wave[i][4]=pre_min
		events_wave[i][5]=pre_min_t
		events_wave[i][6]=i_peak-pre_min
		events_wave[i][7]=isi
		events_wave[i][10]=sweep
	
	endfor
	//for (i=2; i<(num_crossings-1); i+=1)
		//variable tau=fit_decay(i)
		//events_wave[i][8]=tau
	//endfor
	wavestats/q/rmd=[][6] events_wave
	variable avg_amp=V_avg
	wavestats/q/rmd=[][7] events_wave
	variable avg_isi=V_avg
	variable dimIndex=FindDimLabel(output_wave, 0, sweep_name)
	//print sweep_name
	if(dimIndex==-2)
		print "uh oh"
		variable row_c=dimsize(output_wave,0)
		InsertPoints/M=0 row_c, 1, output_wave
		SetDimLabel 0, row_c, $sweep_name, output_wave
		dimIndex=row_c
		
	endif
	//output_wave[dimIndex][0]=sweep
	output_wave[dimIndex][4]=avg_amp
	output_wave[dimIndex][5]=avg_isi
	output_wave[dimIndex][3]=num_crossings
end

function test_loop_2(start, stop, AD, thresh)
	variable start, stop, AD, thresh
	variable i
	for (i=start;i<=stop;i+=1)
		string sweep_df_name="X_"+num2str(i)
		//print sweep_df_name
		DFREF sweep_df = root:MIES:HardwareDevices:ITC1600:Device0:Data:$sweep_df_name
		SetDataFolder sweep_df
		string i_name="AD_"+num2str(AD)+"_filter"
		string dc_name="deconv_AD_"+num2str(AD)
		wave i_filter=$i_name
		
		wave deconv_filter=$dc_name
		variable stop_search=rightx(deconv_filter)
		find_crossings(thresh)
		find_peaks(deconv_filter, thresh, start=100, stop=stop_search)
		wave peakx
		make_events_wave(AD, (numpnts(peakx)))
		WAVE crossings
		analyze_crossings(crossings, i_filter, deconv_filter, AD, i)
		wave deconv_filter
		analyze_peaks(AD, deconv_filter, i_filter, i)
	endfor

end

function test_loop0(start, stop, AD)
	variable start, stop, AD
	variable i
	for (i=start; i<=stop; i+=1)
		ipsc_sweep_ts(i, AD)
	endfor
end

function plot_psc_a_wave(AD)
	variable AD
	string wave_name = "PSC_analysis_AD_"+num2str(AD)
	wave psc_a_wave=$wave_name
	display/l=lb psc_a_wave[][1] vs psc_a_wave[][0]
	appendtograph/l=ls psc_a_wave[][2] vs psc_a_wave[][0]
	appendtograph/l=lc psc_a_wave[][3] vs psc_a_wave[][0]
	Label lb "holding (pA)";DelayUpdate
	Label ls "sigma";DelayUpdate
	Label lc "events";DelayUpdate
	ModifyGraph axisEnab(lb)={0,0.31},axisEnab(ls)={0.33,0.64},axisEnab(lc)={0.67,1}
	SetAxis lb *,0
	SetAxis ls 0,*
	SetAxis lc 0,*
end

function pull_event(trace, i, events_wave)
	wave trace, events_wave
	variable i

	variable pre_window=-5
	variable post_window=50
	DFREF saveDFR = GetDataFolderDFR()
	string event_name="event_"+num2str(i)
	variable i_time=events_wave[i][0]
	variable isi=events_wave[i][7]
	if (isi<10)
		return 0
	endif
	variable isi_next=events_wave[i+1][7]
	if (isi_next<30)
		return 0
	endif
	SetDataFolder event_folder
	variable d_start=x2pnt(trace, (i_time+pre_window))
	variable d_end= x2pnt(trace, (i_time+post_window))
	duplicate/o/r=[d_start,d_end] trace $event_name
	wave event=$event_name
	SetScale/P x pre_window,deltax(event),"ms", event
	variable off=mean(event,pre_window,-1)
	event-=off
	appendtograph event
	setdatafolder saveDFR

end

Function make_event_folder()
	if (Datafolderexists("event_folder")==0)
		newdatafolder event_folder
		
	endif

end

function append_events_in_sweep(start, stop, AD)
	variable start, stop, AD
	string e_wave_name="AD_"+num2str(AD)+"_events"
	string AD_wave_name="AD_"+num2str(AD)
	wave events_wave=$e_wave_name
	variable i
	wave ad_wave=$ad_wave_name
	make_event_folder()
	for (i=start; i<=stop; i+=1)
		pull_event(AD_wave,i, events_wave)
	endfor
end

function plot_events_sweeps(start, stop, AD)
	variable start, stop, AD
	variable i
	display
	for (i=start; i<=stop; i+=1)
		string sweep_df_name="X_"+num2str(i)
		DFREF sweep_df = root:MIES:HardwareDevices:ITC1600:Device0:Data:$sweep_df_name
		SetDataFolder sweep_df
		string e_name="AD_"+num2str(AD)+"_events"
		wave e_wave=$e_name
		variable e_stop=dimsize(e_wave,0)-2
		append_events_in_sweep(0,e_stop,AD)
	
	endfor
	

end

function concat_events(start, stop, AD)
	variable start, stop, AD
	string e_wave_name="AD_"+num2str(AD)+"_events"
	SetDataFolder root:psc_folder
	Make/o/n=(1,11)/D $e_wave_name
	wave event_mast=$e_wave_name
	event_mast=Nan
	variable i
	for (i=start;i<=stop;i+=1)
		string sweep_df_name="X_"+num2str(i)
		DFREF sweep_df = root:MIES:HardwareDevices:ITC1600:Device0:Data:$sweep_df_name
		SetDataFolder sweep_df
		wave event_i=$e_wave_name
		Concatenate/NP=0 {event_i}, event_mast
	endfor
	
	
	
end