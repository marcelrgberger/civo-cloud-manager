"""Regression coverage for critical legal date validation."""

import unittest

from check_legal_localizations import normalize_dates, signature


class LegalDateValidationTests(unittest.TestCase):
    def test_translated_dates_preserve_signature(self):
        source, source_counts = normalize_dates("11 March 2003; 9 aprile 2003", "en")
        translated, translated_counts = normalize_dates("自2003年3月11日起; 自2003年4月9日起", "zh-Hans")
        self.assertEqual(source_counts, translated_counts)
        self.assertEqual(signature(source), signature(translated))

    def test_swapped_dates_fail_despite_identical_counts(self):
        source, source_counts = normalize_dates("11 March 2003; 9 aprile 2003", "en")
        swapped, swapped_counts = normalize_dates("2003年4月9日; 2003年3月11日", "zh-Hans")
        self.assertEqual(source_counts, swapped_counts)
        self.assertNotEqual(signature(source), signature(swapped))


if __name__ == "__main__":
    unittest.main()
