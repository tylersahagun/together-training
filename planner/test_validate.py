import copy
import unittest
from validate import validate

class ValidationTests(unittest.TestCase):
    def setUp(self):
        self.plan={'version':1,'weekStart':'2026-11-16','workouts':[{'id':'dd3e8760-f455-4a26-a66c-c0e2c1455c00','date':'2026-11-16','title':'Run','activity':'running','location':'outdoor','kind':'custom','steps':[{'purpose':'work','name':'Easy','goal':'time','seconds':600},{'purpose':'cooldown','name':'Breathing','goal':'time','seconds':180}]}]}
    def test_valid(self): self.assertEqual(validate(self.plan),[])
    def test_missing_cooldown(self):
        self.plan['workouts'][0]['steps'].pop()
        self.assertTrue(any('cooldown' in e for e in validate(self.plan)))
    def test_duplicate_and_outside_week(self):
        self.plan['workouts'].append(copy.deepcopy(self.plan['workouts'][0]))
        self.plan['workouts'][1]['date']='2026-11-23'
        result=validate(self.plan)
        self.assertTrue(any('duplicate' in e for e in result))
        self.assertTrue(any('within the week' in e for e in result))
    def test_malformed_step_does_not_crash(self):
        self.plan['workouts'][0]['steps']=[None]
        self.assertTrue(validate(self.plan))
    def test_bad_duration_does_not_crash(self):
        self.plan['workouts'][0]['steps'][-1]['seconds']='long'
        self.assertTrue(validate(self.plan))

if __name__ == '__main__': unittest.main()
