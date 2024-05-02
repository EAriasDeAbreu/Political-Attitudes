********************************************************************************
********************************************************************************
*Authors: 
*Coder: Edmundo Arias De Abreu
*Project: HEC Proyecto
*Data: PanelMunicipios_Violencia.xlsx + PanelMunicipios_Votos.xlsx
*Stage: Regression Analysis

*Last checked: 29.03.2024

/*
********************************************************************************
*                                 Contents                                     *
********************************************************************************

This do outlines a procedure for estimating Two-Way Fixed Effects (TWFE) 
regressions using the Panel_v1.dta dataset. Our primary objective is to quantify
 the causal impact of violent attacks on the political attitudes of Colombian 
 municipalities. This analysis will be reflected through changes in the voting 
 patterns observed in local 'Concejo' elections, specifically examining the 
 number of votes cast for each political party within these municipalities.

Inputs:
	- Panel_v3.dta
	
Output:
	- TWFE Estimation Graphs – see 4/_Output -> Results

	

********************************************************************************
*/

*Prepare the terminal
clear
cls

*Set graph format
set scheme s2mono
grstyle init
grstyle set plain, horizontal box
grstyle color background white
grstyle set color navy gs5 gs10
grstyle set color gs10: major_grid
grstyle set lp solid dash dot 
grstyle set symbol circle triangle diamond X
grstyle set legend 6, nobox
graph set window fontface "Garamond"


********************************************************************************
*                                                                              *
*                           Event Study Design Set Up                          *
*                                                                              *
********************************************************************************

/// Import dataset
use "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Final/Political Participation/Panel_vPP.dta", clear

// Gen Sequental year variable for simplicity
egen year = group(periodo)

/// Declare panel
destring id, gen(code)
xtset code year

/// Violence indicator
gen D_violencia = (Violencia != 0)


sort id year
/// Gen First-Treat variable: year of first 'violencia'
by id: egen firsttreat = min(cond(D_violencia == 1, year, .))
tab firsttreat

/// Create dummy treatment variable specific on date
gen Dit = (year >= firsttreat & firsttreat!=0)
tab Dit

/// Create relative periods (t-t_0)
gen rel_time=year-firsttreat

tab rel_time, gen(evt) // dummies for each period
 *-> I have 4 leads & 4 lags !
 

	 ** Leads
	forvalues x = 1/4 {
		
		local j= 5-`x'
		ren evt`x' evt_l`j'
		cap label var evt_l`j' "-`j'" 
	}

	**  Lags
	forvalues x = 0/4 {
		
		local j= 5+`x'
		ren evt`j' evt_f`x'
		cap label var evt_f`x' "`x'"  
	}
	
	
** Base period to be ommited becuase of perfect multicollinearity:
replace evt_l1=0
 
 

********************************************************************************
*                                                                              *
*                                Regressions                                   *
*                                                                              *
********************************************************************************


********************      Participacion Política              ******************  

egen VotoTotal = rowtotal(PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO PARTIDOCAMBIORADICALCOLOMBIAN PARTIDOCOLOMBIADEMOCRATICA censoe_mujeres censoe_hombres censoe_total PARTIDOSOCIALDEUNIDADNACIONA PARTIDOCENTRODEMOCRATICOMAN PARTIDOCOLOMBIAHUMANAYUNION PARTIDOALIANZAVERDE POLODEMOCRATICOINDEPENDIENTE VOTOSENBLANCO)

gen PartAll = VotoTotal / censoe_total

gen L_PartAll = log(PartAll)
/// Event Study – TWFE
reghdfe L_PartAll evt_l4 evt_l3 evt_l2 evt_l1 evt_f0 evt_f1 evt_f2, abs(id year) vce(cluster id)
	estimates store coefs_i 

reghdfe L_PartAll Dit, abs(id year) vce(cluster id)

*) Graph
coefplot coefs_i, omitted														///
	vertical 																	///
	label drop(_cons)															///
	yline(0, lpattern(dash) lwidth(*0.5))   							 		///
	ytitle("Participación Política")                          ///
	xtitle("Años Relativo al Ataque", size(medsmall))			 		        ///
	xlabel(, labsize(small) nogextend labc(black)) 	 				 			///
	ylabel(,nogrid nogextend labc(black) format(%9.2f)) 				 		///
	msymbol(O) 														 			///
	mlcolor(black) 													 			///
	mfcolor(black) 													 			///
	msize(vsmall) 													 			///
	levels(95) 														 			///
	xline(4, lpattern(dash) lwidth(*0.5))										///
	ciopts(lcol(black) recast(rcap) lwidth(*0.8)) 					 			///
	plotregion(lcolor(black) fcolor(white))  							 		///
	graphregion(lcolor(black) fcolor(white))  						 			///
	yscale(lc(black)) 												 			///
	xscale(lc(black)) 												 			///
	name(TWFE2_1, replace)
 graph export "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/4:_Output/Results/Extended/TWFE_pp.pdf", replace
*--> Effect! Violence on municipalities decreases Conservative votes
 
 
 

*************   Participacion Política vs Violencia del Estado    **************  

/// Import dataset
use "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Final/Political Participation/Panel_vPP.dta", clear

// Gen Sequental year variable for simplicity
egen year = group(periodo)

/// Declare panel
destring id, gen(code)
xtset code year

/// Violence indicator
gen D_violencia = (V_GruposArma != 0)


sort id year
/// Gen First-Treat variable: year of first 'violencia'
by id: egen firsttreat = min(cond(D_violencia == 1, year, .))
tab firsttreat

/// Create dummy treatment variable specific on date
gen Dit = (year >= firsttreat & firsttreat!=0)
tab Dit

/// Create relative periods (t-t_0)
gen rel_time=year-firsttreat

tab rel_time, gen(evt) // dummies for each period
 *-> I have 4 leads & 4 lags !
 

	 ** Leads
	forvalues x = 1/4 {
		
		local j= 5-`x'
		ren evt`x' evt_l`j'
		cap label var evt_l`j' "-`j'" 
	}

	**  Lags
	forvalues x = 0/4 {
		
		local j= 5+`x'
		ren evt`j' evt_f`x'
		cap label var evt_f`x' "`x'"  
	}
	
	
** Base period to be ommited becuase of perfect multicollinearity:
replace evt_l1=0



*------ Estimation
egen VotoTotal = rowtotal(PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO PARTIDOCAMBIORADICALCOLOMBIAN PARTIDOCOLOMBIADEMOCRATICA censoe_mujeres censoe_hombres censoe_total PARTIDOSOCIALDEUNIDADNACIONA PARTIDOCENTRODEMOCRATICOMAN PARTIDOCOLOMBIAHUMANAYUNION PARTIDOALIANZAVERDE POLODEMOCRATICOINDEPENDIENTE VOTOSENBLANCO)

gen PartAll = VotoTotal / censoe_total


/// Event Study – TWFE
reghdfe PartAll evt_l4 evt_l3 evt_l2 evt_l1 evt_f0 evt_f1 evt_f2, abs(id year) vce(cluster id)
	estimates store coefs_i 

*) Graph
coefplot coefs_i, omitted														///
	vertical 																	///
	label drop(_cons)															///
	yline(0, lpattern(dash) lwidth(*0.5))   							 		///
	ytitle("Votos Totales sobre Censo Total")                          ///
	xtitle("Años Relativo al Ataque (por el Estado)", size(medsmall))			 		        ///
	xlabel(, labsize(small) nogextend labc(black)) 	 				 			///
	ylabel(,nogrid nogextend labc(black) format(%9.2f)) 				 		///
	msymbol(O) 														 			///
	mlcolor(black) 													 			///
	mfcolor(black) 													 			///
	msize(vsmall) 													 			///
	levels(95) 														 			///
	xline(4, lpattern(dash) lwidth(*0.5))										///
	ciopts(lcol(black) recast(rcap) lwidth(*0.8)) 					 			///
	plotregion(lcolor(black) fcolor(white))  							 		///
	graphregion(lcolor(black) fcolor(white))  						 			///
	yscale(lc(black)) 												 			///
	xscale(lc(black)) 												 			///
	name(TWFE2_1, replace)
 graph export "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/4:_Output/Results/Extended/TWFE_pp_Otros.pdf", replace
*--> Effect! Violence on municipalities decreases Conservative votes
 
 
 
********************           Voting Ratios                  ******************  

gen R_ConsTotal = PARTIDOCONSERVADORCOLOMBIANO / VotoTotal
gen R_LibTotal = PARTIDOLIBERALCOLOMBIANO / VotoTotal
gen R_BlancoTotal = VOTOSENBLANCO / VotoTotal
gen R_ConsLib = PARTIDOCONSERVADORCOLOMBIANO / PARTIDOLIBERALCOLOMBIANO

gen L_ConsTotal = log(R_ConsTotal)
gen L_LibTotal = log(R_LibTotal)
gen L_BlancoTotal = log(R_BlancoTotal)
gen L_ConsLib = log(R_ConsLib)


// Event Study – TWFE
reghdfe L_ConsLib evt_l14 evt_l13 evt_l12 evt_l11 evt_l10 evt_l9 evt_l8 evt_l7 evt_l6 evt_l5 evt_l4 evt_l3 evt_l2 evt_l1 evt_f0 evt_f1 evt_f2 evt_f3 evt_f4 evt_f5 evt_f6 evt_f7 evt_f8 evt_f9 evt_f10 evt_f11 evt_f12 evt_f13 evt_f14, abs(id year) vce(cluster id)
	estimates store coefs_i 

*) Graph
coefplot coefs_i, omitted														///
	vertical 																	///
	label drop(_cons)															///
	yline(0, lpattern(dash) lwidth(*0.5))   							 		///
	ytitle("Votos Totales (log)")                              ///
	xtitle("Años Relativo al Ataque", size(medsmall))			 		        ///
	xlabel(, labsize(small) nogextend labc(black)) 	 				 			///
	ylabel(,nogrid nogextend labc(black) format(%9.2f)) 				 		///
	msymbol(O) 														 			///
	mlcolor(black) 													 			///
	mfcolor(black) 													 			///
	msize(vsmall) 													 			///
	levels(95) 														 			///
	xline(13, lpattern(dash) lwidth(*0.5))										///
	ciopts(lcol(black) recast(rcap) lwidth(*0.8)) 					 			///
	plotregion(lcolor(black) fcolor(white))  							 		///
	graphregion(lcolor(black) fcolor(white))  						 			///
	yscale(lc(black)) 												 			///
	xscale(lc(black)) 												 			///
	name(TWFE3, replace)



**# BIG TAKEAWAY #3:
/*
Violent attacks on municipalities decreases votes towards conservatives and 
total number of votes, while voting patterns to other parties remain relatively
the same.

*/


reghdfe 
 




