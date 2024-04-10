cd "C:/Users/juanj/OneDrive - Universidad de los Andes/Andes/#6 - Semester/Historia Económica de Colombia/Political-Attitudes-main/"

********************************************************************************
********************************************************************************
*Authors: 
*Coder: Edmundo Arias De Abreu - Juan Jose Gutierrez
*Project: HEC Proyecto
*Data: Panel_v3.dta
*Stage: Regression Analysis

*Last checked: 2024.04.08

/*
********************************************************************************
*                                 Contents                                     *
********************************************************************************

This do generates a series of descriptive statistics tables and graphs for the
dataset Panel_v3, to primarily outline the contents of the variables ""

Inputs:
	- Panel_v3.dta
	
Output:
	- FALTA – see 4/_Output -> Results

	

********************************************************************************
*/


*Prepare the terminal
clear
**cls

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


/// Import dataset
use "2__ProcessedData\MergedData\Final\Panel_v3.dta", clear

label var Violencia "Ataque violento"
label var PARTIDOLIBERALCOLOMBIANO "Votos partido liberal"
label var PARTIDOCONSERVADORCOLOMBIANO "Votos partido liberal"
label var MOVIMIENTONUEVOLIBERALISMO "Votos partido nuevo liberalismo"
label var OTROSPARTIDOOMOVIMIENTOS "Votos otros partidos/movimientos"
label var ALIANZANALPOPULARANAPO "Votos partido alianza popular ANAPO"
label var UNIONPATRIOTICAUP "Votos union patriotica"
label var PARTIDOPATRIANUEVA "Votos partido patria nueva"
label var VOTOSENBLANCO "Votos en blanco"

sum Violencia
asdoc sum Violencia PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO    ///
MOVIMIENTONUEVOLIBERALISMO OTROSPARTIDOOMOVIMIENTOS ALIANZANALPOPULARANAPO   ///
UNIONPATRIOTICAUP PARTIDOPATRIANUEVA VOTOSENBLANCO,                          ///
title(Estadisticas descriptivas para base Panel_V3) label replace save(4__Output/Tables/Sum Variables.doc)


/*convertir 0 en NA e interpretar como, en un año dado, entre los municipios que
experimentaron violencia, estos tuvieron en promedio ## ataques violentos.*/


gen Violenciasans0 = Violencia 

replace Violenciasans0 = . if Violencia == 0

bysort periodo: sum Violenciasans0

bysort periodo: asdoc sum Violenciasans0  , title(Estadisticas descriptivas de Violencia por anno para municipios con violencia ) label replace save(4__Output/Tables/Sum Violencia por año.doc)


**------------------------------- GRAFICAS -----------------------------------*
// Gen Sequental year variable for simplicity
egen year = group(periodo)

/// Declare panel
destring id, gen(code)
xtset code year

collapse (sum) Violencia PARTIDOLIBERALCOLOMBIANO PARTIDOCONSERVADORCOLOMBIANO ///
 MOVIMIENTONUEVOLIBERALISMO OTROSPARTIDOOMOVIMIENTOS ALIANZANALPOPULARANAPO    ///
 UNIONPATRIOTICAUP PARTIDOPATRIANUEVA VOTOSENBLANCO, by(year)
 
twoway tsline Violencia, ///
xtitle("group(Periodo)") ///
ytitle("Número de ataques violentos") ///
title("Número de ataques violentos en el tiempo", size(4)) ///
legend(pos(6)) ///
 /*note("{bf:Gráfico }")*/ ///
name(graph_1, replace) 
graph export "4__Output/Figures/Grafica Violencia.png", as (png) replace


