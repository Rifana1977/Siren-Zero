import json

with open('analyze.json', 'r', encoding='utf-8-sig') as f:
    text = f.read()

try:
    data = json.loads(text)
    errors = [d for d in data['diagnostics'] if d['severity'] == 'ERROR']
    for d in errors:
        print(f"{d['location']['file']}:{d['location']['range']['start']['line']} - {d['problemMessage']}")
    
    if not errors:
        print("NO COMPILATION ERRORS FOUND")
except Exception as e:
    print(f"Failed to parse JSON: {e}")
    print(text[:200])
