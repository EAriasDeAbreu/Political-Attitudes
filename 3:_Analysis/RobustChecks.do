********************************************************************************
********************************************************************************
*Authors: 
*Coder: Edmundo Arias De Abreu
*Project: HEC Proyecto
*Data: Panel_v3.dta
*Stage: Robustness Checks

*Last checked: 29.03.2024

/*
********************************************************************************
*                                 Contents                                     *
********************************************************************************

Robustness checks of main results by doing the estimation via different 
estimators more robust to staggered treatment

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
use "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Final/Panel_v3.dta", clear

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
 *-> I have 14 leads & 14 lags !
 

	 ** Leads
	forvalues x = 1/14 {
		
		local j= 15-`x'
		ren evt`x' evt_l`j'
		cap label var evt_l`j' "-`j'" 
	}

	**  Lags
	forvalues x = 0/14 {
		
		local j= 15+`x'
		ren evt`j' evt_f`x'
		cap label var evt_f`x' "`x'"  
	}
	
	
** Base period to be ommited becuase of perfect multicollinearity:
replace evt_l1=0
 
 
 
 

********************           Voter Turnout                  ******************  

/// Define Total Votes
egen VotoTotal = rowtotal(PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO MOVIMIENTONUEVOLIBERALISMO OTROSPARTIDOOMOVIMIENTOS ALIANZANALPOPULARANAPO UNIONPATRIOTICAUP PARTIDOPATRIANUEVA VOTOSENBLANCO VOTOSNULOS)

/// Set as logarithm
gen l_VotoTotal = log(VotoTotal)

 
* 2. Nuevos estimadores 
*===============================================================================*

* 2.1. Callaway & Sant'Anna (2021)
*-------------------------------------------------------------------------------*


csdid l_VotoTotal, ivar(code) time(year) gvar(firsttreat) vce(cluster code)	reps(100)
csdid_estat event, 
csdid_plot, ylabel(, nogrid)	



*===============================================================================*

* Roth (2020) Honest DiD Test
*-------------------------------------------------------------------------------*
ssc install honestdid


qui csdid l_VotoTotal, ivar(code) time(year) gvar(firsttreat) vce(cluster code)	reps(100) pointwise		
csdid_estat event, window(-10 10) estore(csdid)
estimates restore csdid

local plotopts xtitle(Mbar) ytitle(95% Robust CI)
honestdid, pre(1/5) post(6/10) mvec(0.5(0.5)2) coefplot `plotopts' ylabel(, nogrid)











