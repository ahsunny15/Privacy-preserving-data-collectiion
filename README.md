# Privacy Preserving Data Collection for Generative AI

  The objective of this research is to evaluate comprehensive privacy-preserving techniques such as differential privacy, data anonymization, and synthetic data generation for effectively and securely training generative AI models in a healthcare ecosystem.

The goal of this research is to determine how privacy-preserving techniques can be effectively implemented in the data collection and training processes of generative AI models used in healthcare, ensuring effective data privacy while maintaining data utility and scalability. The specific research questions are: 

1. How effective are the privacy-preserving techniques (differential privacy, data anonymization, and synthetic data generation) in minimizing data leakage and re-identification risks during the training of generative AI models on healthcare data?

2. What is the impact of implementing privacy-preserving techniques on the data utility of healthcare datasets, as measured by the Perplexity, ROUGE scores, and Human Evaluation of AI models trained on privacy-preserved healthcare datasets?.

3. How scalable and computationally efficient are the implemented privacy-preserving techniques in the context of real-world healthcare AI applications?<br>


<h2> Methodology</h2>
This study followed a structured pipeline to ensure the development of a privacy-preserving AI model for generating treatment recommendations based on clinical data. The methodology consists of the following key stages:<br>


1. Dataset Selection:
The publicly available MIMIC-IV database (version 3.1) was selected for this study. This dataset includes de-identified health records from ICU admissions, offering a comprehensive source of patient information suitable for clinical modeling tasks.<br>


2. Dataset Preprocessing:
Preprocessing steps were applied to ensure data quality and consistency. These included:

      <h4>&#8226;      Removal of irrelevant columns</h4>
      <h4>&#8226;      Standardization of text fields such as diagnoses and procedures</h4>
      <h4>&#8226;      De-duplication of patient records</h4>
      <h4>&#8226;      Feature engineering, including calculation of inpatient duration and transformation of categorical variables</h4><br>


3. Applying Privacy-Preserving Techniques
To safeguard patient privacy, three independent privacy-preserving techniques were applied to the dataset:

      <h4>&#8226;  Differential Privacy: Calibrated noise was added to sensitive attributes using the Laplace mechanism to provide formal privacy guarantees.</h4>
      <h4>&#8226;  Data Anonymization: Identifiable attributes were obscured using generalization, value swapping, and salted hashing techniques to reduce the risk of re-identification.</h4>
      <h4>&#8226;  Synthetic Data Generation: Bayesian Networks were used to generate synthetic datasets that preserve statistical relationships found in the original data while ensuring no real patient data were exposed.</h4><br>

4. Model Training
Each processed dataset was independently used to fine-tune the LLaMA-3.1-8B-Instruct model. The LoRA (Low-Rank Adaptation) technique was employed to efficiently adapt the model for the task of generating treatment recommendations based on patient features.<br>

5. Model Evaluation
To evaluate both the privacy and utility of the trained models, several metrics and approaches were applied:

      <h4>&#8226;  Membership Inference Attacks to assess vulnerability to data leakage</h4>
      <h4>&#8226;  ROUGE scores to measure the relevance and quality of the generated text</h4>
      <h4>&#8226;  Perplexity to evaluate the model’s predictive performance</h4>
      <h4>&#8226;  Human Evaluation to assess the clinical coherence and usefulness of the generated treatment recommendations</h4><br>

<h2>Findings</h2>
<h3>Membership Inference Attack</h3>

![MIA](https://github.com/user-attachments/assets/8131ff6a-ca12-4e33-9382-73a88b00c811)<br><br>
Differential Privacy and Synthetic Data generation provide strong defenses against privacy breaches. In contrast, Anonymized Data, while useful for certain applications, poses a higher risk of membership inference due to deterministic generalization and swapping techniques.

<h3>Perplexity Score</h3>

<img width="600" height="300" alt="perplexity_scores" src="https://github.com/user-attachments/assets/e424425a-43f1-45d0-8779-cf7851e933ff" /><br><br>
The base perplexity score was 30.65 before model training. The improvement from 30.65 to approximately 1.41–1.46 indicates that all privacy-preserving techniques retained enough statistical structure for the model to learn effectively.

<h3>ROUGE Score</h3>

<img width="600" height="300" alt="rouge_scores" src="https://github.com/user-attachments/assets/dce1dfaa-3e26-4819-a47b-d340ceed3183" /><br><br>
Both Differential Privacy and Synthetic Data proved their capacity to preserve linguistic coherence in the process of ensuring privacy, Anonymization technique showed that it is still effective in retaining structural and semantic relationships.

<h3>Human Evaluation Score</h3>

<img width="600" height="500" alt="radar_chart" src="https://github.com/user-attachments/assets/5a564322-299a-4a10-b2be-2a51784788b1" /><br><br>
Differential Privacy stands out as the optimal approach, delivering outputs that are both private and useful for downstream applications. Synthetic Data presents a viable alternative with moderate performance, while Anonymized Data demonstrates the need for more optimized methods to improve output quality.<br>

<h2>Conclusion</h2>

 Differential Privacy and Synthetic Data Generation achieved the highest levels of privacy preservation, as evidenced by lower attack success rates in membership inference attacks. 

 Differential Privacy delivered the best balance between privacy and data utility, as seen in its low perplexity and ROUGE scores, superior evaluation loss, and strong human evaluation results. 

 Anonymization, while useful in reducing identifiable information, was less effective in both privacy protection and data utility due to the deterministic distortions introduced by generalization and value swapping. 

The study validates that Differential Privacy is the most effective technique for balancing privacy and utility in healthcare datasets, followed by Synthetic Data Generation. Anonymization needs substantial developments to match the effectiveness of the other techniques.
