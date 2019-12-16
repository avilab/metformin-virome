library(tidyverse)
library(here)
library(readxl)

SItableS1_sample_subsets <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Sample subsets")
SItableS1_phenotypes <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Phenotypes", na = "NA")

SItableS1_sample_subsets %>% 
  filter(Status %in% c("T2D metformin-", "T2D metformin+")) %>% 
  count(Status) %>% 
  knitr::kable(caption = "Number of T2D patiens on metformin treatment.", format = "html") %>% 
  kableExtra::kable_styling()

nature15766_t2d <- SItableS1_sample_subsets %>% 
  filter(Status %in% c("T2D metformin-", "T2D metformin+")) %>% 
  select(sample_name = Sample, Status) %>% 
  mutate(sample_name = str_remove(sample_name, "NG.*_"))

nature12198_s2 <- read_excel("data/nature12198-s2.xlsx", sheet = "Supplementary Table 3", skip = 1) %>% 
  rename(Sample = `Sample ID`, oral_anti_diabetic_medication = `Oral anti-diabetic medication (-, no medication; Met, metformin; Sulph, sulphonylurea)`) %>% 
  select(1:30)

nature12198_s2 %>% 
  filter(Classification == "T2D") %>% 
  select(Sample, Classification, oral_anti_diabetic_medication) %>% 
  count(oral_anti_diabetic_medication) %>% 
  knitr::kable(caption = "Number of T2D patiens on metformin treatment.") %>% 
  kableExtra::kable_styling()

nature12198_t2d <- nature12198_s2 %>% 
  filter(Classification == "T2D", oral_anti_diabetic_medication %in% c("-", "Met")) %>% 
  mutate(Status = case_when(
    oral_anti_diabetic_medication == "-" ~ "T2D metformin-",
    oral_anti_diabetic_medication == "Met" ~ "T2D metformin+"
  )) %>% 
  select(sample_name = Sample, Status)

# nature12506 study excluded T2D patients, only BMI data is available.
t2d_samples <- bind_rows(nature15766_t2d, nature12198_t2d)

all_runs <- read_csv(here("output/all_runs.csv"))

t2d_runs <- inner_join(t2d_samples, all_runs) %>% 
  group_by(sample_name) %>% 
  top_n(1, read_count) %>% 
  distinct() %>% 
  ungroup()

t2d_runs %>% 
  ggplot() +
  geom_histogram(aes(read_count), binwidth = 1e6)

# Runs/samples with more than 15M reads
t2d_runs %>% 
  filter(read_count >= 1.5e7) %>% 
  count(Status)

t2d_samples <- t2d_runs %>% 
  # filter(read_count >= 1.5e7) %>% 
  separate(fastq_ftp, c("fq1", "fq2"), sep = ";") %>% 
  separate(fastq_bytes, c("fq1_bytes", "fq2_bytes"), sep = ";") %>% 
  mutate_at(vars(ends_with("bytes")), as.numeric) %>% 
  mutate(GB = (fq1_bytes + fq2_bytes) / 1e9) %>% 
  select(-fq1_bytes, -fq2_bytes) %>% 
  rename(sample = sample_name, run = run_accession)

t2d_samples %>% 
  group_by(study_accession) %>% 
  summarise_at("GB", sum)

t2d_samples %>% 
  group_by(study_accession, Status) %>% 
  count()

t2d_samples %>% 
  write_tsv(here("output/samples.tsv"))

