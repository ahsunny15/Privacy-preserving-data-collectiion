# Privacy Preserving Data Collection for Generative AI

  The objective of this research is to evaluate comprehensive privacy-preserving techniques such as differential privacy, data anonymization, and synthetic data generation for effectively and securely training generative AI models in a healthcare ecosystem.

The goal of this research is to determine how privacy-preserving techniques can be effectively implemented in the data collection and training processes of generative AI models used in healthcare, ensuring effective data privacy while maintaining data utility and scalability. The specific research questions are: 

1. How effective are the privacy-preserving techniques (differential privacy, data anonymization, and synthetic data generation) in minimizing data leakage and re-identification risks during the training of generative AI models on healthcare data?

2. What is the impact of implementing privacy-preserving techniques on the data utility of healthcare datasets, as measured by the Perplexity, ROUGE scores, and Human Evaluation of AI models trained on privacy-preserved healthcare datasets?.

3. How scalable and computationally efficient are the implemented privacy-preserving techniques in the context of real-world healthcare AI applications?


<h2> Methodology</h2>
This study followed a structured pipeline to ensure the development of a privacy-preserving AI model for generating treatment recommendations based on clinical data. The methodology consists of the following key stages:


1. Dataset Selection:
The publicly available MIMIC-IV database (version 3.1) was selected for this study. This dataset includes de-identified health records from ICU admissions, offering a comprehensive source of patient information suitable for clinical modeling tasks.


2. Dataset Preprocessing:
Preprocessing steps were applied to ensure data quality and consistency. These included:

      <h4>&#8226;  Removal of irrelevant columns</h4>
      <h4>&#8226;  Standardization of text fields such as diagnoses and procedures</h4>
      <h4>&#8226;  De-duplication of patient records</h4>
      <h4>&#8226;  Feature engineering, including calculation of inpatient duration and transformation of categorical variables</h4>


3. Applying Privacy-Preserving Techniques
To safeguard patient privacy, three independent privacy-preserving techniques were applied to the dataset:

      <h4>&#8226;  Differential Privacy: Calibrated noise was added to sensitive attributes using the Laplace mechanism to provide formal privacy guarantees.</h4>
      <h4>&#8226;  Data Anonymization: Identifiable attributes were obscured using generalization, value swapping, and salted hashing techniques to reduce the risk of re-identification.</h4>
      <h4>&#8226;  Synthetic Data Generation: Bayesian Networks were used to generate synthetic datasets that preserve statistical relationships found in the original data while ensuring no real patient data were exposed.</h4>

4. Model Training
Each processed dataset was independently used to fine-tune the LLaMA-3.1-8B-Instruct model. The LoRA (Low-Rank Adaptation) technique was employed to efficiently adapt the model for the task of generating treatment recommendations based on patient features.

5. Model Evaluation
To evaluate both the privacy and utility of the trained models, several metrics and approaches were applied:

      <h4>&#8226;  Membership Inference Attacks to assess vulnerability to data leakage</h4>
      <h4>&#8226;  ROUGE scores to measure the relevance and quality of the generated text</h4>
      <h4>&#8226;  Perplexity to evaluate the model’s predictive performance</h4>
      <h4>&#8226;  Human Evaluation to assess the clinical coherence and usefulness of the generated treatment recommendations</h4>
