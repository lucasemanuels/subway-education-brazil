options(java.parameters = "-Xmx16G")

library(r5r)
library(haven)
library(data.table)
# library(mapview)
# mapview::mapviewOptions(platform = 'leafgl')

# importa data from stata
df_escolas <- haven::read_dta('./data_raw/Base_escolas_paper_subway.dta')
df_estacao <- haven::read_dta('./data_raw/Base_estacoes_Salvador.dta')


# prepare input data for r5r
data.table::setDT(df_escolas)
data.table::setDT(df_estacao)

data.table::setnames(
  x = df_escolas, 
  old = c("code_school", "longitude", "latitude"),
  new = c("id", "lon", "lat")
  )

data.table::setnames(
  x = df_estacao, 
  old = c("estacao", "longitude", "latitude"),
  new = c("id", "lon", "lat")
)

# build graph
data_path <- './r5r_network/'
r5r_core <- r5r::setup_r5(data_path = data_path)

# caculate travel time matrix
ttm <- r5r::travel_time_matrix(
  r5r_core = r5r_core,
  origins = df_estacao,
  destinations = df_escolas,
  mode = 'walk',
  max_trip_duration = 1440, # 24 hours in minutes
  walk_speed = 3.6,
  progress = TRUE
  )

data.table::setnames(
  x = ttm, 
  old = c("from_id", "to_id", "travel_time_p50"),
  new = c("estacao", "code_school", "travel_time")
)

head(ttm)

# check if all schools have been found
nrow(ttm) == (nrow(df_escolas) * nrow(df_estacao))


# export result
data.table::fwrite(
  x = ttm,
  file = './data_output/travel_times.csv'
  )
