# --- Instalar (uma vez) ---
install.packages(c("censobr", "dplyr", "haven"))

library(censobr)
library(dplyr)
library(haven)


###########################  "DomicilioRenda"
# Parâmetros
muni_code    <- 2927408            # Salvador
dataset_name <- "DomicilioRenda"           # Troque p/ "Domicilio", "Pessoa", etc.
# out_file     <- sprintf("censo2010_setor_salvador_%s.dta", tolower(dataset_name))

# 1) Ler setores de 2010 (retorna Arrow Dataset)
ds <- read_tracts(
  year = 2010,
  dataset = dataset_name,
  showProgress = TRUE
)

# 2) Filtrar Salvador e materializar em data.frame
ssa10 <- ds |>
  filter(code_muni == muni_code) |>
  select(code_tract, code_muni, everything()) |>
  collect()

# 3) (Opcional, mas recomendado) garantir IDs como texto para não perder zeros
ssa10 <- ssa10 |>
  mutate(
    code_tract = as.character(code_tract),
    code_muni  = as.character(code_muni)
  )

# 4) Salvar em .dta (Stata 14)
write_dta(
  data   = ssa10,
  path   = out_file,
  version = 14,
  label  = sprintf("Censo 2010 - Setor - Salvador - %s", dataset_name)
)
write_dta(ssa10, paste0("C:/Users/User/OneDrive/Lucas 2025/Paper - Salvador Subway/data/raw/census tract/", "censo2010_setor_salvador_DomicilioRenda.dta"))

#cat("Arquivo salvo em:", normalizePath(out_file), "\n")


###########################  "Basico"
# Parâmetros
muni_code    <- 2927408            # Salvador
dataset_name <- "Basico"           # Troque p/ "Domicilio", "Pessoa", etc.
# out_file     <- sprintf("censo2010_setor_salvador_%s.dta", tolower(dataset_name))

# 1) Ler setores de 2010 (retorna Arrow Dataset)
ds <- read_tracts(
  year = 2010,
  dataset = dataset_name,
  showProgress = TRUE
)

# 2) Filtrar Salvador e materializar em data.frame
ssa10 <- ds |>
  filter(code_muni == muni_code) |>
  select(code_tract, code_muni, everything()) |>
  collect()

# 3) (Opcional, mas recomendado) garantir IDs como texto para não perder zeros
ssa10 <- ssa10 |>
  mutate(
    code_tract = as.character(code_tract),
    code_muni  = as.character(code_muni)
  )

# 4) Salvar em .dta (Stata 14)
write_dta(
  data   = ssa10,
  path   = out_file,
  version = 14,
  label  = sprintf("Censo 2010 - Setor - Salvador - %s", dataset_name)
)
write_dta(ssa10, paste0("C:/Users/User/OneDrive/Lucas 2025/Paper - Salvador Subway/data/raw/census tract/", "censo2010_setor_salvador_Basico.dta"))


###########################  "Domicilio"
# Parâmetros
muni_code    <- 2927408            # Salvador
dataset_name <- "Domicilio"           # Troque p/ "Domicilio", "Pessoa", etc.
# out_file     <- sprintf("censo2010_setor_salvador_%s.dta", tolower(dataset_name))

# 1) Ler setores de 2010 (retorna Arrow Dataset)
ds <- read_tracts(
  year = 2010,
  dataset = dataset_name,
  showProgress = TRUE
)

# 2) Filtrar Salvador e materializar em data.frame
ssa10 <- ds |>
  filter(code_muni == muni_code) |>
  select(code_tract, code_muni, everything()) |>
  collect()

# 3) (Opcional, mas recomendado) garantir IDs como texto para não perder zeros
ssa10 <- ssa10 |>
  mutate(
    code_tract = as.character(code_tract),
    code_muni  = as.character(code_muni)
  )

# 4) Salvar em .dta (Stata 14)
write_dta(
  data   = ssa10,
  path   = out_file,
  version = 14,
  label  = sprintf("Censo 2010 - Setor - Salvador - %s", dataset_name)
)
write_dta(ssa10, paste0("C:/Users/User/OneDrive/Lucas 2025/Paper - Salvador Subway/data/raw/census tract/", "censo2010_setor_salvador_Domicilio.dta"))


# Abre o dicionário oficial (HTML/PDF) no navegador:
data_dictionary(year = 2010, dataset = "tracts")

# Ver nomes de colunas do módulo Entorno (com os prefixos entorno01_/02_/03_)
vars <- read_tracts(year = 2010, dataset = "Entorno", as_data_frame = FALSE, showProgress = FALSE)
names(vars)