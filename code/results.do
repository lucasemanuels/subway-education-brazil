* ssc install csdid
* ssc install drdid
* ssc install outreg2
* ssc install event_plot
* ssc install grc1leg 
* ssc install coefplot
********************************
* RESULTS
********************************

clear all
use "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\base_estimacoes_metro_SSA_final.dta", clear

*
order co_entidade ano ano_inauguracao grupo_tratado1 grupo_tratado2 grupo_tratado3 treat min_dist
*

** fixing sample **
{
replace ano_inauguracao = 0 if ano_inauguracao==2023
replace grupo_tratado1=0 if grupo_tratado3==0
replace grupo_tratado1=0 if inrange(min_dist,4,6)
keep if grupo_tratado1!=.
*drop if linha=="Linha 2 (Planejada)" | linha=="Linha 1 (Planejada)"
drop if linha=="Linha 1 (Planejada)"
replace ano_inauguracao=0 if grupo_tratado1==0
tab ano_inauguracao
tab linha
g ano_inauguracao2 = ano_inauguracao
replace ano_inauguracao2 = . if ano_inauguracao2==0

keep if min_dist<6
}
**********************
	
* Control vars *
{
ta dependad, g(depend)
*ta estacao, g(station)
egen station = group(estacao)
ta in_agua_filtrada, g(filtrada)
ta co_municipio, g(mun)
*egen bairros = group(bairro)
*ta bairro, g(county)

gen Esc_publica=1 if tp_dependencia==1 | tp_dependencia==2 |  tp_dependencia==3
replace Esc_publica=0 if tp_dependencia==4

egen t=group(ano)
bys co_entidade: egen min_year=min(ano)	if in_agua_filtrada!=.

	foreach v of varlist depend* filtrada* mun* in_esgoto_rede_publica Esc_publica { //county* {
		bys co_entidade: g t_`v' = `v'*t
	}
}
drop t_dependad
*
  
* Outcomes *
{
foreach v of varlist qt_mat_fund_ai qt_mat_fund_af qt_mat_med {
	if "`v'"=="qt_mat_fund_ai" loc w "taxa_abandono_ef_anos_iniciais"
	if "`v'"=="qt_mat_fund_af" loc w "taxa_abandono_ef_anos_finais"
	if "`v'"=="qt_mat_med" loc w "taxa_abandono_em"
	
	g ln_`v' = ln(`v') 
	g p_`v' = `v'/qt_mat_bas if `w'!=.
}

foreach v of varlist qt_doc_bas qt_doc_fund qt_doc_med {
	g p_`v' = `v'/qt_doc_bas if `v'>0
}

foreach v of varlist qt_tur_fund qt_tur_med {
	bys co_entidade: egen min_`v' = max(`v') 
}

g comp_fund = qt_mat_fund/qt_tur_fund if min_qt_tur_fund>0
g comp_medio = qt_mat_med/qt_tur_med if min_qt_tur_med>0
g turmas_fund = qt_tur_fund/qt_tur_bas if min_qt_tur_fund>0
g turmas_medio = qt_tur_med/qt_tur_bas if min_qt_tur_med>0
 
g st_fund = qt_mat_fund/qt_doc_fund if min_qt_tur_fund>0
g st_medio = qt_mat_med/qt_doc_med if min_qt_tur_med>0

g choice = mora_fora_ssa/qt_mat_bas if qt_mat_bas!=.
g choice_ai = mora_fora_ssa_ai/qt_mat_fund_ai if qt_mat_fund_ai!=.
g choice_af = mora_fora_ssa_af/qt_mat_fund_af if qt_mat_fund_af!=.
g choice_em = mora_fora_ssa_medio/qt_mat_med if qt_mat_med!=.

g transp_ai = transporte_publico_ai/qt_mat_fund_ai
g transp_af = transporte_publico_af/qt_mat_fund_af
g transp_em = transporte_publico_medio/qt_mat_med

replace mora_fora_ssa_ai = . if taxa_abandono_ef_anos_iniciais==.
replace mora_fora_ssa_af = . if taxa_abandono_ef_anos_finais==. 
replace mora_fora_ssa_medio = . if taxa_abandono_em==.

gsort co_entidade -inse_classificacao
bys co_entidade: replace inse_classificacao=inse_classificacao[1]
so co_entidade ano
egen grupo = group(inse_classificacao)
recode grupo (4/5 = 1) (1 2 3 = 2), generate(inse)

}
*
g event = ano-ano_inauguracao

***********************	
so co_entidade ano
***********************



***************************************************************	
**************************** TABLES ****************************
***************************************************************

***************************************************************
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\Results\Tables"	
***************************************************************
	
	
** TAB 1 - Descriptive **	
* baseline means
sum taxa_abandono_ef_anos_iniciais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_iniciais!=.)
sum taxa_abandono_ef_anos_iniciais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_iniciais!=.) & Esc_publica==1
sum taxa_abandono_ef_anos_iniciais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_iniciais!=.) & Esc_publica==0	
sum taxa_abandono_ef_anos_finais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_finais!=.)
sum taxa_abandono_ef_anos_finais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_finais!=.) & Esc_publica==1
sum taxa_abandono_ef_anos_finais if (event==-1 & min_dist<=2 & taxa_abandono_ef_anos_finais!=.) & Esc_publica==0	
sum taxa_abandono_em if (event==-1 & min_dist<=2 & taxa_abandono_em!=.)
sum taxa_abandono_em if (event==-1 & min_dist<=2 & taxa_abandono_em!=.) & Esc_publica==1
sum taxa_abandono_em if (event==-1 & min_dist<=2 & taxa_abandono_em!=.) & Esc_publica==0		


	
** TAB 2 - Main results **	
qui foreach y of varlist taxa_abandono_ef_anos_iniciais  {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist  taxa_abandono_ef_anos_finais taxa_abandono_em {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*drop t_depend* t_filtrada* t_mun* t_in_esgoto_rede_publica
qui foreach y of varlist taxa_abandono_ef_anos_iniciais  {
	csdid `y' t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2pub.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist  taxa_abandono_ef_anos_finais taxa_abandono_em {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2pub.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*drop t_depend* t_filtrada* t_mun* t_in_esgoto_rede_publica
qui foreach y of varlist taxa_abandono_ef_anos_iniciais  {
	csdid `y' t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2priv.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist  taxa_abandono_ef_anos_finais taxa_abandono_em {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
	csdid `y'  if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 
		estimates store cs2
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) 	
		estimates store cs3
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica  if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple) notyet
		estimates store cs4
		outreg2 [cs1 cs2 cs3 cs4] using "tab2priv.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*drop t_depend* t_filtrada* t_mun* t_in_esgoto_rede_publica


** TAB 3 - Performance **	
qui foreach y of varlist taxa_aprovacao_ef_anos_iniciais   {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist taxa_reprovacao_ef_anos_iniciais tdi_ef_anos_iniciais taxa_aprovacao_ef_anos_finais taxa_reprovacao_ef_anos_finais tdi_ef_anos_finais taxa_aprovacao_em taxa_reprovacao_em tdi_em {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Public schools
qui foreach y of varlist taxa_aprovacao_ef_anos_iniciais   {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3_p.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist taxa_reprovacao_ef_anos_iniciais tdi_ef_anos_iniciais taxa_aprovacao_ef_anos_finais taxa_reprovacao_ef_anos_finais tdi_ef_anos_finais taxa_aprovacao_em taxa_reprovacao_em tdi_em {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3_p.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Private schools
qui foreach y of varlist taxa_aprovacao_ef_anos_iniciais   {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3priv.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist taxa_reprovacao_ef_anos_iniciais tdi_ef_anos_iniciais taxa_aprovacao_ef_anos_finais taxa_reprovacao_ef_anos_finais tdi_ef_anos_finais taxa_aprovacao_em taxa_reprovacao_em tdi_em {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab3priv.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*

** TAB 4 - Composition **	
qui foreach y of varlist p_qt_mat_fund_ai    {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 , ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist p_qt_mat_fund_af p_qt_mat_med comp_fund comp_medio turmas_fund turmas_medio mora_fora_ssa_ai mora_fora_ssa_af mora_fora_ssa_medio  {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 , ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Public schools
qui foreach y of varlist p_qt_mat_fund_ai {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_p.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist p_qt_mat_fund_af p_qt_mat_med comp_fund comp_medio turmas_fund turmas_medio mora_fora_ssa_ai mora_fora_ssa_af mora_fora_ssa_medio  {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_p.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Private schools
qui foreach y of varlist p_qt_mat_fund_ai    {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4priv.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist p_qt_mat_fund_af p_qt_mat_med comp_fund comp_medio turmas_fund turmas_medio mora_fora_ssa_ai mora_fora_ssa_af mora_fora_ssa_medio {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4priv.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
	
 	
** TAB 4 - Teacher Characteristics **
qui foreach y of varlist st_fund    {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 , ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist st_medio dsu_ef dsu_em p_qt_doc_fund p_qt_doc_med  {
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 , ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Public schools
qui foreach y of varlist st_fund {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2_p.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist st_medio dsu_ef dsu_em p_qt_doc_fund p_qt_doc_med  {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2_p.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*
* Private schools
qui foreach y of varlist st_fund    {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2priv.tex",  tex replace  dec(2)  nocons stats(coef se pval aster)
}
qui foreach y of varlist st_medio dsu_ef dsu_em p_qt_doc_fund p_qt_doc_med {
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_pub==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(simple)
		estimates store cs1
		outreg2 [cs1] using "tab4_2priv.tex",  tex append  dec(2)  nocons stats(coef se pval aster)
}
*


	

***************************************************************
 cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\Results\Figures\"	
***************************************************************

** Figure 1 - MAIN Event study **
qui foreach y of varlist taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais taxa_abandono_em {
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc w "Elementary (early grd.)"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc w "Elementary (upper grd.)"
	if "`y'"=="taxa_abandono_em" loc w "High school"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc t "-2.5(1)2.5"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc t "-2.5(1)2.5"
	if "`y'"=="taxa_abandono_em" loc t "-4.5(1.5)4.5"
	
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs1)	

	csdid `y' if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	matrix cs2 = e(b)'
	matrix cs_v2 = J(56,1,.)	

	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	matrix cs3 = e(b)'
	matrix cs_v3 = J(56,1,.)

	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<4, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) notyet
	matrix cs4 = e(b)'	
	matrix cs_v4 = J(56,1,.)			

		
event_plot cs1 cs2#cs_v2 cs3#cs_v3 cs4#cs_v4, ///
	stub_lag(Tp# Tp# Tp# Tp#) stub_lead( Tm# Tm# Tm# Tm#) plottype(connected) ciplottype(rarea) alpha(.1) ///
	 perturb(-0.2(0.1)0.2) trimlead(5) trimlag(6) noautolegend  ///
	graph_opt(title(`w', size(medlarge)) ///
		xtitle("Years of exposure") ytitle("Estimate", xoffset(2)) xlabel( -5 "-6" -4 "-5" -3 "-4" -2 "-3" -1 "-2" 0(1)5) ylabel(0 `t') xsize(9) ///
		 legend(pos(6) col(2) rows(1) size(3) order(1 "Main" 5 "No controls" 7 "Alternate FE" 9 "Not-yet treated") region(style(none)) ) ///
	xline(-.5, lcolor(black) lpattern(dash)) yline(0, lcolor(red) lpattern(dot)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(circle) msize(medlarge) color(blue) lpattern(solid)) lag_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(blue%20 blue%20)) lead_opt1(msymbol(circle) msize(medlarge) color(blue)) ///
	lead_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(blue%20 blue%20)) ///					
	lag_opt2(msymbol(square) msize(small) color(gs10) lpattern(shortdash)) lag_ci_opt2(color(gs10 gs10) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs10 gs10)) lead_opt2(msymbol(square) msize(small) color(gs10) lpattern(shortdash)) ///
	lead_ci_opt2(color(gs10 gs10) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs10 gs10)) ///	
	lag_opt3(msymbol(diamond) msize(small) color(gs6) lpattern(shortdash)) lag_ci_opt3(color(gs6 gs6) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs6 gs6)) lead_opt3(msymbol(diamond) msize(small) color(gs6) lpattern(shortdash)) ///
	lead_ci_opt3(color(gs6 gs6) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs6 gs6)) ///	
	lag_opt4(msymbol(triangle) msize(small) color(gs8) lpattern(shortdash)) lag_ci_opt4(color(gs8 gs8) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs8 gs8)) lead_opt4(msymbol(triangle) msize(small) color(gs8) lpattern(shortdash)) ///
	lead_ci_opt4(color(gs8 gs8) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs8 gs8)) 
	
	graph save `y'.gph, replace	
}

grc1leg taxa_abandono_ef_anos_iniciais.gph taxa_abandono_ef_anos_finais.gph taxa_abandono_em.gph, r(1) graphregion(color(white)) iscale(1)  name(fig1, replace) 
	graph display fig1, ysize(5) xsize(11)
	graph export fig1.pdf, replace as(pdf) 	
	
	
	

** Figure 1 APPENDIX - Robustness Event study using eventually treated**
qui foreach y of varlist taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais taxa_abandono_em {
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc w "Elementary (early grd.)"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc w "Elementary (upper grd.)"
	if "`y'"=="taxa_abandono_em" loc w "High school"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc t "-2.5(1)2.5"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc t "-2.5(1)2.5"
	if "`y'"=="taxa_abandono_em" loc t "-4.5(1.5)4.5"
	
	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<2, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs1)	

	csdid `y' if min_dist<2, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	matrix cs2 = e(b)'
	matrix cs_v2 = J(56,1,.)	

	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<2, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	matrix cs3 = e(b)'
	matrix cs_v3 = J(56,1,.)

	csdid `y' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica t_mun* if min_dist<2, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) notyet
	matrix cs4 = e(b)'	
	matrix cs_v4 = J(56,1,.)			

		
event_plot cs1 cs2#cs_v2 cs3#cs_v3 cs4#cs_v4, ///
	stub_lag(Tp# Tp# Tp# Tp#) stub_lead( Tm# Tm# Tm# Tm#) plottype(connected) ciplottype(rarea) alpha(.1) ///
	 perturb(-0.2(0.1)0.2) trimlead(5) trimlag(6) noautolegend  ///
	graph_opt(title(`w', size(medlarge)) ///
		xtitle("Years of exposure") ytitle("Estimate", xoffset(2)) xlabel( -5 "-6" -4 "-5" -3 "-4" -2 "-3" -1 "-2" 0(1)5) ylabel(0 `t') xsize(9) ///
		 legend(pos(6) col(2) rows(1) size(3) order(1 "Main" 5 "No controls" 7 "Alternate FE" 9 "Not-yet treated") region(style(none)) ) ///
	xline(-.5, lcolor(black) lpattern(dash)) yline(0, lcolor(red) lpattern(dot)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(circle) msize(medlarge) color(blue) lpattern(solid)) lag_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(blue%20 blue%20)) lead_opt1(msymbol(circle) msize(medlarge) color(blue)) ///
	lead_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(blue%20 blue%20)) ///					
	lag_opt2(msymbol(square) msize(small) color(gs10) lpattern(shortdash)) lag_ci_opt2(color(gs10 gs10) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs10 gs10)) lead_opt2(msymbol(square) msize(small) color(gs10) lpattern(shortdash)) ///
	lead_ci_opt2(color(gs10 gs10) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs10 gs10)) ///	
	lag_opt3(msymbol(diamond) msize(small) color(gs6) lpattern(shortdash)) lag_ci_opt3(color(gs6 gs6) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs6 gs6)) lead_opt3(msymbol(diamond) msize(small) color(gs6) lpattern(shortdash)) ///
	lead_ci_opt3(color(gs6 gs6) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs6 gs6)) ///	
	lag_opt4(msymbol(triangle) msize(small) color(gs8) lpattern(shortdash)) lag_ci_opt4(color(gs8 gs8) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(gs8 gs8)) lead_opt4(msymbol(triangle) msize(small) color(gs8) lpattern(shortdash)) ///
	lead_ci_opt4(color(gs8 gs8) lpattern(dash dash) msymbol(point point) msize(zero zero) color(gs8 gs8)) 
	
	graph save `y'2.gph, replace	
}

grc1leg taxa_abandono_ef_anos_iniciais2.gph taxa_abandono_ef_anos_finais2.gph taxa_abandono_em2.gph, r(1) graphregion(color(white)) iscale(1)  name(fig12, replace) 
	graph display fig12, ysize(5) xsize(11)
	graph export fig12.pdf, replace as(pdf) 		
	
	
	
** Figure 2 - Heterogeneity - School type **	
qui foreach y of varlist taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais taxa_abandono_em {
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc w "Elementary (early grd.)"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc w "Elementary (upper grd.)"
	if "`y'"=="taxa_abandono_em" loc w "High school"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc t "-2(.5)2"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc t "-6(2)6"
	if "`y'"=="taxa_abandono_em" loc t "-5(2.5)5"
	
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs1)	

	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_publica==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs2)		

		
event_plot cs1 cs2, ///
	stub_lag(Tp# Tp# ) stub_lead( Tm# Tm# ) plottype(connected) ciplottype(rarea) alpha(.1) ///
	 perturb(-0.2(0.1)0.2) trimlead(5) trimlag(6) noautolegend  ///
	graph_opt(title(`w', size(medlarge)) ///
		xtitle("Years of exposure") ytitle("Estimate", xoffset(2)) xlabel(-5 "-6" -4 "-5" -3 "-4" -2 "-3" -1 "-2" 0(1)5) ylabel(`t') xsize(9) ///
		 legend(pos(6) col(2) rows(1) size(3) order(1 "Public schools" 5 "Private schools") region(style(none)) ) ///
	xline(-.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dot)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(circle) msize(small) color(blue) lpattern(solid)) lag_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(blue%20 blue%20)) lead_opt1(msymbol(circle) msize(small) color(blue)) ///
	lead_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(blue%20 blue%20)) ///					
	lag_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) lag_ci_opt2(color(red%20 red%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(red%20 red%20)) lead_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) ///
	lead_ci_opt2(color(red%20 red%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(red%20 red%20)) 
	
	
	graph save school_`y'.gph, replace	
}

grc1leg school_taxa_abandono_ef_anos_iniciais.gph school_taxa_abandono_ef_anos_finais.gph school_taxa_abandono_em.gph, c(3) graphregion(color(white)) iscale(1) name(fig2, replace) 
	graph display fig2, ysize(5) xsize(12)
	graph export fig2.pdf, replace as(pdf) 		
	
	
	
* heterogeneidade do ideb_af
foreach v of varlist ideb_af ideb_ai ideb_em {
	bys co_entidade: egen `v'_pre2013 = mean(`v') if ano<=2013 & `v'!=.
	egen m_`v'=median(`v') if ano<=2013 & `v'!=.
	g above_`v' = `v'_pre2013 > m_`v' if ano<=2013 & `v'!=.
	
	gsort co_entidade above_`v'
	bys co_entidade: replace above_`v' = above_`v'[1]
	drop m_`v' `v'_pre2013
}


** Figure 3 - Heterogeneity - School quality and background **	
qui foreach y of varlist taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais  {
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc w "Elementary (early grd.)"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc w "Elementary (upper grd.)"
	if "`y'"=="taxa_abandono_em" loc w "High school"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc t "-4(2)4"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc t "-6(2)6"
	if "`y'"=="taxa_abandono_em" loc t "-5(2.5)5"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc h "above_ideb_ai"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc h "above_ideb_af"
	if "`y'"=="taxa_abandono_em" loc h "above_ideb_em"
	
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & `h'==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs1)	

	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & `h'==0, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs2)		

		
event_plot cs1 cs2, ///
	stub_lag(Tp# Tp# ) stub_lead( Tm# Tm# ) plottype(connected) ciplottype(rarea) alpha(.1) ///
	 perturb(-0.2(0.1)0.2) trimlead(5) trimlag(6) noautolegend  ///
	graph_opt(title(`w', size(medlarge)) ///
		xtitle("Years of exposure") ytitle("Estimate", xoffset(2)) xlabel(-5 "-6" -4 "-5" -3 "-4" -2 "-3" -1 "-2" 0(1)5) ylabel(`t') xsize(9) ///
		 legend(pos(6) col(2) rows(1) size(3) order(1 "High quality" 5 "Low quality") region(style(none)) ) ///
	xline(-.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dot)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(circle) msize(small) color(blue) lpattern(solid)) lag_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(blue%20 blue%20)) lead_opt1(msymbol(circle) msize(small) color(blue)) ///
	lead_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(blue%20 blue%20)) ///					
	lag_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) lag_ci_opt2(color(red%20 red%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(red%20 red%20)) lead_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) ///
	lead_ci_opt2(color(red%20 red%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(red%20 red%20)) 
	
	
	graph save ideb_`y'.gph, replace	
}

qui foreach y of varlist taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais  {
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc w "Elementary (early grd.)"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc w "Elementary (upper grd.)"
	if "`y'"=="taxa_abandono_em" loc w "High school"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc t "-4(2)4"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc t "-6(2)6"
	if "`y'"=="taxa_abandono_em" loc t "-5(2.5)5"
	if "`y'"=="taxa_abandono_ef_anos_iniciais" loc h "above_ideb_ai"
	if "`y'"=="taxa_abandono_ef_anos_finais" loc h "above_ideb_af"
	if "`y'"=="taxa_abandono_em" loc h "above_ideb_em"
	
	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_p==1 & inse==2, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs1)	

	csdid `y'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_p==1 & inse==1, ivar(co_entidade) time(ano) gvar(ano_inauguracao) method(dripw) agg(event) 
	estat event, estore(cs2)		

		
event_plot cs1 cs2, ///
	stub_lag(Tp# Tp# ) stub_lead( Tm# Tm# ) plottype(connected) ciplottype(rarea) alpha(.1) ///
	 perturb(-0.2(0.1)0.2) trimlead(5) trimlag(6) noautolegend  ///
	graph_opt(title(`w', size(medlarge)) ///
		xtitle("Years of exposure") ytitle("Estimate", xoffset(2)) xlabel( -5 "-6" -4 "-5" -3 "-4" -2 "-3" -1 "-2" 0(1)5) ylabel(`t') xsize(9) ///
		 legend(pos(6) col(2) rows(1) size(3) order(1 "High SES" 5 "Low SES") region(style(none)) ) ///
	xline(-.5, lcolor(black) lpattern(dash)) yline(0, lcolor(black) lpattern(dot)) graphregion(color(white)) bgcolor(white) ylabel(, angle(horizontal))) ///
	lag_opt1(msymbol(circle) msize(small) color(blue) lpattern(solid)) lag_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(blue%20 blue%20)) lead_opt1(msymbol(circle) msize(small) color(blue)) ///
	lead_ci_opt1(color(blue%20 blue%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(blue%20 blue%20)) ///					
	lag_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) lag_ci_opt2(color(red%20 red%20) lpattern(dash dash) ///
	msymbol(point point) msize(zero zero) color(red%20 red%20)) lead_opt2(msymbol(square) msize(small) color(red) lpattern(shortdash)) ///
	lead_ci_opt2(color(red%20 red%20) lpattern(dash dash) msymbol(point point) msize(zero zero) color(red%20 red%20)) 
	
	
	graph save inse_`y'.gph, replace	
}
*
grc1leg ideb_taxa_abandono_ef_anos_iniciais.gph ideb_taxa_abandono_ef_anos_finais.gph, c(2) graphregion(color(white)) iscale(1)  name(fig3, replace) 
	graph display fig3, ysize(4) xsize(8)
	graph export fig3.pdf, replace as(pdf) 	
grc1leg inse_taxa_abandono_ef_anos_iniciais.gph inse_taxa_abandono_ef_anos_finais.gph, c(2) graphregion(color(white)) iscale(1)  name(fig3_2, replace) 
	graph display fig3_2, ysize(4) xsize(8)
	graph export fig3_2.pdf, replace as(pdf) 		
	

	
	
	
cap rename taxa_abandono_ef_anos_iniciais tx_abandono_ef_ai
cap rename taxa_abandono_ef_anos_finais tx_abandono_ef_af
	
** Figure - Radius robustness **	
preserve
keep if min_dist<=4
bys estacao: egen treat_year = max(ano_inauguracao)


foreach v of varlist tx_abandono_ef_ai tx_abandono_ef_af taxa_abandono_em {
qui forv t=1.9(.1)3.1 {
	local h = round(`t'*100)
	g all`h'`v' = cond(min_dist<=`t',treat_year,0)
	*replace robust`h' = round(robust`h')
	replace all`h'`v' = 0 if grupo_tratado3==0

	csdid `v' t_Esc_publica t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4, ivar(co_entidade) time(ano) gvar(all`h'`v') method(dripw) agg(simple) 
	estimates store call`h'`v'
}
}
*
foreach v of varlist tx_abandono_ef_ai tx_abandono_ef_af taxa_abandono_em {
qui forv t=1.9(.1)3 {
	local h = round(`t'*100)
	g pub`h'`v' = cond(min_dist<=`t',treat_year,0)
	*replace robust`h' = round(robust`h')
	replace pub`h'`v' = 0 if grupo_tratado3==0

	csdid `v'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_p==1, ivar(co_entidade) time(ano) gvar(pub`h'`v') method(dripw) agg(simple) 
	estimates store cpub`h'`v'
}
}
*
foreach v of varlist tx_abandono_ef_ai tx_abandono_ef_af taxa_abandono_em {
qui forv t=1.9(.1)3 {
	local h = round(`t'*100)
	g priv`h'`v' = cond(min_dist<=`t',treat_year,0)
	*replace robust`h' = round(robust`h')
	replace priv`h'`v' = 0 if grupo_tratado3==0

	csdid `v'  t_depend* t_filtrada* t_in_esgoto_rede_publica if min_dist<4 & Esc_p==0, ivar(co_entidade) time(ano) gvar(priv`h'`v') method(dripw) agg(simple) 
	estimates store cpriv`h'`v'
}
}

coefplot call*tx_abandono_ef_ai , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (early grd.)", size(medium)) name(abai, replace) 
coefplot call*tx_abandono_ef_af , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (upper grd.)", size(medium)) name(abaf, replace) 
coefplot call*taxa_abandono_em , vertical legend(off) yline(0, lpattern(dash)) title("High school", size(medium)) name(abem, replace) 

graph combine abai abaf abem, r(1) xsize(8) iscale(1)  graphregion(color(white)) name(g0, replace) title(All schools)

coefplot cpub*tx_abandono_ef_ai , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (early grd.)", size(medium)) name(abai1, replace) 
coefplot cpub*tx_abandono_ef_af , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (upper grd.)", size(medium)) name(abaf1, replace) 
coefplot cpub*taxa_abandono_em , vertical legend(off) yline(0, lpattern(dash)) title("High school", size(medium)) name(abem1, replace) 

graph combine abai1 abaf1 abem1, r(1) xsize(8) iscale(1)  graphregion(color(white)) name(g1, replace) title(Public schools)

coefplot cpriv*tx_abandono_ef_ai , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (early grd.)", size(medium)) name(abai2, replace) 
coefplot cpriv*tx_abandono_ef_af , vertical legend(off) yline(0, lpattern(dash)) title("Elementary (upper grd.)", size(medium)) name(abaf2, replace) 
coefplot cpriv*taxa_abandono_em , vertical legend(off) yline(0, lpattern(dash)) title("High school", size(medium)) name(abem2, replace) 

graph combine abai2 abaf2 abem2, r(1) xsize(8) iscale(1)  graphregion(color(white)) name(g2, replace) title(Private schools)


graph combine g0 g1 g2, r(3) xsize(4) iscale(.5)  graphregion(color(white)) name(groups, replace) 
graph export radius.pdf, replace as(pdf) 	
***
restore	
	
	
	
*********************
**** END OF FILE ****
*********************

