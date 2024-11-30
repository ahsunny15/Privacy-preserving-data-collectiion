#install libraries
install.packages("tidyverse")
install.packages("data.table")
install.packages("digest")

#load required libraries
library(tidyverse)
library(data.table)
library(digest)

#load dataset
combined_data <- fread("combined_data.csv")

#generalize the age
combined_data$age <- cut(combined_data$age,
                         breaks = c(0,10,20,30,40,50,60,70,80,90,100),
                         labels = c("0-10","11-20", "21-30", "31-40", "41-50", "51-60", "61-70", "71-80", "81-90", "91-100")
)

swap_values <- function(combined_data, swap_ratio, col_to_swap) {
  set.seed(123)  #set seed for reproducibility
  
  #number of rows to swap, based on the swap ratio
  num_rows <- nrow(combined_data)
  swap_count <- ceiling(num_rows * swap_ratio)  #calculate the number of rows
  
  #select random indices for swapping
  indices <- sample(1:num_rows, swap_count)  #randomly pick rows to swap
  
  #loop through each column and swap the selected rows
  for (item in col_to_swap) {
    swapped_column <- combined_data[[item]]
    swapped_column[indices] <- sample(swapped_column[indices])  #shuffle only selected rows
    combined_data[[item]] <- swapped_column  #update the column in the original data
  }
  
  return(combined_data)
}

#swap 15% of the values to the columns
swap_ratio <- 0.15
col_to_swap <- c("insurance", "gender", "race")  
combined_data <- swap_values(combined_data, swap_ratio, col_to_swap)

#apply salt
salt <- "random_salt_value"

#apply hashing on subject_id
combined_data$subject_id <- sapply(combined_data$subject_id, function(x) digest(paste0(x, salt), algo = "xxhash32"))

#apply hashing on hadm_id
combined_data$hadm_id <- sapply(combined_data$hadm_id, function(x) digest(paste0(x, salt), algo = "crc32"))

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
combined_data <- update_gender(combined_data, male_symptoms, female_symptoms)

#save the annonymized data
write.csv(combined_data, file = "anonymized_data.csv", row.names = FALSE)
