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

    def test_eula_and_terms_date_with_day_translates_to_its_own_token(self):
        source, source_counts = normalize_dates("10 December 2026", "en")
        for language, text in (("de", "10. Dezember 2026"), ("ja", "2026年12月10日"), ("ru", "10 декабря 2026")):
            translated, translated_counts = normalize_dates(text, language)
            self.assertEqual(source_counts, translated_counts)
            self.assertEqual(signature(source), signature(translated))
            self.assertEqual(signature(translated)["date_sequence"], ["DATE_F"])

    def test_wrong_day_or_month_of_effective_date_fails(self):
        source, source_counts = normalize_dates("10 December 2026", "en")
        for text in ("11 December 2026", "10 November 2026", "10 September 2026"):
            wrong, wrong_counts = normalize_dates(text, "en")
            self.assertNotEqual(signature(source), signature(wrong), text)
            self.assertNotEqual(source_counts, wrong_counts, text)

    def test_document_date_of_the_other_group_fails(self):
        source, _ = normalize_dates("10 December 2026", "en")
        legacy, _ = normalize_dates("September 2026", "en")
        self.assertNotEqual(signature(source), signature(legacy))


if __name__ == "__main__":
    unittest.main()
