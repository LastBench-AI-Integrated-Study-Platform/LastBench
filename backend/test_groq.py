from groq import Groq

api_key = "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"

try:
    client = Groq(api_key=api_key)
    
    response = client.chat.completions.create(
        messages=[{"role": "user", "content": "Hello"}],
        model="llama-3.3-70b-versatile",
        max_tokens=10
    )
    
    print("✅ API Key is VALID!")
    print(f"Response: {response.choices[0].message.content}")
    
except Exception as e:
    print("❌ API Key is INVALID!")
    print(f"Error: {e}")