import copy
from pathlib import Path
import unittest
from native_synthetic import SyntheticLife
ROOT=Path(__file__).resolve().parents[1]

class LifeTests(unittest.TestCase):
    def test_unattended_pet_dies_without_a_single_frame_request(self):
        pet=SyntheticLife();pet.advance(24*60)
        self.assertEqual(pet.values['characterid'],12)
        self.assertGreater(pet.values['deathminute'],5)
        self.assertLess(pet.values['deathminute'],24*60)

    def test_repeated_minute_updates_equal_one_delayed_background_run(self):
        fine=SyntheticLife();coarse=SyntheticLife()
        for minute in range(1,24*60+1):fine.advance(minute)
        coarse.advance(24*60)
        self.assertEqual(fine.values,coarse.values)

    def test_refresh_does_not_age_or_reset_a_pet(self):
        pet=SyntheticLife();pet.advance(7);before=copy.deepcopy(pet.values)
        for _ in range(100):pet.advance(7)
        self.assertEqual(before,pet.values)
        pet.advance(3);self.assertEqual(before,pet.values)

    def test_new_invoice_after_death_cannot_resurrect_the_pet(self):
        pet=SyntheticLife();pet.advance(1440);death=pet.values['deathminute']
        for action in range(1,9):self.assertFalse(pet.care(action))
        self.assertEqual(pet.values['characterid'],12)
        self.assertEqual(pet.values['deathminute'],death)

    def test_heart_decay_accumulates_across_short_job_runs(self):
        pet=SyntheticLife();pet.advance(5)
        self.assertEqual(pet.values['hunger'],4)
        pet.advance(6);pet.advance(7);self.assertEqual(pet.values['hunger'],4)
        pet.advance(8);self.assertEqual(pet.values['hunger'],3)
        self.assertTrue(pet.care(1));self.assertEqual(pet.values['hunger'],4)

    def test_medicine_requires_the_documented_number_of_doses(self):
        pet=SyntheticLife();pet.advance(5);pet.call('startsick',[])
        self.assertFalse(pet.care(1))
        self.assertTrue(pet.care(4));self.assertTrue(pet.values['sick'])
        self.assertTrue(pet.care(4));self.assertFalse(pet.values['sick'])

    def test_sleep_pauses_hunger_but_is_independent_of_viewers(self):
        pet=SyntheticLife();pet.values['minutes']=5;pet.configure(2)
        pet.values['clockorigin']=20*60;pet.values['clockbaseminute']=5
        pet.advance(65)
        self.assertTrue(pet.values['sleeping']);self.assertEqual(pet.values['hunger'],4)
        self.assertEqual(pet.values['caremisses'],1) # ignored lights warning

    def test_cleaning_removes_poop_without_secretly_healing(self):
        pet=SyntheticLife();pet.advance(5);pet.values['poop']=4;pet.call('startsick',[])
        self.assertTrue(pet.care(2));self.assertEqual(pet.values['poop'],0)
        self.assertTrue(pet.values['sick'])

    def test_five_adult_care_mistakes_are_fatal(self):
        pet=SyntheticLife();pet.configure(5)
        for _ in range(4):pet.call('caremiss',[])
        self.assertEqual(pet.values['characterid'],5)
        pet.call('caremiss',[]);self.assertEqual(pet.values['characterid'],12)

    def test_primary_p1_rates_are_used_instead_of_the_inaccurate_open_clone(self):
        pet=SyntheticLife()
        self.assertEqual(pet.stats[1]['basehunger'],3)
        self.assertEqual(pet.stats[5]['basehunger'],81)
        self.assertEqual(pet.stats[7]['wakehour'],11)
        self.assertEqual(pet.stats[9]['shots'],3)

    def test_background_job_has_no_rolecenter_dependency_and_runs_all_week(self):
        source=(ROOT/'src/TamaJobs.Codeunit.al').read_text()
        self.assertIn('Engine.AdvanceThrough(CurrentDateTime(), true)',source)
        self.assertIn('"Run in User Session" := false',source)
        for day in ['Mondays','Tuesdays','Wednesdays','Thursdays','Fridays','Saturdays','Sundays']:
            self.assertIn('"Run on '+day+'" := true',source)
        self.assertNotIn('CurrPage',source)

if __name__=='__main__':unittest.main()
