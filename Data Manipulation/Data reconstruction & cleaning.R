
#install libraries
install.packages("tidyverse")
install.packages("data.table")

#load required libraries
library(tidyverse)
library(data.table)

#load datasets
admission <- fread("admissions.csv")
patients <- fread("patients.csv")
symptoms <- fread("drgcodes.csv")
diagnoses <- fread("d_icd_diagnoses.csv")
diagnoses_icd <- fread("diagnoses_icd.csv")
procedures <- fread("d_icd_procedures.csv")
procedures_icd <- fread("procedures_icd.csv")

#select the relevant columns
admission_clean <- admission %>% 
  select(subject_id, hadm_id, admittime, dischtime,admission_type, race, insurance)

#select the relevant columns
patients_clean <- patients %>% 
  select(subject_id, gender, anchor_age)

#select the relevant columns
symptoms_clean <- symptoms %>% 
  select(subject_id, hadm_id, description)

#remove unnecessary columns
procedures_icd_clean <- procedures_icd %>% 
  select(-seq_num, -chartdate)

#remove unnecessary column
diagnoses_icd_clean <- diagnoses_icd %>% 
  select(-seq_num)

#extract diagnoses from diagnoses & diagnoses_icd
merged_diagnoses <- diagnoses_icd_clean %>% 
  left_join(diagnoses %>% 
              rename(diagnoses=long_title), by = c("icd_code","icd_version"))

#extract procedures from procedures & procedure_icd
merged_procedures <- procedures_icd_clean %>% 
  left_join(procedures %>% 
              rename(procedures=long_title), by = c("icd_code","icd_version"))

#combined all the datasets
combined_data <- admission_clean %>% 
  left_join(patients_clean, by = "subject_id") %>% 
  left_join(symptoms_clean %>% 
              rename(symptoms=description), by = c("subject_id", "hadm_id")) %>% 
  left_join(merged_diagnoses, by = c("subject_id", "hadm_id")) %>% 
  left_join(merged_procedures, by = c("subject_id", "hadm_id"))

#check if there is any missing value
colSums(is.na(combined_data))

#remove NA
combined_data <- drop_na(combined_data)

combined_data <- combined_data %>% 
  distinct(subject_id, .keep_all = TRUE) %>% #remove duplicate rows 
  rename(age = 9) %>%  #rename the column
  select(subject_id,hadm_id, admittime, dischtime, age, gender, admission_type, insurance, race, symptoms, diagnoses, procedures)

#remove empty values
combined_data <- combined_data[!is.na(combined_data$insurance) & combined_data$insurance != "", ]

#extract the time spent in the hospital & round up the value to the next whole number
combined_data <- combined_data %>%
  mutate(
    inpatient_duration = ceiling(as.numeric(difftime(dischtime, admittime, units = "days")))
  )

#remove admit time and discharge time
combined_data <- combined_data %>% 
  select(-admittime, -dischtime) %>% 
  relocate(inpatient_duration, .after = race)

#function to categorize admission types
cat_admission_type <- function(admission) {
  if (admission %in% c("URGENT", "EW EMER.", "DIRECT EMER.")) {
    return("Emergency")
  } else if (admission %in% c("ELECTIVE", "SURGICAL SAME DAY ADMISSION")) {
    return("Elective")
  } else if (admission %in% c("OBSERVATION ADMIT", "EU OBSERVATION", "DIRECT OBSERVATION")) {
    return("Observation")
  } else {
    return("Other")  #for any admission types that don't fit
  }
}

#apply categorization function to the dataset
combined_data$admission_type <- sapply(combined_data$admission_type, cat_admission_type)

#function to generalized ethnicity groups
gen_ethnicity <- function(ethnicity) {
  sapply(ethnicity, function(x) {
    if (grepl("ASIAN", x)) {
      return("Asian")
    } else if (grepl("WHITE", x) || grepl("EUROPEAN", x) || x %in% c("PORTUGUESE", "SOUTH AMERICAN")) {
      return("White")
    } else if (grepl("BLACK", x) || x == "AMERICAN INDIAN/ALASKA NATIVE") {
      return("Black")
    } else if (grepl("HISPANIC", x) || grepl("LATINO", x)) {
      return("Hispanic")
    } else {
      return("Other")
    }
  })
}

#apply generalization to the dataset
combined_data$race <- gen_ethnicity(combined_data$race)

#remove duplicate entity
combined_data <- combined_data[!duplicated(combined_data[, "procedures"]), ]

#define a function to process rows
clean_text <- function(text) {
  #match abbreviations (all uppercase or with slashes, e.g., LUTS or AICD)
  abbreviation_pattern <- "\\((?:[A-Z]+|[A-Z]+/[A-Z]+)\\)|\\[[A-Z]+\\]"
  
  #remove non-abbreviation phrases in parentheses or square brackets
  cleaned_text <- str_remove_all(text, "\\([^()]*\\)|\\[[^\\[\\]]*\\]")
  
  #reinsert abbreviations (preserve only abbreviations)
  abbreviations <- str_extract_all(text, abbreviation_pattern)[[1]]
  if (length(abbreviations) > 0) {
    cleaned_text <- paste(cleaned_text, paste(abbreviations, collapse = " "))
  }
  
  #remove extra spaces
  cleaned_text <- str_squish(cleaned_text)
  
  return(cleaned_text)
}

#apply to the data
combined_data <- combined_data %>% 
  mutate(across(c(symptoms, diagnoses, procedures), ~ sapply(., clean_text)))

#save the new data
write.csv(combined_data, file = "combined_data.csv", row.names = FALSE)
