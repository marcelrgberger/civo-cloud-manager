"""Regression coverage for critical legal date validation."""

import unittest

from check_legal_localizations import (
    document_date_problems, find_forbidden_disclosures, find_typographic_characters,
    find_unbundled_links, normalize_dates, signature,
)


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


class PolicyEffectiveDateTests(unittest.TestCase):
    def test_policy_effective_date_translates_to_its_own_token(self):
        source, source_counts = normalize_dates("8 November 2026", "en")
        for language, text in (("de", "8. November 2026"), ("es", "8 de noviembre de 2026"),
                               ("ja", "2026年11月8日"), ("ru", "8 ноября 2026")):
            translated, translated_counts = normalize_dates(text, language)
            self.assertEqual(source_counts, translated_counts, language)
            self.assertEqual(signature(source), signature(translated), language)
            self.assertEqual(signature(translated)["date_sequence"], ["DATE_G"], language)

    def test_policy_effective_date_is_not_taken_for_the_impressum_month(self):
        _, counts = normalize_dates("8 November 2026", "en")
        self.assertEqual(counts[4], 0)

    def test_wrong_day_of_policy_effective_date_fails(self):
        source, _ = normalize_dates("8 November 2026", "en")
        for text in ("18 November 2026", "9 November 2026", "8 December 2026"):
            wrong, _ = normalize_dates(text, "en")
            self.assertNotEqual(signature(source), signature(wrong), text)

    def test_policy_carries_exactly_its_own_date(self):
        _, counts = normalize_dates("Effective Date: 8 November 2026", "en")
        self.assertEqual(document_date_problems("PrivacyPolicy.md", counts), [])

    def test_policy_with_the_old_document_date_fails(self):
        _, counts = normalize_dates("Effective Date: September 2026", "en")
        self.assertTrue(document_date_problems("PrivacyPolicy.md", counts))

    def test_policy_with_a_missing_or_doubled_date_fails(self):
        for text in ("no date", "8 November 2026 and 8 November 2026"):
            _, counts = normalize_dates(text, "en")
            self.assertTrue(document_date_problems("PrivacyPolicy.md", counts), text)

    def test_other_documents_keep_the_september_date(self):
        _, counts = normalize_dates("Effective Date: September 2026", "en")
        self.assertEqual(document_date_problems("TermsOfService.md", counts), [])
        _, counts = normalize_dates("Effective Date: 8 November 2026", "en")
        self.assertTrue(document_date_problems("TermsOfService.md", counts))


class ForbiddenDisclosureTests(unittest.TestCase):
    def test_affirmative_vendor_row_fails(self):
        row = "| OpenAI Ireland Ltd. | OpenAI API Services | Ireland |"
        self.assertEqual(find_forbidden_disclosures(row), ["OpenAI"])

    def test_vendor_names_are_found_case_insensitively(self):
        self.assertIn("RevenueCat", find_forbidden_disclosures("receipts go to revenuecat, inc."))

    def test_text_without_these_vendors_passes(self):
        text = "The app calls api.civo.com. It uses no APNs token and no push service."
        self.assertEqual(find_forbidden_disclosures(text), [])


class BundledLinkTests(unittest.TestCase):
    def test_relative_link_to_a_missing_document_fails(self):
        self.assertEqual(find_unbundled_links("See the [Cookie Policy](../website/COOKIE_POLICY.en.md)."),
                         ["../website/COOKIE_POLICY.en.md"])
        self.assertEqual(find_unbundled_links("[Fair Use](FAIR_USE_POLICY.en.md)"), ["FAIR_USE_POLICY.en.md"])

    def test_link_to_a_bundled_document_passes(self):
        self.assertEqual(find_unbundled_links("[Terms](TermsOfService.md) and [Imprint](Impressum.md)"), [])

    def test_template_style_names_that_the_app_routes_pass(self):
        self.assertEqual(find_unbundled_links("[Privacy Policy](PRIVACY_POLICY.md) [Imprint](IMPRESSUM.md)"), [])

    def test_web_links_are_not_relative_links(self):
        self.assertEqual(find_unbundled_links("[Civo](https://www.civo.com/privacy)"), [])


class TypographyTests(unittest.TestCase):
    def test_typographic_characters_are_reported(self):
        self.assertEqual(find_typographic_characters("a \u2014 b \u201cquoted\u201d\u2026"), ["\u2014", "\u201c", "\u201d", "\u2026"])

    def test_plain_ascii_punctuation_passes(self):
        self.assertEqual(find_typographic_characters('a - b "quoted"...'), [])


if __name__ == "__main__":
    unittest.main()
