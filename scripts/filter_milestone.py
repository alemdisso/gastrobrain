import json, sys

data = json.load(sys.stdin)
milestone_filter = sys.argv[1] if len(sys.argv) > 1 else '0.2.13'

items = [
    i for i in data['items']
    if isinstance(i.get('milestone'), dict) and milestone_filter in i['milestone'].get('title', '')
]

print(f'Found {len(items)} issues for {milestone_filter}')
for i in items:
    num = i['content']['number']
    title = i['title'][:70]
    est = i.get('estimate', '?')
    prio = i.get('priority', '?')
    status = i.get('status', '?')
    size = i.get('size', '?')
    labels = ', '.join(i.get('labels', []))
    print(f'  #{num} | {est}pts | {prio} | {size} | {status} | {title}')
    print(f'        labels: {labels}')
