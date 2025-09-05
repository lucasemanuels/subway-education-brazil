# Description ------------------------------------------------------------------------

# This script geocodes the addresses of schools using the Brazilian School 
# Census dataset (`Censo Escolar`) as input. It selects relevant address 
# components (street, number, CEP, neighborhood, municipality, state), 
# prepares the data for geocoding using the `geocodebr` package, and then 
# runs batch geolocation for each school.
#
# The resulting dataset includes geographic coordinates (latitude, longitude) 
# for each school, and is exported as a `.csv` file for later use in spatial 
# analyses or merging with monitoring data.


library(ipeadatalake)
library(geocodebr)
library(dplyr)
library(arrow)
library(data.table)
# library(mapview)
# library(sf)
# library(geobr)
# library(data.table)
# library(purrr)
# library(lubridate)
options(scipen = 999)

# 1. Load and prepare school address data -------------------------------

gather_schools_in_year <- function(year){
  
  df <- ipeadatalake::ler_censo_escolar(ano = year, base = 'basica') |>
    dplyr::select('NU_ANO_CENSO','CO_ENTIDADE','TP_SITUACAO_FUNCIONAMENTO',
                  'NO_MUNICIPIO','CO_UF','CO_MUNICIPIO','DS_ENDERECO',
                  'NU_ENDERECO','DS_COMPLEMENTO','NO_BAIRRO','CO_CEP')
    
  # filter salvador e lauro de freitas
  df <- df |>
    filter(CO_MUNICIPIO %in% c(2927408, 2919207))
  
  
  df_arc <- ipeadatalake::adicionar_geoloc(
    dados = df, 
    base = 'censo_escolar', 
    ano = year
    )
  
  
  df_schools <- df_arc |>
    janitor::clean_names() |>
    mutate(
      abbrev_state = co_uf,
      code_muni    = co_municipio,
      logradouro   = ds_endereco,
      numero       = nu_endereco,
      cep          = co_cep,
      bairro       = no_bairro,
      arc_score = score,
      arc_precisao = addr_type,
      arc_address = match_addr,
      arc_lat = lat,
      arc_lon = lon
    ) |>
    select(co_entidade, abbrev_state, code_muni, logradouro, numero, cep, bairro,
           arc_score, arc_precisao, arc_address, arc_lat, arc_lon) |>
    collect()
  
  data.table::setDT(df_schools)[, year := year]
  
  return(df_schools)
}

# periodo da analise
YEAR_VEC   <- 2009L:2020L # 2011L:2024L

df_schools <- pbapply::pblapply(X = YEAR_VEC, FUN = gather_schools_in_year) |>
  data.table::rbindlist()

head(df_schools)


# schools_sf <- df_schools |>
#   sfheaders::sf_point(x = 'arc_lon', y = 'arc_lat', keep = T)
# sf::st_crs(schools_sf) <- 4674
# mapview::mapview(schools_sf)


# 2. Geocode school addresses with geocodebr -------------------------------------

fields <- geocodebr::definir_campos(
  logradouro  = 'logradouro',
  numero      = 'numero',
  cep         = 'cep',
  localidade  = 'bairro',
  municipio   = 'code_muni',
  estado      = 'abbrev_state'
)

# sort data
df_schools <- df_schools[order(abbrev_state, code_muni, co_entidade)]

df_schools_geo <- geocodebr::geocode(
  enderecos          = df_schools,
  campos_endereco    = fields,
  resultado_completo = TRUE,
  verboso            = TRUE,
  resolver_empates   = TRUE,
  n_cores            = 10
)

data.table::setnames(
  df_schools_geo, 
  old = c('lat', 'lon', 'precisao', 'tipo_resultado'),
  new = c('geocodebr_lat', 'geocodebr_lon', 'geocodebr_precisao', 'geocodebr_tipo_resultado')
)

# schools_sf2 <- df_schools_geo |>
#   sfheaders::sf_point(x = 'geocodebr_lon', y = 'geocodebr_lat', keep = T)
# sf::st_crs(schools_sf2) <- 4674
# mapview::mapview(schools_sf2)


janitor::tabyl(df_schools_geo$geocodebr_precisao)
janitor::tabyl(df_schools_geo$arc_precisao)


# 2. filtra precisao geocode --------------------------------

# mantem a melhor precisao de geocodebr e arcgis e inep

#' precision levels arcgis
#' 
#' Locality - Administrative areas such as municipalities, cities, and neighborhoods; typically the smallest administrative area
#' PostalLoc - Postal code points combined with administrative boundaries.
#' PostalExt - Extended postal code points such as USPS ZIP+4.
#' Postal - Postal code points.
#' POI - Points of interest, such as populated places, business names, landmarks, and geographic names.
#' PointAddress - Point address with associated house numbers and street names.
#' BuildingName - Point address with an associated building name.
#' StreetAddress — A street address, such as 320 Madison St, that represents an interpolated location along a street given the house number within an address range
#' StreetInt - Street intersections derived from StreetAddress data.
#' StreetAddressExt - An interpolated StreetAddress match when the house number component of the address falls outside the existing StreetAddress house number range.
#' StreetName — Similar to a street address but without the house number. Reference data contains street centerlines with associated street names (no numbered address ranges), along with administrative divisions and optional postal code, for example, W Olive Ave, Redlands, CA, 92373.

max_cats_geocodebr <- c("numero")
max_cats_arcgis <- c("PointAddress", "StreetInt", "BuildingName", "POI")




# select best results
df_schools_geo[ , lat := fcase( 
  geocodebr_precisao == max_cats_geocodebr                  , geocodebr_lat,
  arc_precisao %chin% max_cats_arcgis                       , arc_lat,
  geocodebr_precisao == "numero_aproximado"                 , geocodebr_lat,
  arc_precisao %chin% c("StreetAddress", "StreetAddressExt"), arc_lat,
  geocodebr_precisao == "logradouro"                        , geocodebr_lat,
  arc_precisao == "StreetName"                              , arc_lat,
  geocodebr_precisao == "cep"                               , geocodebr_lat,
  arc_precisao %in% c('PostalLoc', 'PostalExt', 'Postal')   , arc_lat,
  geocodebr_precisao == "localidade"                        , geocodebr_lat,
  arc_precisao == "Locality"                                , arc_lat,
  default = NA)
  ]

df_schools_geo[ , lon := fcase( 
  geocodebr_precisao == max_cats_geocodebr                  , geocodebr_lon,
  arc_precisao %chin% max_cats_arcgis                       , arc_lon,
  geocodebr_precisao == "numero_aproximado"                 , geocodebr_lon,
  arc_precisao %chin% c("StreetAddress", "StreetAddressExt"), arc_lon,
  geocodebr_precisao == "logradouro"                        , geocodebr_lon,
  arc_precisao == "StreetName"                              , arc_lon,
  geocodebr_precisao == "cep"                               , geocodebr_lon,
  arc_precisao %in% c('PostalLoc', 'PostalExt', 'Postal')   , arc_lon,
  geocodebr_precisao == "localidade"                        , geocodebr_lon,
  arc_precisao == "Locality"                                , arc_lon,
  default = NA)
]

# register source
df_schools_geo[ , coords_source := fcase( 
  geocodebr_precisao == max_cats_geocodebr                  , 'geocodebr',
  arc_precisao %chin% max_cats_arcgis                       , 'arcgis',
  geocodebr_precisao == "numero_aproximado"                 , 'geocodebr',
  arc_precisao %chin% c("StreetAddress", "StreetAddressExt"), 'arcgis',
  geocodebr_precisao == "logradouro"                        , 'geocodebr',
  arc_precisao == "StreetName"                              , 'arcgis',
  geocodebr_precisao == "cep"                               , 'geocodebr',
  arc_precisao %in% c('PostalLoc', 'PostalExt', 'Postal')   , 'arcgis',
  geocodebr_precisao == "localidade"                        , 'geocodebr',
  arc_precisao == "Locality"                                , 'arcgis',
  default = NA)
]


# schools_sf3 <- df_schools_geo |>
#   filter(!is.na(lat)) |>
#   sfheaders::sf_point(x = 'lon', y = 'lat', keep = T)
# sf::st_crs(schools_sf3) <- 4674
# mapview::mapview(schools_sf3)

# janitor::tabyl(df_schools_geo$coords_source)
# # df_schools_geo$coords_source     n    percent valid_percent
# #                       arcgis  6348 0.3357486645      0.335873
# #                    geocodebr 12552 0.6638811022      0.664127
# #                         <NA>     7 0.0003702332            NA
# # 

# there are still 7 cases without coordinates (1 unique school)
df_schools_geo[ is.na(lat), co_entidade] |> unique() |> length()


# For these cases, we'll use inep coords in geobr 2020
geobr_schools <- geobr::read_schools(year = 2020)
geobr_schools <- sfheaders::sf_to_df(geobr_schools, fill = T)

geobr_schools <- geobr_schools |>
  select(code_school, x, y)

data.table::setDT(geobr_schools)
df_schools_geo[geobr_schools, on=c('co_entidade'='code_school'), lon_inep := i.x]
df_schools_geo[geobr_schools, on=c('co_entidade'='code_school'), lat_inep := i.y]

df_schools_geo[ , coords_source := ifelse( is.na(coords_source), "inep", coords_source)]
df_schools_geo[ , lon := ifelse( coords_source=="inep", lon_inep, lon)]
df_schools_geo[ , lat := ifelse( coords_source=="inep", lat_inep, lat)]
janitor::tabyl(df_schools_geo$coords_source)


# reorder rows and cols
df_schools_geo <- df_schools_geo[order(year, code_muni, co_entidade)]
data.table::setcolorder(
  x = df_schools_geo, 
  neworder = c('year', 'co_entidade', 'code_muni', 'lat', 'lon', 'coords_source', 
               'arc_precisao', 'geocodebr_precisao')
  )

# schools_sf <- df_schools_geo |>
#     filter(!is.na(lat)) |>
#   sfheaders::sf_point(x = 'lon', y = 'lat', keep = T)
# 
# sf::st_crs(schools_sf) <- 4674
# mapview::mapviewOptions(platform = 'mapdeck')
# mapview::mapview(schools_sf)

# o numero de NAs cai de 565 para 237
summary(df_schools_geo$lat)

# we still have 80 schools with missing coordinates 
df_schools_geo[ is.na(lat), co_entidade] |> unique() |> length()

# but some schools are missing just one or two years and the other the whole period 12 years
df_schools_geo[ is.na(lat), co_entidade] |> table()
summary(df_schools_geo$lat)


# escola q desaparece em alguns anos
# 29463351 varios anos
# 29458617, em 2015 ?
# 29180384

# escola q parece mudar de endereco
# 29178614

# fix NAs ?
# fix missing years ?




# 5. add H3 index  ------------------------------------------

df_schools <- df_schools_geo[ !is.na(lat)]

df_schools[, h3_09 := h3r::latLngToCell(lat = lat, lng = lon, resolution = 9)]

# did_i_move ----------------------------------------------------------------------------------

did_i_move <- function(h3_address, tolerance = 2) {
  
  ring <- if(tolerance > 1) {
    c(1:tolerance) |> 
      purrr::map(
        \(x) h3r::gridRingUnsafe(h3_address, rep(x, length(h3_address)))
      ) |> 
      purrr::reduce(\(acc, nxt) purrr::map2(acc, nxt, c))
    
  } else {
    h3r::gridRingUnsafe(h3_address, rep(tolerance, length(h3_address))) 
  }
  
  ## fills rings with the own hexagon
  hive <- purrr::map2(h3_address, ring, \(x, y) c(x, y)) |> unique()
  
  
  ## FALSE if there are different rings
  !purrr::every(h3_address, \(x) purrr::every(hive, \(y) x %in% y))
}



df_schools[, movers := did_i_move(h3_09), by = co_entidade]


janitor::tabyl(df_schools$movers)


df_movers <- df_schools[movers ==T]


a <- df_movers[co_entidade == 29178193]

a <- a |>
  select(-c(year)) |>
  distinct()

a$movers
unique(a$h3_09)



# 5. Save geocoded school data   ------------------------------------------

data.table::fwrite(df_schools,file = "./data/schools_geocoded.csv")

