*-----------------------------------------------------------------------------*
*     HEC: ES on the effect of violence on political participation			  *
*							Kelly Cadena :)									  *
*-----------------------------------------------------------------------------*
/* 	CONTENT:
	*) Linear projection of the population for all Colombian municipalities 
	(recoded) for the periods 1972-1984, based on the municipal population 
	projection data by DANE.
	
	PROCEDURE:
	*) Using the municipal data, a regression of population over years was run 
	for each municipality (using data for even years between 1984 and 2007). 
	This approximates the population growth rate (assuming it is constant). 
	This estimate was then used to project the population data up to 1972.	*/

clear all
cap log close
set more off, perm
cls

*******************************************************************************
* 						PART 1: POB DATABASE (1972-2007)					  *
*******************************************************************************
import excel "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Municipal_area_1985-2020.xls", firstrow clear

* 1. PANEL CONVERSION *
*---------------------*	
//DPMP (str) -> codmpio (num)
destring DPMP, gen(codmpio)

// Drop if cod is unknown
drop if codmpio == 0

//Keep yrs of interest
keep codmpio F H J L N Q T W AA
rename (F H J L N Q T W AA) (p1986 p1988 p1990 p1992 p1994 p1997 p2000 p2003 p2007)

//drop if no info on pob 1986 
drop if p1986 ==.
drop if p1986 ==0

global anos "1986 1988 1990 1992 1994 1997 2000 2003 2007"

// store var values in local
levelsof codmpio, local(list_cods)

local i = 1

// 9 yrs * 1037 mpios, 3 vars (cod yr pob)
mat v = J(9*1037, 3,.)

foreach mpio of local list_cods{
	foreach ano in $anos{
		mat v[`i',1] = `mpio'
		mat v[`i',2] = `ano'
		
		sum p`ano' if codmpio == `mpio'
		mat v[`i',3] = r(mean)
		local i= `i' + 1
	}
}

svmat v
drop p1988 p1990 p1988 p1992 p1994 p1997 p2000 p2003 p2007
rename (v1 v2 v3) (cod year pob)

// save panel database
save "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Work/pob8507.dta", replace

* 2. BETA LOCALS *
*----------------*
local j = 1
mat m = J(1037, 1, .)
foreach mpio of local list_cods{
	reg pob year if cod == `mpio'
	local m`mpio' = _b[year]
	local j = `j' + 1
}

* 3. PROYECTION 1972-1884 (EVEN YRS) *
*------------------------------------*
// 7 yrs * 1037 mpios, 3 vars (cod yr pob)
mat c = J(7*1037, 3, .)

// loop for matrix
local mult = 1
local j = 1
foreach mpio of local list_cods{
	forvalues a = 1972(2)1984{
		mat c[`j',1] = `mpio'
		mat c[`j', 2] = `a'
		mat c[`j',3] =  v[`mult',3] - (((1986-`a')/2)*`m`mpio'')
		di `m`mpio''
		local j = `j'+1
	}
	local mult = `mult'+9
}

drop _all

//matrix to database
svmat c

rename (c1 c2 c3) (cod year pob)

//append for whole dataset
append using "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Work/pob8507.dta"

sort cod year

//rename key for merge
rename year periodo

// drop obs that remain after conversion (mat -> dat)
drop if cod == .
drop codmpio p1986

// whole pob database
save "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Work/PanelMunicipios_Poblacion.dta", replace

*******************************************************************************
* 						PART 2: POB + VIOLENCE DATABASE*					  *
*******************************************************************************
use "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Panel_v3.dta", clear

//id (str) -> cod (num)
gen cod = real(id)

merge 1:1 cod periodo using "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Work/PanelMunicipios_Poblacion.dta"
	* 15,317 merged

// keep only observations that merged
drop if _merge !=3 
	* 2490 deleted
	
drop _merge

save "/Users/kellycadena/Documents/Programacion/Stata/HEC/Datos/Work/Panel_v4.dta", replace 
