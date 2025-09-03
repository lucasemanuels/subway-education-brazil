********************************************************************************************
* Autor: Lucas Emanuel
* Projeto: Subway Education
 
********************************************************************************************

************************************************************************************************************************										* Etapa 1 - Leitura e organização das bases de dados 
************************************************************************************************************************

******************************
* 1 - Censo Escolar: 2009-2019
******************************
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\censo escolar\"
forvalues i=2009/2019  {
import delimited "microdados_ed_basica_`i'\dados\microdados_ed_basica_`i'.csv", delimiter(";") clear 
keep if co_municipio==2927408 | co_municipio==2919207
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\censo escolar\censo_escolar_SSA_LF_`i'.dta", replac  
}

clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\censo escolar\"
use censo_escolar_SSA_LF_2009.dta, clear
append using censo_escolar_SSA_LF_2010.dta, force
append using censo_escolar_SSA_LF_2011.dta, force
append using censo_escolar_SSA_LF_2012.dta, force
append using censo_escolar_SSA_LF_2013.dta, force
append using censo_escolar_SSA_LF_2014.dta, force
append using censo_escolar_SSA_LF_2015.dta, force
append using censo_escolar_SSA_LF_2016.dta, force
append using censo_escolar_SSA_LF_2017.dta, force
append using censo_escolar_SSA_LF_2018.dta, force
append using censo_escolar_SSA_LF_2019.dta, force
ds
keep nu_ano_censo no_municipio co_municipio co_entidade no_entidade tp_dependencia tp_localizacao no_bairro in_agua_filtrada in_agua_potavel in_agua_rede_publica in_energia_rede_publica in_esgoto_rede_publica in_esgoto_fossa in_computador in_acesso_internet_computador in_laboratorio_informatica in_laboratorio_ciencias in_biblioteca in_biblioteca_sala_leitura qt_salas_existentes qt_salas_utilizadas in_sala_professor in_sala_diretoria in_quadra_esportes in_quadra_esportes_coberta in_quadra_esportes_descoberta in_internet in_internet_alunos in_acesso_internet_computador qt_funcionarios in_alimentacao in_regular in_diurno in_noturno in_ead in_bas in_inf in_inf_cre in_inf_pre in_fund in_fund_ai in_fund_af in_med in_prof in_prof_tec in_eja in_eja_fund in_eja_med in_esp qt_mat_bas qt_mat_inf qt_mat_inf_cre qt_mat_inf_pre qt_mat_fund qt_mat_fund_ai qt_mat_fund_af qt_mat_med qt_mat_prof qt_mat_prof_tec qt_mat_eja qt_mat_bas_fem qt_mat_bas_masc qt_mat_bas_nd qt_mat_bas_branca qt_mat_bas_preta qt_mat_bas_parda qt_mat_bas_amarela qt_mat_bas_indigena qt_mat_bas_0_3 qt_mat_bas_4_5 qt_mat_bas_6_10 qt_mat_bas_11_14 qt_mat_bas_15_17 qt_mat_bas_18_mais qt_mat_bas_d qt_mat_bas_n qt_mat_inf_int qt_mat_inf_cre_int qt_mat_inf_pre_int qt_mat_fund_int qt_mat_fund_ai_int qt_mat_fund_af_int qt_mat_med_int qt_doc_bas qt_doc_inf qt_doc_inf_cre qt_doc_inf_pre qt_doc_fund qt_doc_fund_ai qt_doc_fund_af qt_doc_med qt_tur_bas qt_tur_inf qt_tur_inf_cre qt_tur_inf_pre qt_tur_fund qt_tur_fund_ai qt_tur_fund_af qt_tur_med qt_tur_prof
rename nu_ano_censo ano
compress
ds
describe
sum
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\censo_escolar_SSA_LF_2009_2019.dta", replace

************
* 2 - Ideb *
************
**** Anos inciais ****
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\ideb\divulgacao_anos_iniciais_escolas_2023\"
import excel "divulgacao_anos_iniciais_escolas_2023.xlsx", sheet("IDEB_Escolas (Anos_Iniciais)") cellrange(A10) firstrow case(lower) clear
rename id_escola co_entidade
keep co_municipio co_entidade rede vl_nota_matematica_* vl_nota_portugues_* vl_nota_media_* vl_observado_*
forv i=2005(2)2023 {
rename vl_nota_matematica_`i' matematica_ai_`i'
rename vl_nota_portugues_`i' portugues_ai_`i'
rename vl_nota_media_`i' saeb_ai_`i'
rename vl_observado_`i' ideb_ai_`i'
}
drop if co_entidade == .
reshape long portugues_ai_ matematica_ai_ saeb_ai_ ideb_ai_, i(co_municipio co_entidade rede) j(ano)
replace portugues_ai_ = subinstr(portugues_ai_, ",",".",.)
replace matematica_ai_ = subinstr(matematica_ai_, ",",".",.)
destring saeb_ai_ ideb_ai_ matematica_ai_ portugues_ai_ , replace force
rename matematica_ai_ matematica_ai
rename portugues_ai_ portugues_ai
rename saeb_ai_ saeb_ai
rename ideb_ai_ ideb_ai
keep if co_municipio==2927408 | co_municipio==2919207
drop if ano==2005 | ano==2007 | ano==2021 | ano==2023 
compress
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\ideb\ideb_ai_SSA_LF.dta", replace
**** Anos finais ****
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\ideb\divulgacao_anos_finais_escolas_2023\"
import excel "divulgacao_anos_finais_escolas_2023.xlsx", sheet("IDEB_Escolas (Anos_Finais)") cellrange(A10) firstrow case(lower) clear
rename id_escola co_entidade
keep co_municipio co_entidade rede vl_nota_matematica_* vl_nota_portugues_* vl_nota_media_* vl_observado_*
forv i=2005(2)2023 {
rename vl_nota_matematica_`i' matematica_af_`i'
rename vl_nota_portugues_`i' portugues_af_`i'
rename vl_nota_media_`i' saeb_af_`i'
rename vl_observado_`i' ideb_af_`i'
}
drop if co_entidade == .
reshape long portugues_af_ matematica_af_ saeb_af_ ideb_af_, i(co_municipio co_entidade rede) j(ano)
replace portugues_af_ = subinstr(portugues_af_, ",",".",.)
replace matematica_af_ = subinstr(matematica_af_, ",",".",.)
destring saeb_af_ ideb_af_ matematica_af_ portugues_af_, replace force
rename matematica_af_ matematica_af
rename portugues_af_ portugues_af
rename saeb_af_ saeb_af
rename ideb_af_ ideb_af
compress
keep if co_municipio==2927408 | co_municipio==2919207
drop if ano==2005 | ano==2007 | ano==2021 | ano==2023 
compress
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\ideb\ideb_af_SSA_LF.dta", replace
**** Ensino Médio ****   só tem a partir de 2017 em diante
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\ideb\divulgacao_ensino_medio_escolas_2023\"
import excel "divulgacao_ensino_medio_escolas_2023.xlsx", sheet("IDEB_Escolas (ENSINO MÉDIO)") cellrange(A10) firstrow case(lower) clear
rename id_escola co_entidade
keep co_municipio co_entidade rede vl_nota_matematica_* vl_nota_portugues_* vl_nota_media_* vl_observado_*
forv i=2017(2)2023 {
rename vl_nota_matematica_`i' matematica_em_`i'
rename vl_nota_portugues_`i' portugues_em_`i'
rename vl_nota_media_`i' saeb_em_`i'
rename vl_observado_`i' ideb_em_`i'
}
drop if co_entidade == .
reshape long portugues_em_ matematica_em_ saeb_em_ ideb_em_, i(co_municipio co_entidade rede) j(ano)
replace portugues_em_ = subinstr(portugues_em_, ",",".",.)
replace matematica_em_ = subinstr(matematica_em_, ",",".",.)
destring saeb_em_ ideb_em_ matematica_em_ portugues_em_ , replace force
rename matematica_em_ matematica_em
rename portugues_em_ portugues_em
rename saeb_em_ saeb_em
rename ideb_em_ ideb_em
compress
keep if co_municipio==2927408 | co_municipio==2919207
drop if ano==2005 | ano==2007 | ano==2021 | ano==2023 
compress
drop rede
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\ideb\ideb_em_SSA_LF.dta", replace

clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\ideb\"
use "ideb_ai_SSA_LF.dta", clear
merge 1:1 co_municipio co_entidade ano using "ideb_af_SSA_LF.dta",  nogenerate
merge 1:1 co_municipio co_entidade ano using "ideb_em_SSA_LF.dta",  nogenerate
compress

save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\ideb_escola_SSA_LF_2007_2019.dta", replace

************
* 4 - INSE *
************
/*
TP_TIPO_REDE	"Dependência Administrativa:
0 - Total (Federal, Estadual, Municipal e Privada)
1 - Federal
2 - Estadual
3 - Municipal
5 - Total (Estadual e Municipal)
6 - Total (Federal, Estadual e Municipal)"
TP_LOCALIZACAO	"Localização:
0 - Total (Urbana e Rural)
1 - Urbana
2 - Rural
*/
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\inse\"
import excel "Indicador_INSE_por_Escola.xlsx", cellrange(A11) case(lower) clear

rename A co_entidade
rename B no_entidade
rename C co_uf
rename D no_uf
rename E co_municipio
rename F no_municipio
rename G id_area
rename H area
rename I id_rede
rename J rede
rename K id_localizacao
rename L localizacao
rename M qtd_alunos_inse
rename N inse_valor_absoluto
rename O inse_classificação
keep if co_municipio==2927408 | co_municipio==2919207
gen ano=2013
keep co_entidade qtd_alunos_inse inse_valor_absoluto inse_classificação ano
rename inse_classificação inse_classificacao
compress
describe
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\inse_SSA_LF_2013.dta", replace

clear all
use "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\clean\INSE_2013_2015_2019.dta", clear
	
tab ano
keep if ano==2013
	
	
gsort pk_cod_entidade -inse_classificacao
bys pk_cod_entidade: replace inse_classificacao=inse_classificacao[1]
so pk_cod_entidade ano
egen grupo = group(inse_classificacao)
recode grupo (4/5 = 1) (1 2 3 = 2), generate(inse)
drop grupo
describe
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\inse_2013.dta", replace



********************************
* 4 - Indicadores Educacionais *
********************************
* Diverso indicadores educacionais do INEP, no nível da escola, já tratados pela equipe da "Base dos Dados"
* link: https://basedosdados.org/dataset/63f1218f-c446-4835-b746-f109a338e3a1?table=08a18c0b-f460-4173-b779-ee422907b9db 
* bigquerry
/*
SELECT * FROM `basedosdados.br_inep_indicadores_educacionais.escola`
WHERE id_municipio IN (2927408, 2919207)
  AND ano BETWEEN 2009 AND 2019
ORDER BY ano, id_municipio, id_escola;
*/
clear all
import delimited "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\Indicadores educacionais - Basedos dados\bq-results-20250827-220412-1756332268926.csv"
keep  ano id_municipio id_escola localizacao rede ///
  atu_ei atu_ei_creche atu_ei_pre_escola atu_ef atu_ef_anos_iniciais atu_ef_anos_finais atu_em ///
  had_ei had_ei_creche had_ei_pre_escola had_ef had_ef_anos_iniciais had_ef_anos_finais had_em ///
  tdi_ef tdi_ef_anos_iniciais tdi_ef_anos_finais tdi_em ///
  taxa_aprovacao_ef taxa_aprovacao_ef_anos_iniciais taxa_aprovacao_ef_anos_finais taxa_aprovacao_em taxa_reprovacao_ef taxa_reprovacao_ef_anos_iniciais taxa_reprovacao_ef_anos_finais taxa_reprovacao_em taxa_abandono_ef taxa_abandono_ef_anos_iniciais taxa_abandono_ef_anos_finais taxa_abandono_em  ///
  dsu_ei dsu_ei_creche dsu_ei_pre_escola dsu_ef dsu_ef_anos_iniciais dsu_ef_anos_finais dsu_em  ///
  afd_ei_grupo_1 afd_ei_grupo_2 afd_ei_grupo_3 afd_ei_grupo_4 afd_ei_grupo_5 afd_ef_grupo_1 afd_ef_grupo_2 afd_ef_grupo_3 afd_ef_grupo_4 afd_ef_grupo_5 afd_ef_anos_iniciais_grupo_1 afd_ef_anos_iniciais_grupo_2 afd_ef_anos_iniciais_grupo_3  afd_ef_anos_iniciais_grupo_4 afd_ef_anos_iniciais_grupo_5 afd_ef_anos_finais_grupo_1 afd_ef_anos_finais_grupo_2 afd_ef_anos_finais_grupo_3 afd_ef_anos_finais_grupo_4 afd_ef_anos_finais_grupo_5 afd_em_grupo_1 afd_em_grupo_2 afd_em_grupo_3 afd_em_grupo_4 afd_em_grupo_5  ///
  ird_media_regularidade_docente ///
  ied_ef_nivel_1 ied_ef_nivel_2 ied_ef_nivel_3 ied_ef_nivel_4 ied_ef_nivel_5 ied_ef_nivel_6 ied_ef_anos_iniciais_nivel_1 ied_ef_anos_iniciais_nivel_2 ied_ef_anos_iniciais_nivel_3 ied_ef_anos_iniciais_nivel_4 ied_ef_anos_iniciais_nivel_5 ied_ef_anos_iniciais_nivel_6 ied_ef_anos_finais_nivel_1 ied_ef_anos_finais_nivel_2 ied_ef_anos_finais_nivel_3  ied_ef_anos_finais_nivel_4 ied_ef_anos_finais_nivel_5 ied_ef_anos_finais_nivel_6 ied_em_nivel_1 ied_em_nivel_2 ied_em_nivel_3 ied_em_nivel_4 ied_em_nivel_5 ied_em_nivel_6 ///
  icg_nivel_complexidade_gestao_es

rename id_municipio co_municipio
rename id_escola co_entidade  
rename localizacao tipoloca
rename rede dependad

save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\indicadores_educacionais_SSA_LF_2009_2019.dta", replace


*********************************************
* 5 - Base de escolas da região de Salvador *
*********************************************
* Sample de análise: Escolas SSA
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\dist\"
use Base_dist_escolas_estacoes_2, clear
tab linha
preserve
duplicates drop code_school, force
count //  1,674 escolas
restore

gen ano_inauguracao=substr(data_inauguracao, -4, 4)
destring ano_inauguracao, replace
rename code_school co_entidade
replace ano_inauguracao=2023 if linha=="Linha 2 (Planejada)" | linha=="Linha 1 (Planejada)"
tab ano_inauguracao

gen ano_inauguracao_dist2km= ano_inauguracao if  dist_km<=2
bys co_entidade: egen year_inauguracao=min(ano_inauguracao_dist2km)
keep if year_inauguracao==ano_inauguracao_dist2km // as linhas 19-21 resolve para os tratados (lembrar q se mudar corte do tratamento, muda a linha 19)

bys co_entidade: egen min_dist=min(dist_km)
keep if min_dist==dist_km // resolve para os demais

keep co_entidade estacao min_dist linha ano_inauguracao
tab ano_inauguracao
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\escolas_estacoes.dta", replace

*******************
* 6 - Travel time *
*******************
clear all
import delimited "C:\Users\User\OneDrive\Lucas 2025\Paper - Salvador Subway\data\raw\travel_times\travel_times.csv"
rename code_school co_entidade

bys co_entidade: egen min_travel_time=min(travel_time)
keep if min_travel_time==travel_time 

duplicates report co_entidade 
bys co_entidade: gen dup=_N
tab dup
* 45 escolas possuem duas estações mais próximas pela medida de travel time
drop if dup==2
rename estacao estacao_travel_time


* vincular aleatoriamente qual a estação mais próxima (bootstrap))
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\escolas_travel_time.dta", replace

clear all
use "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\escolas_estacoes.dta", clear 
merge 1:1 co_entidade using "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\escolas_travel_time.dta"
drop dup _merge travel_time
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\escolas_estacoes_travel_time.dta", replace


************************************************************
* 7 - Censo escolar aluno - Mora fora e transporte público *
************************************************************
clear all
use "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\alunos_2007_2020_SSA_final.dta", clear 
rename pk_cod_entidade co_entidade
drop if ano <2009 | ano==2020
tab ano
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\alunos_2009_2019_SSA_final.dta", replace

   

****************************************************************************************************************************************************************
										* Etapa 2 - Merge
****************************************************************************************************************************************************************
clear all
cd "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\final\"
use alunos_2009_2019_SSA_final
use indicadores_educacionais_SSA_LF_2009_2019.dta, clear
merge 1:1 ano co_municipio co_entidade using censo_escolar_SSA_LF_2009_2019.dta
keep if _merge==1 | _merge==3
rename _merge merge_censo_indicad_educ
merge 1:1 ano co_municipio co_entidade using ideb_escola_SSA_LF_2007_2019.dta, keep(1 3) nogen
merge 1:1 ano co_entidade using  alunos_2009_2019_SSA_final, keep(1 3) nogen
merge 1:1 ano co_entidade using inse_SSA_LF_2013.dta, keep(1 3) nogen
merge m:1 co_entidade using escolas_estacoes_travel_time,  keep(3) nogen
save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\base_estimacoes_metro_SSA.dta", replace

***************************************************************************************************************************
* ETAPA 3 - GERANDO VARIAVEIS DE TRATAMENTO
***************************************************************************************************************************
clear all
use "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\base_estimacoes_metro_SSA.dta", clear
tab ano
tab co_municipio

global resultstab_path "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\Results\Tables"
global resultsfig_path "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\Results\Figures"

cd "$resultstab_path" 
cd "$resultsfig_path" 

preserve
sum min_dist
duplicates drop co_entidade, force 
count
count if min_dist<=2
count if min_dist>2 & min_dist<=4
count if min_dist>4 & min_dist<=6
restore

gen grupo_tratado1=1 if min_dist<=2
replace grupo_tratado1=0 if min_dist>2 & min_dist<=4
tab grupo_tratado1

gen treat=1 if ano>=ano_inauguracao & grupo_tratado==1
replace treat=0 if missing(treat) & grupo_tratado1==0 
tab treat

gen year_treat=ano_inauguracao if grupo_tratado1==1

	gen time=ano-year_treat
	tab time
	replace time=-1 if year_treat==.
	tab time
	
	forvalues i=-11(1)-2 {
	local a=abs(`i')
	gen pre`a'=time==`i'
	label var pre`a' "`i'"
	}

	forvalues i=0(1)5 {
	local a=abs(`i')
	gen post`a'=time==`i'
	label var post`a' "`i'"
	}

gen grupo_tratado2=1 if min_dist<=2
replace grupo_tratado2=0 if min_dist>3 & min_dist<=5
tab grupo_tratado2

gen grupo_tratado3=1 if min_dist<=2 & (linha~="Linha 2 (Planejada)" | linha~="Linha 1 (Planejada)")
replace grupo_tratado3=0 if min_dist<=2 & (linha=="Linha 2 (Planejada)" | linha=="Linha 1 (Planejada)") 
tab grupo_tratado3

tab grupo_tratado1
tab grupo_tratado2
tab grupo_tratado3

save "C:\Users\dasil\OneDrive\Lucas 2025\Paper - Salvador Subway\data\base_estimacoes_metro_SSA_final.dta", replace

***************************************************************************************************************************
* ETAPA 4 - ESTIMAÇÕES 
***************************************************************************************************************************














