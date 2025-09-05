
# rJavaEnv::java_quick_install(version = 21)

options(java.parameters = "-Xmx16G")

library(r5r)
library(haven)
library(data.table)
# library(mapview)
# mapview::mapviewOptions(platform = 'leafgl')

# importa data from stata
df_escolas <- data.table::fread("./data/schools_geocoded.csv")
df_estacao <- haven::read_dta('./data_raw/Base_estacoes_Salvador.dta')


# prepare input data for r5r
data.table::setDT(df_escolas)
data.table::setDT(df_estacao)

data.table::setnames(
  x = df_escolas, 
  old = "co_entidade",
  new = "id"
  )

data.table::setnames(
  x = df_estacao, 
  old = c("estacao", "longitude", "latitude"),
  new = c("id", "lon", "lat")
)

# build graph
data_path <- './r5r_network/'
r5r_network <- r5r::build_network(data_path = data_path)

# caculate travel time matrix
ttm <- r5r::travel_time_matrix(
  r5r_network = r5r_network,
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
  file = './data/travel_times.csv'
  )
