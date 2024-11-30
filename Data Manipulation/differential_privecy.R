#install libraries
install.packages("tidyverse")
install.packages("data.table")
install.packages("diffpriv")

#load required libraries
library(tidyverse)
library(data.table)
library(diffpriv)

#load dataset
combined_data <- fread("combined_data.csv")

#LaPlace Mechaism
#function to apply laplace mechanism with differential privacy
laplace_mechanism <- function(col_name, epsilon, sensitivity) {
  
  #define the laplace mechanism with sensitivity and dimensions
  laPlace_Mechanism <- DPMechLaplace(sensitivity = sensitivity, dims = 1)
  
  # define the privacy parameters
  privacy_params <- DPParamsEps(epsilon = epsilon)
  
  #apply laplace mechanism to the column
  noisy_column <- sapply(col_name, function(x) {
    release <- releaseResponse(laPlace_Mechanism, privacyParams = privacy_params, X = x)
    noisy_value <- x + release$response
    return(round(noisy_value))  #round up the noisy value
  })
  
  return(noisy_column)
}

#function for the categorical values
categorical_noisy_values <- function(counts, original_values, col_labels) {
  noisy_values <- unlist(mapply(rep, col_labels, counts))
  
  total_records <- length(original_values)
  
  if (length(noisy_values) > total_records) {
    noisy_values <- noisy_values[1:total_records]  #remove some if there are too many values
  } else if (length(noisy_values) < total_records) {
    diff <- total_records - length(noisy_values)
    
    #find the most frequent value to fillup the gap
    most_frequent_value <- col_labels[which.max(counts)]
    noisy_values <- c(noisy_values, rep(most_frequent_value, diff))
  }
  
  #shuffle to randomize the noisy values
  noisy_values <- sample(noisy_values)
  
  return(noisy_values)
}

#male and female-specific health terms
female_symptoms <- c("vaginal", "uterine", "cesarean", "female", "abortion", "hysterotomy", "antepartum", "d&c", 
                     "breast", "postpartum", "mastectomy", "pelvic", "eclampsia", "uterus")
male_symptoms <- c("male", "transurethral", "penis", "urethral", "testes", "scrotal", "prostatectomy")

#function to apply differential privacy with gender assignment constraints
apply_dp_with_constraints <- function(gender, symptoms, diagnoses, procedures) {
  #convert gender to numeric for DP purposes: 1 for Male, 0 for Female
  gender_numeric <- ifelse(gender == "Male", 1, 0)
  
  #combine symptom, diagnosis, and procedure into a single string
  combined_text <- paste(symptoms, diagnoses, procedures, collapse = " ")
  
  #determine the gender for female specific health issues
  if (any(grepl(paste(female_symptoms, collapse = "|"), combined_text, ignore.case = TRUE))) {
    return("Female")  #assign F to female specific health issues
  } 
  #determine gender for male specific health issues
  else if (any(grepl(paste(male_symptoms, collapse = "|"), combined_text, ignore.case = TRUE))) {
    return("Male")  #assign M to male specific health issues 
  } 
  else {
    #apply laplace mechanism to the gender
    noisy_gender <- laplace_mechanism(gender_numeric, epsilon = 1.5, sensitivity = 1)
    
    #convert noisy numeric gender back to categorical: >= 0.5 becomes Male, else Female
    return(ifelse(noisy_gender >= 0.5, "Male", "Female"))
  }
}

#apply the function across the dataset
combined_data$gender <- mapply(apply_dp_with_constraints, 
                               combined_data$gender, 
                               combined_data$symptoms, 
                               combined_data$diagnoses, 
                               combined_data$procedures)


#for numerical data
combined_data$age <- laplace_mechanism(combined_data$age, epsilon = 0.4, sensitivity = 1)
combined_data$inpatient_duration <- pmax(laplace_mechanism(combined_data$inpatient_duration, epsilon = 2, sensitivity = 1),0) #hospital stay cant be negative value
combined_data$subject_id <- pmax(laplace_mechanism(combined_data$subject_id, epsilon = .001, sensitivity = 1), 10000000)
combined_data$hadm_id    <- laplace_mechanism(combined_data$hadm_id, epsilon = .001, sensitivity = 1)


#for categorical data
#apply on insurance 
medicaid_count <- sum(combined_data$insurance == "Medicaid")
private_count <- sum(combined_data$insurance == "Private")
medicare_count <- sum(combined_data$insurance == "Medicare")
other_count <- sum(combined_data$insurance == "Other")

noisy_medicaid_count <- laplace_mechanism(medicaid_count, epsilon = 1, sensitivity = 1)
noisy_private_count <- laplace_mechanism(private_count, epsilon = 1, sensitivity = 1)
noisy_medicare_count <- laplace_mechanism(medicare_count, epsilon = 1, sensitivity = 1)
noisy_other_count <- laplace_mechanism(other_count, epsilon = 1, sensitivity = 1)

combined_data$insurance <- categorical_noisy_values(
  counts = c(noisy_medicaid_count, noisy_private_count, noisy_medicare_count, noisy_other_count),
  original_values = combined_data$insurance,
  col_labels = c("Medicaid", "Private", "Medicare", "Other")
)

#apply on admission type
emergency_count <- sum(combined_data$admission_type == "Emergency")
elective_count <- sum(combined_data$admission_type == "Elective")
observation_count <- sum(combined_data$admission_type == "Observation")

noisy_emergency_count <- laplace_mechanism(emergency_count, epsilon = 1.5, sensitivity = 1)
noisy_elective_count <- laplace_mechanism(elective_count, epsilon = 1.5, sensitivity = 1)
noisy_observation_count <- laplace_mechanism(observation_count, epsilon = 1.5, sensitivity = 1)

combined_data$admission_type <- categorical_noisy_values(
  counts = c(noisy_emergency_count, noisy_elective_count, noisy_observation_count),
  original_values = combined_data$admission_type,
  col_labels = c("Emergency", "Elective", "Observation")
)

#save the DP dataset
write.csv(combined_data, file = "differential_privecy.csv", row.names = FALSE)
