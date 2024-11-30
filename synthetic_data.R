install.packages("bnlearn")

# Load required libraries
library(data.table)
library(tidyverse)
library(bnlearn)

#read in data
combined_data <- fread("combined_data.csv")

#remove unnecessary columns
combined_data <- combined_data %>% 
  select(-subject_id, -hadm_id)

#convert character variables to factors
combined_data <- combined_data %>% 
  mutate_all(factor)

#create a dag and to make relationship with the column
dag <- empty.graph(nodes = names(combined_data))
dag <- set.arc(dag, from = "symptoms", to = "diagnoses")
dag <- set.arc(dag, from = "diagnoses", to = "procedures")

#fit the bayesian network
fitted_bn <- bn.fit(dag, combined_data)

#the length of synthetic data to generate
n <- nrow(combined_data)

#generate synthetic data based on the fitted network
synthetic_data <- rbn(fitted_bn, n = n)

#relocate columns and convert back to chr and int
synthetic_data <- synthetic_data %>% 
  relocate(inpatient_duration, .after = age) %>%
  mutate(across(1:2, ~ suppressWarnings(as.numeric(as.character(.))))) %>%  # Convert first 2 columns to numeric
  mutate(across(3:9, as.character))  # Convert columns 3-9 to character


#check the structure of the modified data frame
str(synthetic_data)

#define the update_gender function with enhanced accuracy
update_gender <- function(data, male_symptoms, female_symptoms) {
  
  #using regex for exact match
  male_pattern <- paste0("\\b(", paste(male_symptoms, collapse = "|"), ")\\b")
  female_pattern <- paste0("\\b(", paste(female_symptoms, collapse = "|"), ")\\b")
  
  #loop through each row to update gender based on matches
  for (i in 1:nrow(data)) {
    #fetch relevant fields for matching
    text <- tolower(paste(data$symptoms[i], data$diagnoses[i], data$procedures[i], sep = " "))
    
    #check for matches
    male_match <- str_detect(text, male_pattern)
    female_match <- str_detect(text, female_pattern)
    
    #assign gender based matches
    if (male_match && !female_match) {
      data$gender[i] <- "Male"
    } else if (female_match && !male_match) {
      data$gender[i] <- "Female"
    } 
  }
  
  return(data)
}

#male and female-specific health terms
female_symptoms <- c("vaginal", "uterine", "cesarean", "female", "abortion", "hysterotomy", "antepartum", "d&c", 
                     "breast", "postpartum", "mastectomy", "pelvic", "eclampsia", "uterus")
male_symptoms <- c("male", "transurethral", "penis", "urethral", "testes", "scrotal", "prostatectomy")

#applying the function
synthetic_data <- update_gender(synthetic_data, male_symptoms, female_symptoms)


#function for refining age
replace_age_if_symptom_match <- function(data, delivery_symptoms) {
  delivery_symptoms <- c("vaginal", "delivery" ,"pregnency", "abortion")
  
  #look for the age and word match
  data <- data %>%
    mutate(age = ifelse(
      (age > 50) & (
        grepl(paste(delivery_symptoms, collapse = "|"), symptoms, ignore.case = TRUE) |
          grepl(paste(delivery_symptoms, collapse = "|"), diagnoses, ignore.case = TRUE) |
          grepl(paste(delivery_symptoms, collapse = "|"), procedures, ignore.case = TRUE)
      ),
      sample(18:50, n(), replace=TRUE), #replace age with random value 18-50
      age #else keep the existing age
    ))
  
  return(data)
}

#apply the function to the dataset
synthetic_data <- replace_age_if_symptom_match(synthetic_data, delivery_symptoms)

write.csv(synthetic_data, file = "synthetic_data.csv", row.names = FALSE)
