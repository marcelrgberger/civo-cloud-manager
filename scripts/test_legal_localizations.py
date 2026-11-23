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

    def test_impressum_edit_month_translates_to_its_own_token(self):
        source, source_counts = normalize_dates("November 2026", "en")
        for language, text in (("de", "November 2026"), ("es", "noviembre de 2026")):
            translated, translated_counts = normalize_dates(text, language)
            self.assertEqual(source_counts, translated_counts)
            self.assertEqual(signature(source), signature(translated))
            self.assertEqual(signature(translated)["date_sequence"], ["DATE_E"])

    def test_stale_edit_month_fails(self):
        source, source_counts = normalize_dates("November 2026", "en")
        stale, stale_counts = normalize_dates("septiembre de 2026", "es")
        self.assertNotEqual(source_counts, stale_counts)
        self.assertNotEqual(signature(source), signature(stale))

    def test_unchanged_document_date_keeps_its_token(self):
        source, source_counts = normalize_dates("September 2026", "en")
        translated, translated_counts = normalize_dates("septembre 2026", "fr")
        self.assertEqual(source_counts, translated_counts)
        self.assertEqual(signature(source), signature(translated))
        self.assertEqual(signature(translated)["date_sequence"], ["DATE_A"])


if __name__ == "__main__":
    unittest.main()
