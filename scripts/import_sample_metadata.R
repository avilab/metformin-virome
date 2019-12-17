library(tidyverse)
library(here)
library(readxl)


SItableS1_sample_subsets <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Sample subsets")
SItableS1_phenotypes <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Phenotypes", na = "NA")

SItableS1_sample_subsets %>% 
  filter(Status %in% c("T2D metformin-", "T2D metformin+")) %>% 
  count(`Country subset`, Status) %>% 
  knitr::kable(caption = "Number of T2D patiens on metformin treatment.", format = "html") %>% 
  kableExtra::kable_styling()

nature15766_t2d <- SItableS1_sample_subsets %>% 
  filter(Status %in% c("T2D metformin-", "T2D metformin+")) %>% 
  select(sample_name = Sample, country = `Country subset`, Status) %>% 
  mutate(sample_name = str_remove(sample_name, "NG.*_"))

# 70 year old women from Sweden
nature12198_s2 <- read_excel("data/nature12198-s2.xlsx", sheet = "Supplementary Table 3", skip = 1) %>% 
  rename(Sample = `Sample ID`, oral_anti_diabetic_medication = `Oral anti-diabetic medication (-, no medication; Met, metformin; Sulph, sulphonylurea)`) %>% 
  select(1:30)

nature12198_s2 %>% 
  filter(Classification == "T2D") %>% 
  select(Sample, Classification, oral_anti_diabetic_medication) %>% 
  count(oral_anti_diabetic_medication) %>% 
  knitr::kable(caption = "Number of T2D patiens on metformin treatment.") %>% 
  kableExtra::kable_styling()

# Non-Sweden born participans have been living in Sweden for 37-60 years. Their country of origin will be SWE.
nature12198_t2d <- nature12198_s2 %>% 
  filter(Classification == "T2D", oral_anti_diabetic_medication %in% c("-", "Met")) %>% 
  mutate(country = "SWE", Status = case_when(
    oral_anti_diabetic_medication == "-" ~ "T2D metformin-",
    oral_anti_diabetic_medication == "Met" ~ "T2D metformin+"
  )) %>% 
  select(sample_name = Sample, country, Status)

# nature12506 study excluded T2D patients, only BMI data is available.
t2d_samples <- bind_rows(nature15766_t2d, nature12198_t2d)
t2d_samples %>% 
  group_by(country, Status) %>% 
  count()

library(httr)
library(xml2)
library(glue)
get_accession <- function(query) {
  r <- GET(glue("http://www.ebi.ac.uk/ena/data/search?query={query}&result=read_run&display=xml"))
  r %>% 
    content() %>% 
    xml2::read_xml() %>% 
    xml2::xml_contents() %>% 
    .[[1]] %>% 
    xml_attrs() %>% 
    .[["accession"]]
}

get_runs_from_acc <- safely(. %>% get_accession %>% get_runs)

t2d_samples %>% 
  filter(country == "CHN") %>% 
  pull(sample_name) %>% 
  map(get_runs_from_acc)

missing_runs <- list.files("output", pattern = "^SRR\\d+", full.names = TRUE) %>% 
  tibble(files = .) %>% 
  mutate(runs = map(files, read_tsv))
bgi_runs <- missing_runs %>% 
  pull(runs) %>% 
  bind_rows() %>% 
  mutate(sample_name = str_replace(sample_alias, "bgi-", "")) %>% 
  select(study_accession, sample_accession, sample_name, run_accession, read_count, library_layout, fastq_bytes, fastq_ftp)

all_runs <- read_csv(here("output/all_runs.csv")) %>% 
  filter(library_layout == "PAIRED") %>% 
  mutate(sample_name = str_replace(sample_name, "-IE$", ""))
all_runs <- all_runs %>% 
  bind_rows(bgi_runs)

t2d_runs <- inner_join(t2d_samples, all_runs) %>%
  group_by(sample_name) %>% 
  top_n(1, read_count) %>% 
  distinct() %>% 
  ungroup()

t2d_runs %>% 
  ggplot() +
  geom_histogram(aes(read_count), binwidth = 1e6)

# Check again 
t2d_runs %>% 
  group_by(country, Status) %>% 
  count()

# Runs/samples with more than 15M reads
t2d_runs %>% 
  filter(read_count >= 1.5e7) %>% 
  count(country, Status)

# Parse samples for samples.tsv file
samples <- t2d_runs %>% 
  # filter(read_count >= 1.5e7) %>% 
  separate(fastq_ftp, c("fq1", "fq2"), sep = ";") %>% 
  separate(fastq_bytes, c("fq1_bytes", "fq2_bytes"), sep = ";") %>% 
  mutate_at(vars(ends_with("bytes")), as.numeric) %>% 
  mutate(GB = (fq1_bytes + fq2_bytes) / 1e9) %>% 
  select(-fq1_bytes, -fq2_bytes) %>% 
  rename(sample = sample_name, run = run_accession)
samples %>% 
  write_tsv(here("samples.tsv"))

samples %>% 
  group_by(study_accession) %>% 
  summarise_at("GB", sum)

samples %>% 
  group_by(study_accession, country, Status) %>% 
  count()
