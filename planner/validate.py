#!/usr/bin/env python3
"""Validate the shared weekly-plan interchange format without changing it."""
import datetime as dt
import json
import sys
import uuid

ACTIVITIES = {'running','walking','traditionalStrengthTraining','functionalStrengthTraining','mindAndBody','golf'}

def validate(p):
    errors=[]
    def check(ok, message):
        if not ok: errors.append(message)
    if not isinstance(p,dict): return ['Payload must be an object']
    check(p.get('version') == 1, 'version must be 1')
    try: start=dt.date.fromisoformat(p.get('weekStart',''))
    except (ValueError,TypeError): start=None; errors.append('weekStart must be an ISO date')
    workouts=p.get('workouts')
    if not isinstance(workouts,list) or not workouts: return errors+['workouts must be a nonempty array']
    seen=set()
    for i,w in enumerate(workouts):
        pre=f'workout {i+1}'
        if not isinstance(w,dict): errors.append(pre+' must be an object'); continue
        try: ident=str(uuid.UUID(w.get('id','')))
        except (ValueError,TypeError,AttributeError): ident=None; errors.append(pre+' needs a UUID')
        if ident: check(ident not in seen,pre+' has a duplicate ID'); seen.add(ident)
        try:
            date=dt.date.fromisoformat(w.get('date',''))
            if start: check(0 <= (date-start).days < 7,pre+' date must be within the week')
        except (ValueError,TypeError): errors.append(pre+' needs a valid date')
        check(isinstance(w.get('title'),str) and bool(w['title'].strip()),pre+' needs a title')
        check(w.get('activity') in ACTIVITIES,pre+' has an unsupported activity')
        check(w.get('location') in {'indoor','outdoor','unknown'},pre+' has an invalid location')
        kind=w.get('kind'); check(kind in {'custom','single'},pre+' kind must be custom or single')
        steps=w.get('steps')
        if not isinstance(steps,list) or not steps: errors.append(pre+' needs steps'); continue
        if kind=='single': check(len(steps)==1,pre+' single goal must have one step')
        for j,s in enumerate(steps):
            label=f'{pre} step {j+1}'
            if not isinstance(s,dict): errors.append(label+' must be an object'); continue
            check(s.get('purpose') in {'warmup','work','recovery','cooldown'},label+' has an invalid purpose')
            check(isinstance(s.get('name'),str) and bool(s['name'].strip()),label+' needs a name')
            check(s.get('goal') in {'open','time'},label+' has an invalid goal')
            if s.get('goal')=='time': check(type(s.get('seconds')) in (int,float) and 0<s['seconds']<=86400,label+' needs positive seconds')
            if 'heartRateZone' in s: check(type(s['heartRateZone']) is int and 1<=s['heartRateZone']<=5 and kind=='custom',label+' has an invalid zone')
        if kind=='custom' and all(isinstance(s,dict) for s in steps):
            check(sum(s.get('purpose')=='warmup' for s in steps if isinstance(s,dict))<=1,pre+' has multiple warmups')
            check(sum(s.get('purpose')=='cooldown' for s in steps if isinstance(s,dict))<=1,pre+' has multiple cooldowns')
            last=steps[-1]
            seconds=last.get('seconds')
            check(last.get('purpose')=='cooldown' and last.get('goal')=='time' and type(seconds) in (int,float) and seconds>=180,pre+' needs a timed cooldown of at least 3 minutes')
            check(not any(s.get('purpose')=='warmup' for s in steps) or steps[0].get('purpose')=='warmup',pre+' warmup must be first')
            check(any(s.get('purpose') in {'work','recovery'} for s in steps),pre+' needs a work or recovery step')
    return errors

if __name__=='__main__':
    try:
        with open(sys.argv[1],encoding='utf-8') as f: payload=json.load(f)
        errors=validate(payload)
    except (OSError,ValueError,IndexError) as e: print(e,file=sys.stderr); sys.exit(2)
    if errors: print('\n'.join(errors),file=sys.stderr); sys.exit(1)
    print('Interchange structure validated; protocol and personal readiness require review.')
