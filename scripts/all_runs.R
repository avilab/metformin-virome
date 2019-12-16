library(glue)
library(tidyverse)
library(here)

# Getting run info from ENA: sample names and ftp addresses
bioproject <- c("PRJEB1786", "PRJEB5224", "PRJEB4336")
get_runs <- function(bioproject, reload = FALSE) {
  destfile  <- glue("output/{bioproject}.tsv")
  fields <- "study_accession,sample_accession,sample_title,sample_alias,run_accession,library_layout,read_count,submitted_bytes,fastq_bytes,fastq_ftp"
  url <- glue("https://www.ebi.ac.uk/ena/portal/api/filereport?accession={bioproject}&result=read_run&fields={fields}&format=tsv&download=true")
  if (reload) {
    download.file(url, destfile)
  } else if (!file.exists(destfile)) {
    download.file(url, destfile)
  }
}

out <- map(bioproject, get_runs, reload = TRUE)

runs <- glue("output/{bioproject}.tsv") %>% 
  map(read_tsv, col_types = cols(sample_title = col_character(),
                                 sample_alias = col_character())) %>% 
  bind_rows()

runs %>% 
  mutate(sample_name = case_when(
    study_accession == "PRJEB1786" ~ sample_title,
    TRUE ~ sample_alias
  ),
  sample_name = str_replace(sample_name, "MetaHIT-", "")) %>% 
  select(study_accession, sample_accession, sample_name, run_accession, read_count, library_layout, fastq_bytes, fastq_ftp) %>% 
  write_csv(here("output/all_runs.csv"))

# Bytes to be downloaded
all_runs <- read_csv(here("output/all_runs.csv"))
pe <- all_runs %>% 
  filter(library_layout == "PAIRED")
se <- all_runs %>% 
  filter(library_layout == "SINGLE")

pe_samples <- pe %>% 
  separate(fastq_bytes, c("fq1_bytes", "fq2_bytes"), sep = ";") %>% 
  separate(fastq_ftp, c("fq1", "fq2"), sep = ";") %>% 
  mutate_at(vars(ends_with("bytes")), as.numeric)
pe_samples %>% 
  group_by(study_accession) %>% 
  mutate(GB = (fq1_bytes + fq2_bytes) / 1e9) %>% 
  summarise_at("GB", sum)

pe_samples %>% 
  ggplot() +
  geom_histogram(aes(read_count), bins = 30) +
  scale_x_log10() +
  facet_wrap(~study_accession)


  