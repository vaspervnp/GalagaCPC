import json

transcript_path = r'C:\Users\vasilhs\.gemini\antigravity-ide\brain\b5957d56-ee62-42e4-b282-094597d20fbf\.system_generated\logs\transcript.jsonl'
with open(transcript_path, 'r', encoding='utf-8', errors='ignore') as f:
    for i, line in enumerate(f):
        data = json.loads(line)
        if data.get('type') == 'USER_INPUT':
            step = data.get('step_index')
            content = data.get('content', '')
            print(f"Step {step} (line {i}): {repr(content)[:120]}")
