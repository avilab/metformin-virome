library(tidyverse)
library(here)
library(readxl)

SItableS1_sample_subsets <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Sample subsets")
SItableS1_phenotypes <- read_excel("data/nature15766-s2/SItableS1.xls", sheet = "Phenotypes", na = "NA")
SItableS1_sample_subsets %>% 
  filter(Status %in% c("T2D metformin-", "T2D metformin+")) %>% 
  left_join(SItableS1_phenotypes) %>% 
  count(Status)

nature12198_s2 <- read_excel("data/nature12198-s2.xlsx", sheet = "Supplementary Table 3", skip = 1) %>% 
  rename(Sample = `Sample ID`, oral_anti_diabetic_medication = `Oral anti-diabetic medication (-, no medication; Met, metformin; Sulph, sulphonylurea)`) %>% 
  select(1:30)
nature12198_s2 %>% 
  filter(Classification == "T2D") %>% 
  select(Sample, Classification, oral_anti_diabetic_medication) %>% 
  count(oral_anti_diabetic_medication)
