
!pip install datasets peft transformers trl bitsandbytes

import pandas as pd, torch
from transformers import AutoTokenizer, AutoModelForCausalLM, BitsAndBytesConfig, TrainingArguments
from datasets import DatasetDict, load_dataset
from peft import get_peft_model, LoraConfig
from trl import SFTTrainer


# BitsAndBytesConfig int-4 config
bnb_config = BitsAndBytesConfig(
    load_in_4bit=True, 
    bnb_4bit_use_double_quant=True, 
    bnb_4bit_quant_type="nf4", 
    bnb_4bit_compute_dtype=torch.bfloat16
)

# Loading the model
model_name = "meta-llama/Llama-3.2-3B-Instruct"
model = AutoModelForCausalLM.from_pretrained(
    model_name,
    quantization_config=bnb_config,
    device_map="auto"
) 
tokenizer = AutoTokenizer.from_pretrained(model_name)


# Apply Lora 
lora_config = LoraConfig(
    r = 16,               # Low-rank dimension
    lora_alpha = 32,     # Alpha Scaling factor
    lora_dropout = 0.1,  # Dropout for stability
    target_modules = ["q_proj","k_proj","v_proj","o_proj","gate_proj","up_proj","down_proj"],  # Apply LoRA to attention layers
    task_type = "CAUSAL_LM",
    bias = "none"
)
model = get_peft_model(model, lora_config)


# Load the dataset
dataset = load_dataset('csv', data_files='differential_privacy.csv')

# Split the dataset into training and testing sets
train_test = dataset['train'].train_test_split(test_size=0.2, seed=42)
train_dataset, test_dataset = train_test['train'], train_test['test']


# Add padding
tokenizer.pad_token = tokenizer.eos_token
model.config.pad_token_id = tokenizer.eos_token_id
tokenizer.padding_side = 'right' 

# Create input text 
def create_input_text(example):
  input_text = (
        f"<|begin_of_text|><|start_header_id|>system<|end_header_id|>"
        f"You are a helpful AI assistant for medical procedure prediction. "
        f"Remember, maintain a natural tone. Be precise, concise, and casual. Use only the procedures to generate answers. <|eot|>"
        
        f"<|start_header_id|>user<|end_header_id|>"
        f"Given the patient information: Age: {example['age']}, Gender: {example['gender']}, Symptoms: {example['symptoms']}, Diagnoses: {example['diagnoses']} <|eot|>"
        
        f"<|start_header_id|>assistant<|end_header_id|>"
        f" {example['procedures']}. <|eot|>"
        f"<|end_of_text|>"
    )
  return input_text

# Mapping the labels
train_dataset = train_dataset.map(lambda x: {'input_text': create_input_text(x)})
test_dataset = test_dataset.map(lambda x: {'input_text': create_input_text(x)})


# Tokenization function
def tokenize_function(examples):
    tokenized_inputs = tokenizer(
        examples['input_text'],
        padding='max_length',
        truncation=True,
        max_length=256
    )

    return tokenized_inputs


# Mapping the tokenizer
tokenized_train = train_dataset.map(tokenize_function, batched=True)
tokenized_test = test_dataset.map(tokenize_function, batched=True)


# Training arguments
training_args = TrainingArguments(
  output_dir = './results',            
  eval_strategy = "epoch",
  learning_rate = 2e-4,
  per_device_train_batch_size = 2,
  per_device_eval_batch_size = 2,
  num_train_epochs = 4,
  weight_decay = 0.01, 
  logging_dir = './logs',
  logging_steps = 200,
  save_total_limit = 3,
  prediction_loss_only = False,		
  report_to = "none",				
  do_train = True,				
  fp16 = True
)

trainer = SFTTrainer(
  model = model,
  args = training_args,
  train_dataset = tokenized_train,
  eval_dataset = tokenized_test,
  tokenizer = tokenizer,
)

# Train the model 
trainer.train()


# Inference (Generate predictions for new inputs)
def predict(input_text):
    # Tokenize the input text
    device = "cuda:0"
    
    inputs = tokenizer(input_text, return_tensors="pt", padding=True, truncation=True, max_length=256).to(device) #moving the model to the same device

# Generate predictions
    outputs = model.generate(
        input_ids=inputs["input_ids"],
        attention_mask=inputs["attention_mask"],
        eos_token_id=tokenizer.eos_token_id,    
        max_new_tokens=100,                        
        temperature = 0.8,                       
        top_p = 0.9,                            
        early_stopping=True,                    
        repetition_penalty = 1.3                
    )
    # Decode the generated text
    prediction = tokenizer.decode(outputs[0], skip_special_tokens=True)

    # Extract the procedure prediction
    procedure = prediction[len(input_text):].strip()  # Removing the input text portion
    return procedure


# Example usage with a new input row
example = {
  'age': 55, 
  'gender': 'Female', 
  'symptoms': 'chest pain, shortness of breath', 
  'diagnoses': 'hypertension, coronary artery disease',
  'procedures': ''
}

input_text= create_input_text(example)
# Generate the procedure prediction
predicted_procedure = predict(input_text)
print("Predicted Procedure:", predicted_procedure)