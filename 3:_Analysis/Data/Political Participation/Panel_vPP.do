********************************************************************************
********************************************************************************
*Authors: 
*Coder: Edmundo Arias De Abreu
*Project: HEC Proyecto
*Data: PanelMunicipios_Violencia.xlsx + PanelParticipacionMun.xlsx
*Stage: Data Construction

*Last checked: 16.04.2024

/*
********************************************************************************
*                                 Contents                                     *
********************************************************************************

This do will seek to merge both panels as of now constructed: Violencia and 
Votos. 

Inputs:
	- PanelMunicipios_Violencia.xlsx
	- PanelMunicipios_Votos.xlsx
	
Output:
	- Panel1.dta

	

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
*                        Import and Clean 'Votes Panel'                        *
*                                                                              *
********************************************************************************
import excel "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Votos/PanelParticipacionMun.xlsx", sheet("Sheet1") firstrow clear

// clean up
drop A
sort id periodo

/// Dropping id-year dups: necessary for 1:1 merge
bysort id periodo: keep if _n == 1



/// Save in CleanedData
save "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/CleanedData/Participation.dta", replace


********************************************************************************
*                                                                              *
*                        Import and Clean 'Violence Panel'                        *
*                                                                              *
********************************************************************************

/// Merge with Violence data
merge 1:1 id periodo using "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/CleanedData/ViolencePanel Extended.dta"
drop _merge


order id mun dep periodo Violencia V_Guerrilla V_Estado V_Paramilitar V_Desmovilizados V_GruposArma PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO PARTIDOCAMBIORADICALCOLOMBIAN PARTIDOCOLOMBIADEMOCRATICA censoe_mujeres censoe_hombres censoe_total

sort id periodo

// Keep only the specified voting years
keep if periodo == 2003 | periodo == 2007 | periodo == 2011 | periodo == 2015 | ///
periodo == 2019

// Save panel
save "/Users/edmundoarias/Documents/Uniandes/2024-10/HEC/Political-Attitudes/2:_ProcessedData/MergedData/Final/Political Participation/Panel_vPP.dta", replace
