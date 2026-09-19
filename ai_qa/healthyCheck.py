import os
from dotenv import load_dotenv 
from google import genai

load_dotenv()

client = genai.Client()
#test
api_key = os.getenv("GEMINI_API_KEY")
model = os.getenv("GEMINI_MODEL")
if not api_key or not model:
    raise ValueError("GEMINI_API_KEY or GEMINI_MODEL is missing")

print(f"success API Key: {len(api_key)}")
print(f"success Model: {model}")
interaction = client.interactions.create(
    model=model,
    input="Hi, this is just a connectivity test."
)
print(interaction.output_text)