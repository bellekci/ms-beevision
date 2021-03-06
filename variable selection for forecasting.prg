''''''''''''''''''''''*******************************************************************************************************'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''This code is for selection of variables according to their pseudo out-of-sample forecasting performances measured by RMSE.'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''Written by Selen Andic, selen.baser@tcmb.gov.tr, on 13/6/2014.*********************************'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''''''''''''''''''''Please cite Andic, S. and F. Ogunc. 2015. Variable selection for inflation:a pseudo out-of-sample approach. Central Bank of Turkey Working Paper No:15/06'''''''''''''''''''''''
''''''''''''''''''''''*******************************************************************************************************'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''HOW TO RUN THE CODE'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''this code works with quarterly or monthly data.
'''make sure start date of your wf matches the date of your first "y" observation.
'''make sure you do not have any missing values between the first and last observation of your y and x data.
'''paste your data in its stationary form(s) into a E-views wf.
'''name the dependent variable as "y". 
'''for "x" variables, Quick> Empty Group. paste your "x"  variables without names and close the group without saving. Eviews will name your" x" series as "ser*".
'''declare your foracasting framework, section 2.
'''run the code quietly for faster results. 


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''OUTPUTS AFTER THE CODE IS RUN''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''performances according to criteria "results1" (RMSE-sum) are presented in "Table Results1" (refer to section 8 for details).
'''performances according to criteria "results2" (outperform ratio etc.) are presented in "Table Results2" (refer to section 8 for details).
'''results of "nbrbest" (for instance 5) variables are presented in "Table Results of Best"
'''RRMSEs of the best "nbrbest" variables according to "results1"  and "results2", and recursive forecasts of these variables are shown graphically (refer to section 11 for details).



'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''1) ESTIMATION FRAMEWORK'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''y: stationary dependent variable, x: stationary independent variable, L: lags, e:error term.
'''general form of the model: y=c+b1*L(y)+b2*L(x)+e.
'''lags of y and x variables are determined according to the Schwarz criteria.

close @objects
delete  bench* mod* num* gro* na* obs*   f_* hor* s_* sf* v_* rmse* m_* var* result* sele* sil* minlag* outper* rks* lastobs* stepsi* nbr* ini* best* graph* recur* g_* x*


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''2) FORECASTING FRAMEWORK'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''determine the maximum number of lags for y;
!maxlagy					=4
'''determine the maximum number of lags for x;
!maxlagx					=4
'''determine the minimum number lags for x;
!minlagx					=1
'''determine the maximum number of observations in the first recursive estimation;
scalar numobs			=31
''determine the forecast horizon;
scalar horizon			=4
'''determine the recursive estimation step size;
scalar stepsize			=1
'''determine the percent that the variable outperforms the benchmark at least by;
scalar outperformby	=10
'''determine the number of best variables to be graphed;
scalar nbrbest			=5

''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''3) INITIAL CONDITIONS''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
smpl @all
'''A) group series to determine the number of variables.
group groupx ser*
stomna(groupx, x)
scalar numser=@columns(x)

'''B) defining the last date of each X series for recursive estimations.
'''B.1) define a sample range starting from the first observation till some arbitrary date to determine the missing values at the beginning of the sample.
smpl @all
matrix(numser,1) m_na_ser
for !h=1 to numser
	%b = @str(!h, "i02")
     scalar lastobs_{%b}=@ilast(ser{%b})
	smpl @first @first+lastobs_{%b}-1
     scalar na_ser{%b}=@nas(ser{%b})
	m_na_ser(!h,1)=na_ser{%b}
next

vector v_maxnbr_na=@cmax(m_na_ser)

if !maxlagy>!maxlagx then
	scalar initial=!maxlagy+v_maxnbr_na(1)
else
	scalar initial=!maxlagx+v_maxnbr_na(1)
endif

'''''B.2) for each X series, according to the number of observations, define the last date that the estimation can be run.
smpl @all
for !h=1 to numser
	%b = @str(!h, "i02")	
	scalar obsser{%b}=na_ser{%b}+@obs(ser{%b})
		if @obs(y)>obsser{%b}+!minlagx then
			scalar obsser{%b}=obsser{%b}+!minlagx
		else
			scalar obsser{%b}= @obs(y)
		endif
next


''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''4) BENCHMARK ESTIMATION'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
smpl @all
!bestlagy		=0
!schwarz 		= 99999999
for !j=numobs to @obs(y)
	smpl @first+initial @first+!j-1
	for !i=1 to !maxlagy
		equation benchmark_!j_!i.ls(cov=hac) y c y(-!i to -1)
	next
	for !i=1 to !maxlagy		
		if benchmark_!j_!i.@schwarz<!schwarz then
				!bestlagy=!i
				!schwarz=benchmark_!j_!i.@schwarz
		endif
	next
	copy benchmark_!j_!bestlagy benchmark_!j
	!bestlagy=0
	!schwarz= 99999999
next


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''5) MODEL ESTIMATION'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
smpl @all
	!bestlagx=0
	!bestlagy=0
	!schwarz= 99999999
for !h=1 to numser
	%b = @str(!h, "i02")		
	for !j=numobs to obsser{%b}
		smpl @first+initial @first+!j-1
		for !i=1 to !maxlagy
			for !k=!minlagx to !maxlagx
				equation mod_{%b}_!j_!i_!k.ls(cov=hac) y c y(-!i to -1) ser{%b}(-!k to -!minlagx)
				if mod_{%b}_!j_!i_!k.@schwarz<!schwarz then
					!bestlagx=!k
					!schwarz=mod_{%b}_!j_!i_!k.@schwarz
				endif			
			next
			!schwarz=999999999				
			mod_{%b}_!j_!i_!bestlagx.ls(cov=hac) y c y(-!i to -1) ser{%b}(-!bestlagx to -!minlagx)
			copy 	mod_{%b}_!j_!i_!bestlagx mod_{%b}_!j_!i
		next
		!schwarz=99999999
		for !i=1 to !maxlagy
			if mod_{%b}_!j_!i.@schwarz<!schwarz then
				!bestlagy=!i
				!schwarz=mod_{%b}_!j_!i.@schwarz
			endif
		next
		copy  mod_{%b}_!j_!bestlagy mod_{%b}_!j 
		!schwarz=99999999
		!bestlagx=0
		!bestlagy=0
	next
	!schwarz=99999999
	!bestlagx=0
	!bestlagy=0
next	


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''6) FORECAST'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''A) benchmark forecasts.
smpl @all
for !j=numobs to @obs(y)-horizon step stepsize
	smpl @first+!j @first+!j-1+horizon
	benchmark_!j.forecast f_benchmark_!j
	vector v_f_benchmark_!j=@convert(f_benchmark_!j)
	mtos( v_f_benchmark_!j,s_f_benchmark_!j)
next

'''B) model forecasts.
smpl @all
for !h=1 to numser 
	%b = @str(!h, "i02")	
	for !j=numobs to obsser{%b}-horizon step stepsize
		smpl @first+!j @first+!j-1+horizon 
		mod_{%b}_!j.forecast f_mod_{%b}_!j
		vector v_f_mod_{%b}_!j=@convert(f_mod_{%b}_!j)
		mtos(v_f_mod_{%b}_!j,s_f_mod_{%b}_!j)
	next
next


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''7) CALCULATING RMSE'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''''A) rmse of benchmark.
smpl @all
for !j=numobs to @obs(y)-horizon step stepsize
	series rmse_benchmark_!j = @sqrt(@mean((s_f_benchmark_!j-y)^2))
	matrix(@obs(y)-horizon-numobs+1,1)  m_rmse_benchmark
	!row=!j-numobs+1
	m_rmse_benchmark(!row)= rmse_benchmark_!j(1)
next

''''''B) rmse of models.
matrix(numser,1) m_obsser
for !h=1 to numser
	%b = @str(!h, "i02")	
	m_obsser(!h)=obsser{%b}
	for !j=numobs to obsser{%b}-horizon step stepsize
		series rmse_{%b}_!j=@sqrt(@mean((s_f_mod_{%b}_!j-y)^2))
		matrix(obsser{%b}-horizon-numobs+1,1)  m_rmse_{%b}
		matrix(obsser{%b}-horizon-numobs+1,1)  m_zero_{%b}
		!row=!j-numobs+1
		m_rmse_{%b}(!row)= rmse_{%b}_!j(1)
	next
next

''''''C) calculating sum of RMSEs according to the shortest variable.
vector v_obsser_min=@cmin(m_obsser)
matrix(v_obsser_min(1)-horizon-numobs+1,1) m_rmse_obsminbench
for !h=1 to numser
	%b = @str(!h, "i02")
	matrix(v_obsser_min(1)-horizon-numobs+1,1) m_rmse_obsmin_{%b}
	for !row=1 to v_obsser_min(1)-horizon-numobs+1
		m_rmse_obsmin_{%b}(!row)=m_rmse_{%b}(!row)
		m_rmse_obsminbench(!row)=m_rmse_benchmark(!row)
	next
	vector v_rmsesum_obsmin_{%b}=@csum(m_rmse_obsmin_{%b})
	vector v_rmsesum_obsminbench=@csum(m_rmse_obsminbench)
next


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''8) SORTING VARIABLES'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
'''A) results1; sorting variables according to their sum of RMSEs over recursive estimations relative to sum of RMSEs of benchmark.
matrix(numser,2) m_rrmsesum_inter
matrix(numser,2) m_rrmsesum_sorted

for !a=1 to 2
	table(numser+1,6) results{!a}
next
results1(1,1)="variable number"
results1(1,2)="sum of RMSEs over recursive estimations according to the shortest variable relative to benchmark"
for !h=1 to numser
	%b = @str(!h, "i02")	
	m_rrmsesum_inter(!h,1)={%b}
	m_rrmsesum_inter(!h,2)=v_rmsesum_obsmin_{%b}(1)/v_rmsesum_obsminbench(1)
next

vector rks_rrmsesum=@ranks(@columnextract(m_rrmsesum_inter,2),"a","i")
m_rrmsesum_sorted=@capplyranks(m_rrmsesum_inter,rks_rrmsesum)
for !h=1 to numser
	for !column=1 to 2
	results1(!h+1,!column)=m_rrmsesum_sorted(!h,!column)
	next
next

'''B) results2, step1 ;  finding how many times each variables beats the benchmark, beats it by at least "outperformby" percent, the number of times it produces the best and worst forecasts.
'''B.1) finding how many times a variable beats benchmark and beats it by at least "outperformby".
matrix(numser,6) m_marcellino_t4
for !h=1 to numser
	%b = @str(!h, "i02")	
	m_marcellino_t4(!h,1)={%b}
	for !nbrinter=1 to 2
		matrix(obsser{%b}-horizon-numobs+1,1) m_bench_inter{!nbrinter}_{%b}
	next
	for !row=1 to obsser{%b}-horizon-numobs+1
		m_bench_inter1_{%b}(!row)=m_rmse_benchmark(!row)
		m_bench_inter2_{%b}(!row)=m_rmse_benchmark(!row)*(1-(outperformby)/100)
	next
	for !out=1 to 2
		matrix m_outperform{!out}_{%b}=@elt(m_rmse_{%b},m_bench_inter{!out}_{%b})
		vector v_outperform{!out}_{%b}=@csum(m_outperform{!out}_{%b})
	next
	m_marcellino_t4(!h,2)=@csum(@egt(m_rmse_{%b},m_zero_{%b}))(1)
	m_marcellino_t4(!h,3)=v_outperform1_{%b}(1)
	m_marcellino_t4(!h,4)=v_outperform2_{%b}(1)
next

''''B.2)finding how many times each variable produces best and worst forecasts.
matrix(@obs(y)-horizon-numobs+1,numser) m_na_inter=na
for !h=1 to numser
	%b = @str(!h, "i02")		
	matrix(obsser{%b}-horizon-numobs+1,1)  m_rrmse_{%b}
	for !row= 1 to obsser{%b}-horizon-numobs+1
		if m_bench_inter1_{%b}(!row)<>0 then 
			m_rrmse_{%b}(!row)=m_rmse_{%b}(!row)/m_bench_inter1_{%b}(!row)
		else
			m_rrmse_{%b}(!row)=0
		endif
	next
	matplace(m_na_inter,m_rrmse_{%b},1,!h)
next
matrix m_na_inter_trans=@transpose(m_na_inter)
for !row=1 to @obs(y)-horizon-numobs+1
	vector(@obs(y)-horizon-numobs+1) v_varnbr_minrrmse
	vector(@obs(y)-horizon-numobs+1) v_varnbr_maxrrmse
	vector v_intermin_!row=@cmin(@columnextract(m_na_inter_trans,!row))
	vector v_intermax_!row=@cmax(@columnextract(m_na_inter_trans,!row))
	vector v_intercimin_!row=@cimin(@columnextract(m_na_inter_trans,!row))
	vector v_intercimax_!row=@cimax(@columnextract(m_na_inter_trans,!row))
	if v_intermin_!row(1)<>0 then
		v_varnbr_minrrmse(!row)=v_intercimin_!row(1)
		v_varnbr_maxrrmse(!row)=v_intercimax_!row(1)	
	else
		v_varnbr_minrrmse(!row)=0
		v_varnbr_maxrrmse(!row)=0
	endif
next

'''B.3)matching the number of best and worst forecasts to variables.
mtos(v_varnbr_minrrmse, s_varnbr_minrrmse)
mtos(v_varnbr_maxrrmse, s_varnbr_maxrrmse)
series s_inter_min=@obsby(s_varnbr_minrrmse,s_varnbr_minrrmse)
series s_inter_max=@obsby(s_varnbr_maxrrmse,s_varnbr_maxrrmse)
matrix(@obs(y)-horizon-numobs+1,2) m_inter_min
matrix(@obs(y)-horizon-numobs+1,2) m_inter_max
for !row=1 to @obs(y)-horizon-numobs+1
	m_inter_min(!row,1)=v_varnbr_minrrmse(!row)
	m_inter_min(!row,2)=s_inter_min(!row)
	m_inter_max(!row,1)=v_varnbr_maxrrmse(!row)
	m_inter_max(!row,2)=s_inter_max(!row)
next

for !h=1 to numser
	for !row=1 to @obs(y)-horizon-numobs+1
		if m_marcellino_t4(!h,1)=m_inter_min(!row,1) then 
			m_marcellino_t4(!h,5)=m_inter_min(!row,2) 
		endif
		if m_marcellino_t4(!h,1)=m_inter_max(!row,1) then 
			m_marcellino_t4(!h,6)=m_inter_max(!row,2) 
		endif		
	next
next

'''B.4) carrying the matrix results to results2;
results2(1,1)="variable number"
results2(1,2)="number of recursive estimations"
results2(1,3)="nbr of times the variable outperforms benchmark"
results2(1,4)= "nbr of times the variable outperforms benchmark by at least " + @str(outperformby) + "%"
results2(1,5)= "nbr of times the variable produces best forecasts"
results2(1,6)= "nbr of times the variable produces worst forecasts"
for !h= 1 to numser
	for !column=1 to 6
		results2(!h+1,!column)=m_marcellino_t4(!h,!column)
	next
next


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''9) GENERAL RESULTS'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
for !a=1 to 2
	show results!a
next


'''''''''''''''''''''''''''''''''''''''''''''''''''10) RESULTS OF BEST VARIABLES''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''''the best "nbrbest" variables are summarized in a table (results_of_best). In second column of the table, variables are chosen acc. to their outperform benchmark/nbr of recur. est. ratios in results2.
delete m_su* rks_m_su* results_of*
matrix(numser,2) m_sub_marcellino
for !row=1 to numser
	m_sub_marcellino(!row,1)=m_marcellino_t4(!row,1)
	m_sub_marcellino(!row,2)=m_marcellino_t4(!row,3)/m_marcellino_t4(!row,2)
next

matrix(numser,2) m_sub_mar_sorted 
vector rks_m_sub_mar=@ranks(@columnextract(m_sub_marcellino,2),"d","i")
m_sub_mar_sorted=@capplyranks(m_sub_marcellino,rks_m_sub_mar)

table(nbrbest+1,3) results_of_best
results_of_best(1,1)="variable number of top " + @str(nbrbest) + " acc. to results1"
results_of_best(1,2)="variable number of top " + @str(nbrbest) + " acc. to results2"
results_of_best(1,3)="outperform over estimation ratio acc. to results2"
for !row=2 to nbrbest+1
	results_of_best(!row,1)=results1(!row,1)
	results_of_best(!row,2)=m_sub_mar_sorted(!row-1,1)
	results_of_best(!row,3)=m_sub_mar_sorted(!row-1,2)
next
show results_of_best


'''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''11) GRAPHS''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''''
''A) dropping zeros, if they exist, from the m_rrmse* matrices.
for !h=1 to numser
	%b = @str(!h, "i02")	
	scalar recur_nbr_{%b}=m_marcellino_t4(!h,2)
	matrix(recur_nbr_{%b},1) results_rrmse_{%b}
	!row1=1	
	!row2=1
	while !row1<=recur_nbr_{%b} and !row2<=obsser{%b}
		results_rrmse_{%b}(!row1)=m_rrmse_{%b}(!row2)
		!row1=!row1+1
		!row2=!row2+stepsize
	wend
next

''B) graphing the best "nbrbest" variable according to "results1"  and "results2". be careful, if a variable appears both in top "nbrbest" of "results1" and "results2", it will be graphed twice.
for !a=1 to nbrbest
	scalar best_var_results1_!a=m_rrmsesum_sorted(!a,1)
	scalar best_var_results2_!a=m_sub_mar_sorted(!a,1)
	for !b=1 to 2
		if best_var_results{!b}_!a<10 then
			string best= "0"+ @str(best_var_results{!b}_!a)
			freeze(g_rrmse_bestres!b_{best}) results_rrmse_{best}.line
			group best_res!b_{best} f_mod_{best}* y
			freeze(g_forecast_bestres!b_{best}) best_res!b_{best}.line
				if nbrbest<=5 then
					show g_rrmse_bestres!b_{best}
					show g_forecast_bestres!b_{best}	
				endif
		else
			string best=@str(best_var_results{!b}_!a)
			freeze(g_rrmse_bestres!b_{best}) results_rrmse_{best}.line
			group best_res!b_{best} f_mod_{best}* y
			freeze(g_forecast_bestres!b_{best}) best_res!b_{best}.line
				if nbrbest<=5 then			
					show g_rrmse_bestres!b_{best}
					show g_forecast_bestres!b_{best}
				endif
		endif
	next
next


''''***END OF CODE***'''


