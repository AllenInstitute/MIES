#pragma rtGlobals=1		// Use modern global access method.
Variable/g V_fitmaxiters=500

Menu "Macros"
	Submenu "Mini analysis"
		"IsolateMinis"
		"FindMinis"
		"AnalyzeMinis"
	End
End

Macro IsolateMinis(rnum,chan,sweepvect)
	String sweepvect="sweeps"
	Variable rnum=1,chan=2
	Prompt rnum, "Run number: "
	Prompt chan, "Channel number: "
	Prompt sweepvect, "Wave containing sweep numbers:"
	Silent 1

	string wn=""; wn=WName
	variable numtimes=numpnts($sweepvect),jump,i=0,blip,mult,trodes
	jump = $wn[2*rnum-1]*256												//Set pointer in file
	trodes=$wn[jump+6]													//Number of channels

	if(trodes<=0)															//Backwards compatibility
		trodes = 1
	endif

	Make /O/N=(256*$wn[jump+8]-3) dest; dest=0							//[jump+8] is blocks per run
	variable start=pcsr(a);variable length=(pcsr(b)-pcsr(a))
	make/o/n=(numtimes*length) minis; minis=0;	SetScale/P x 0,0.1,"",minis

	do
		dest= $wn[p+jump+256+(trodes*($sweepvect[i]-1)+chan-1)*256*$wn[jump+8]]
		minis[(length*i),length+(length*i)]=dest[start+p-length*i]
		i+=1
	while(i<numtimes)
	killwaves dest
End Macro

Macro FindMinis(wn,threshold,method,rise,decay)
	String wn="minis";variable threshold=10,method=1,rise=0.5,decay=1
	Prompt wn, "Wave containing minis:"
	Prompt threshold, "Detection threshold (try 10):"
	Prompt method, "Detecton method (0 for template, 1 for derivative):"
	Prompt rise, "Template rise time (ms):"
	Prompt decay, "Template decay tau (ms):"
	Silent 1;delayupdate

	variable duration=7*decay
	variable i=1, j=0
	duplicate/o $wn peaks,indices;indices=0;peaks=0

	if(method==1)
		MiniDeriv(wn,threshold,duration)
	else
		MiniTemplate(wn,rise,decay,duration,threshold)
		duplicate/o indices tempindices
		do		//takes out indices where minis overlap
			if(((indices[i+1]-indices[i])<duration/int) | ((indices[i]-indices[i-1])<duration/int))
				tempindices[i]=0
			else
				j+=1
			endif
			i+=1
		while(i<numpnts(indices))
		indices=tempindices;killwaves tempindices
		sort/r indices, indices
		redimension/n = (j) indices
		sort indices, indices
	endif

	duplicate/o indices $wn+"_indices";killwaves indices
	duplicate/o peaks $wn+"_peaks";killwaves peaks
	display $wn;ModifyGraph axisEnab(left)={0,0.75};append/r $wn+"_peaks";ModifyGraph axisEnab(right)={0.80,1};ModifyGraph nticks(right)=2
End Macro

Proc MiniDeriv(wn,threshold,duration)
	String wn="minis";variable threshold, duration
	Silent 1;delayupdate
	duplicate/o $wn deriv;differentiate deriv; smooth 10,deriv
	redimension/n=(peakfinder(deriv,peaks,indices,threshold)) indices
	killwaves deriv
EndMacro

Function PeakFinder(wn,peaks,indices,threshold)
	Wave wn;Wave peaks;Wave indices;Variable threshold
	Variable i=0,j=0

	do
		if((wn[i]<wn[i+1]) & (wn[i]<wn[i-2]) & (wn[i]<wn[i-1]) & (wn[i]<-threshold))
			peaks[i]=-10
			indices[j]=i
			j+=1
		endif
		i+=1
	while(i<numpnts(wn))
	return j

End

Proc MiniTemplate(minis,rise,decay,duration,threshold)
	String minis= "minis"
	variable rise,decay,duration,threshold
	Silent 1

	rise=1/rise;decay=1/decay;duration*=(1/int)			//creates template from alpha function
	make/o/n= (duration)/d template
	SetScale/P x 0,int,"",template
	template=1*(1-exp(-rise*X))*exp(-decay*x)

	SlidingTemplate($minis,template)
	redimension/n=(peakfinder(DC,peaks,indices,threshold)) indices
	killwaves DC
End Macro

Function SlidingTemplate(events,template)
	wave events;wave template

	Variable scl,offset,N,loops,sum_temp,sum_temp_sq,sum_data,std_err,SSE,d_c,i=0,j=0
	N=numpnts(template)																						//how many points of raw data to take at once?
	loops=numpnts(events)																						//how many times to shift template?
	duplicate/o events,DC;DC=0
	duplicate/o template fit_temp,data,temp_X_data,temp_sq,d_m_f_t_s										//make waves, constants for scaling
	temp_sq=template*template
	sum_temp_sq=sum(temp_sq,pnt2x(temp_sq,0),pnt2x(temp_sq,N))
	sum_temp=sum(template,pnt2x(template,0),pnt2x(template,N))

	do
		data=events[i+p]																						//takes a chunk of mini data
		smooth/b 5,data
		sum_data=sum(data,pnt2x(data,0),pnt2x(data,N))
		temp_X_data=template*data
		scl=(sum(temp_X_data,pnt2x(temp_X_data,0),pnt2x(temp_X_data,N))-sum_temp*sum_data/N)/(sum_temp_sq-sum_temp*sum_temp/N)
		offset=(sum_data-scl*sum_temp)/N
		fit_temp=template*scl+offset
		d_m_f_t_s=(data-fit_temp)*(data-fit_temp)													//starts to calculate detection criterion
		SSE=sum(d_m_f_t_s,0,N)
		std_err=sqrt(SSE/(N-1))
		d_c=scl/std_err
		DC[i-1]=(DC[i-2]+d_c)/2
		DC[i]=d_c
		i+=2
	while(i<loops)
	killwaves data,temp_X_data,fit_temp,d_m_f_t_s,template,temp_sq
End

Macro AnalyzeMinis(minis,auto,length,block)
	String minis= "minis";string auto= "no"
	Variable length=7,block=80
	Prompt minis,"Mini wave:"
	Prompt auto,"Accept all marked minis (yes or no)?"
	Prompt length, "Averaged mini length (ms):"
	Prompt block, "Block size (ms):"
	Silent 1

	length/=int
	Variable zeropeaks
	Wavestats/q $minis
	zeropeaks=(abs(V_avg)-10)// takes average of concatenated mini wave and subtracts 10 from it??????
	duplicate/o $minis+"_peaks" displaypeaks;displaypeaks-=(zeropeaks)//makes a wave equal to zero peaks variable
	Variable i=0,j=0,k=0,l=0,m=0,start=0,peak=0
	make/o/n=(length) isolated_mini,average_mini// makes waves who's length is the "length"/sampling int.
	SetScale/P x 0,int,"",isolated_mini,average_mini;isolated_mini=0;average_mini=0// don't understand what x means after set- scale
	make/o/n=(numpnts($minis+"_indices"))/d miniloc, miniamp, discarded_indices,minirise,minipos
	miniloc=0;miniamp=0;discarded_indices=0;minirise=0; minipos=0
	make/o/n=1 a,b,c,d;a=0;b=0;c=0;d=0
	display a vs b;append c vs d;ModifyGraph mode=3,marker=19,rgb=(0,0,0);ModifyGraph rgb(c)=(0,39168,19712)
	make/o/n=(10/int) view1,view2,view3
	append view1,view2,view3;ModifyGraph rgb(view3)=(0,0,65280)

	do
		duplicate/o/r=[$minis+"_indices"[i]-(0.3*length),$minis+"_indices"[i]+(1.7*length)]$minis view1
		duplicate/o/r=[$minis+"_indices"[i]-(0.3*length),$minis+"_indices"[i]+(1.7*length)]displaypeaks view2
		duplicate/o/r=[$minis+"_indices"[i]-(.5/int),$minis+"_indices"[i]+(.8/int)]$minis view3
		duplicate/o view1 deriv1;smooth 3,deriv1;differentiate deriv1;	deriv1[0,(0.3*length)]=0;deriv1[(0.4*length),(2*length)]=0
		duplicate/o view3 deriv2; smooth 3,deriv2; differentiate deriv2;differentiate deriv2
		WaveStats/q deriv2
		a=(View3(V_minloc-(2*int))+View3(V_minloc-int)+View3(V_minloc))/3; b=V_minloc
		c=(View3(V_maxloc+.2)+View3(V_maxloc+int)+View3(V_maxloc+int))/3; d=V_maxloc
		if(cmpstr(auto,"no")==0)
			DoAlert 2,"Keep Mini? Cancel = Back"
				if(V_flag==1)
					miniloc[j]=$minis+"_indices"[i];minipos[j]=mod($minis+"_indices"[i],block);miniamp[j]=(c[0]-a[0])
					smooth 3,deriv1
					CurveFit/q/n gauss deriv1 /D
					minirise[j]=W_coef[3]/0.56				//.0.56 is slope factor for HW to RT conversion
					j+=1
					if (($minis+"_indices"[i+1]-$minis+"_indices"[i])>length) & ($minis+"_indices"[i]-$minis+"_indices"[i-1])>length))
						isolated_mini=$minis[($minis+"_indices"[i]-11)+p]
						average_mini+=isolated_mini
						m+=1
					endif
					i+=1
				else
					if(V_flag==3)
						i-=1; j-=1; m-=1
					else
						discarded_indices[k]=$minis+"_indices"[i]
						k+=1; i+=1
					endif
				endif
		else
			PauseUpdate
			miniloc[j]=$minis+"_indices"[i];minipos[j]=mod($minis+"_indices"[i],block);miniamp[j]=(c[0]-a[0])
			smooth 3,deriv1
			CurveFit/q/n gauss deriv1 /D
			minirise[j]=W_coef[3]/0.56				//.0.56 is slope factor for HW to RT conversion
			j+=1
			if (($minis+"_indices"[i+1]-$minis+"_indices"[i])>length) & ($minis+"_indices"[i]-$minis+"_indices"[i-1])>length))
				isolated_mini=$minis[($minis+"_indices"[i]-11)+p]
				average_mini+=isolated_mini
				m+=1
			endif
			i+=1
		endif
	while(i<numpnts($minis+"_indices"))
	ResumeUpdate
	print "Of" ,i,"minis," ,j,"were accepted and" ,m,"were averaged"
	average_mini/=m
	remove view1,view2,view3,a,c; append average_mini
	redimension/n=(j) miniloc,miniamp,minirise,minipos;redimension/n=(k) discarded_indices

	duplicate/o miniloc miniint
	do
		miniint[l]=int*(miniloc[l+1]-miniloc[l])
		l+=1
	while (l<j)

	duplicate/o discarded_indices $minis+"_discarded_indices";killwaves discarded_indices
	duplicate/o miniloc $minis+"_locations";killwaves miniloc
	duplicate/o minipos $minis+"_positions";killwaves minipos
	duplicate/o miniamp $minis+"_amplitudes",$minis+"_amp_hist";killwaves miniamp
	duplicate/o miniint $minis+"_intervals",$minis+"_int_hist";killwaves miniint
	duplicate/o minirise $minis+"_rise",$minis+"_rise_hist";killwaves minirise
	duplicate/o average_mini $minis+"_average";append $minis+"_average";remove average_mini;killwaves average_mini

	Histogram/B={0,-2,40} $minis+"_amplitudes",$minis+"_amp_hist"
	display $minis+"_amp_hist";ModifyGraph width=144,height=100;ModifyGraph mode=5
	Histogram/B={0,5,200} $minis+"_intervals",$minis+"_int_hist"
	display $minis+"_int_hist";ModifyGraph width=144,height=100;ModifyGraph mode=5
	Histogram/B={0,.05,20} $minis+"_rise",$minis+"_rise_hist"
	display $minis+"_rise_hist";ModifyGraph width=144,height=100;ModifyGraph mode=5

	killwaves deriv1,deriv2,isolated_mini,a,b,c,d,view1,view2,view3,W_coef,fit_deriv1,W_sigma,W_ParamConfidenceInterval,displaypeaks
EndMacro
