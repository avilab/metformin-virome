library(glue)
library(tidyverse)
library(here)

# Getting run info from ENA: sample names and ftp addresses
bioproject <- c("PRJEB1786", "PRJEB5224", "PRJEB4336")
fields <- "study_accession,sample_accession,sample_title,sample_alias,run_accession,read_count,fastq_ftp"
url <- glue("https://www.ebi.ac.uk/ena/portal/api/filereport?accession={bioproject}&result=read_run&fields={fields}&format=tsv&download=true")
out <- map2(url, bioproject, ~download.file(url = .x, destfile = glue("output/{.y}.tsv")))

runs <- glue("output/{bioproject}.tsv") %>% 
  map(read_tsv, col_types = "cccccdc") %>% 
  bind_rows()
runs %>% 
  mutate(sample_name = case_when(
    study_accession == "PRJEB1786" ~ sample_title,
    TRUE ~ sample_alias
  ),
  sample_name = str_replace(sample_name, "MetaHIT-", "")) %>% 
  select(study_accession, sample_accession, sample_name, run_accession, read_count, fastq_ftp) %>% 
  write_csv(here("output/all_runs.csv"))
