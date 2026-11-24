#!/usr/bin/env python3
"""Check legal translations; optionally verify the resources in a built .app."""

import argparse
from collections import Counter
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
LANGUAGES = ("en", "de", "es", "fr", "it", "nl", "pl", "pt", "zh-Hans", "ja", "ko", "ar", "hi", "id", "tr", "ru")
DOCUMENTS = (
    "AcceptableUsePolicy.md", "EULA.md", "Impressum.md", "PrivacyPolicy.md",
    "PushNotificationConsent.md", "TermsOfService.md", "TrademarkDisclaimer.md",
)
COMPANY_DATA = (
    "DigitalFreedom Global LLC", "30 N Gould St, Ste N", "Sheridan, WY 82801",
    "2026-002048530",
)
# The trader telephone number stays in store and platform accounts and is not
# published in the imprint (publication decision of the legal repository).
UNPUBLISHED_PHONE = re.compile(r"\+\s*1[\s.-]*307[\s.-]*451[\s.-]*0707")

# Dates are facts, not interchangeable digit bags. Normalize only these exact,
# reviewed dates; check both their counts and their sequence in the document.
# Order: document date, ODR closure, Belgian law, Italian decree, Impressum edit month,
# effective date of EULA and Terms of Service (with day), effective date of the
# Privacy Policy (with day; applied first because its month-year form is also the
# Impressum edit month).
# Other numerical facts still use multisets; those checks do not prove their order.
DATE_FORMS = {
    "en": (r"September 2026", r"20 July 2025", r"11 March 2003", r"9 aprile 2003", r"November 2026", r"10 December 2026", r"(?<!\d)8 November 2026"),
    "de": (r"September 2026", r"20\. Juli 2025", r"11\. März 2003", r"9 aprile 2003", r"November 2026", r"10\. Dezember 2026", r"(?<!\d)8\. November 2026"),
    "es": (r"septiembre de 2026", r"20 de julio de 2025", r"11 de marzo de 2003", r"9 de abril de 2003", r"noviembre de 2026", r"10 de diciembre de 2026", r"(?<!\d)8 de noviembre de 2026"),
    "fr": (r"septembre 2026", r"20 juillet 2025", r"11 mars 2003", r"9 avril 2003", r"novembre 2026", r"10 décembre 2026", r"(?<!\d)8 novembre 2026"),
    "it": (r"settembre 2026", r"20 luglio 2025", r"11 marzo 2003", r"9 aprile 2003", r"novembre 2026", r"10 dicembre 2026", r"(?<!\d)8 novembre 2026"),
    "nl": (r"september 2026", r"20 juli 2025", r"11 maart 2003", r"9 aprile 2003", r"november 2026", r"10 december 2026", r"(?<!\d)8 november 2026"),
    "pl": (r"wrzesień 2026", r"20 lipca 2025", r"11 marca 2003", r"9 aprile 2003", r"listopad 2026", r"10 grudnia 2026", r"(?<!\d)8 listopada 2026"),
    "pt": (r"setembro de 2026", r"20 de julho de 2025", r"11 de março de 2003", r"9 aprile 2003", r"novembro de 2026", r"10 de dezembro de 2026", r"(?<!\d)8 de novembro de 2026"),
    "zh-Hans": (r"2026年9月", r"2025年7月20日", r"2003年3月11日", r"2003年4月9日", r"2026年11月", r"2026年12月10日", r"2026年11月8日"),
    "ja": (r"2026年9月", r"2025年7月20日", r"2003年3月11日", r"2003年4月9日", r"2026年11月", r"2026年12月10日", r"2026年11月8日"),
    "ko": (r"2026년 9월", r"2025년 7월 20일", r"2003년 3월 11일", r"2003년 4월 9일", r"2026년 11월", r"2026년 12월 10일", r"2026년 11월 8일"),
    "ar": (r"سبتمبر 2026", r"20 يوليو 2025", r"11 مارس 2003", r"9 أبريل 2003", r"نوفمبر 2026", r"10 ديسمبر 2026", r"(?<!\d)8 نوفمبر 2026"),
    "hi": (r"सितंबर 2026", r"20 जुलाई 2025", r"11 मार्च 2003", r"9 अप्रैल 2003", r"नवंबर 2026", r"10 दिसंबर 2026", r"(?<!\d)8 नवंबर 2026"),
    "id": (r"September 2026", r"20 Juli 2025", r"11 Maret 2003", r"9 aprile 2003", r"November 2026", r"10 Desember 2026", r"(?<!\d)8 November 2026"),
    "tr": (r"Eylül 2026", r"20 Temmuz 2025", r"11 Mart 2003", r"9 Nisan 2003", r"Kasım 2026", r"10 Aralık 2026", r"(?<!\d)8 Kasım 2026"),
    "ru": (r"сентябрь 2026", r"20 июля 2025", r"11 марта 2003", r"9 апреля 2003", r"ноябрь 2026", r"10 декабря 2026", r"(?<!\d)8 ноября 2026"),
}


# Documents that carry their own date instead of the September 2026 document date:
# the Privacy Policy follows the effective date of the template revision it adopts.
DOCUMENT_DATES = {"PrivacyPolicy.md": {"DATE_A": 0, "DATE_G": 1}}
DEFAULT_DOCUMENT_DATES = {"DATE_G": 0}
APPLICATION_ORDER = (6, 0, 1, 2, 3, 4, 5)

# Vendors that never receive data of this app. Derived from docs/privacy-applicability.md
# (rows 15 to 17). Civo, Migadu and Storj are absent on purpose: the published helpdesk
# notice names them as recipients of support requests.
FORBIDDEN_VENDORS = (
    "OpenAI", "RevenueCat", "MailerLite", "Firebase", "Google Cloud", "Google Analytics",
    "Google Play", "Microsoft 365",
)
# Link targets LegalView routes to a tab: the bundled file names and their template-style
# upper-case names (`LegalDocument.documentForFilename`).
BUNDLED_TARGETS = frozenset(DOCUMENTS) | {
    "PRIVACY_POLICY.md", "TERMS_OF_SERVICE.md", "ACCEPTABLE_USE_POLICY.md",
    "PUSH_NOTIFICATION_CONSENT.md", "TRADEMARK_DISCLAIMER.md", "IMPRESSUM.md",
}
# Documents that this reconciliation owns. Other documents still link FAIR_USE_POLICY.md
# (see docs/privacy-applicability.md, follow-ups) and are not rewritten here.
LINK_GUARDED_DOCUMENTS = ("PrivacyPolicy.md", "PushNotificationConsent.md")
TYPOGRAPHIC = re.compile("[\u2013\u2014\u2018\u2019\u201c\u201d\u2026\U0001F300-\U0001FAFF\u2600-\u27BF]")


def normalize_dates(text, language):
    forms = DATE_FORMS[language]
    counts = [0] * len(forms)
    for index in APPLICATION_ORDER:
        text, counts[index] = re.subn(forms[index], f"DATE_{chr(65 + index)}", text, flags=re.I)
    return text, counts


def document_date_problems(name, counts):
    expected = DOCUMENT_DATES.get(name, DEFAULT_DOCUMENT_DATES)
    return [
        f"{token}: expected {want}, found {counts[ord(token[-1]) - 65]}"
        for token, want in expected.items() if counts[ord(token[-1]) - 65] != want
    ]


def find_forbidden_disclosures(text):
    return [vendor for vendor in FORBIDDEN_VENDORS if re.search(re.escape(vendor), text, re.I)]


def find_unbundled_links(text):
    targets = re.findall(r"\]\(([^)\s]+)\)", text)
    return [t for t in targets if not t.startswith(("http://", "https://", "mailto:", "#"))
            and t not in BUNDLED_TARGETS]


def find_typographic_characters(text):
    return TYPOGRAPHIC.findall(text)


def content(text):
    return re.sub(r"<!--.*?-->", "", text, flags=re.S).strip()


def signature(text):
    return {
        "date_sequence": re.findall(r"DATE_[A-G]", text),
        "headings": re.findall(r"^(#{1,6})\s+(\d+(?:\.\d+)*)?", text, re.M),
        "numbers": Counter(re.findall(r"\d+", text)),
        "links": Counter(re.findall(
            r"https?://[^\s<>`)]+|[\w.+-]+@[\w.-]+\.[A-Za-z]+|(?<=\]\()[^)]+", text
        )),
        "bullets": len(re.findall(r"^[-*] ", text, re.M)),
        "table_cells": text.count("|"),
        "company": {value: text.count(value) for value in COMPANY_DATA},
    }


NEW_ENGLISH_DOCUMENTS = ("PushNotificationConsent.md",)


def check_root_privacy():
    """The public PRIVACY.md must agree with the bundled English policy."""
    text = (ROOT / "PRIVACY.md").read_text()
    assert not find_forbidden_disclosures(text), "PRIVACY.md names a vendor not used by this app"
    assert not find_typographic_characters(text), "PRIVACY.md has typographic characters"
    bundled = (ROOT / "CivoCloudManager/en.lproj/PrivacyPolicy.md").read_text()
    bundled_date = re.search(r"\*\*Effective Date:\*\*\s*(.+)", bundled).group(1).strip()
    root_date = re.search(r"^Effective Date:\s*(.+)", text, re.M).group(1).strip()
    assert bundled_date == root_date, f"Effective Date differs: {bundled_date!r} vs {root_date!r}"
    updated = re.search(r"updated:\s*(\d{4})-(\d{2})-(\d{2})", bundled).groups()
    months = ("January", "February", "March", "April", "May", "June", "July", "August",
              "September", "October", "November", "December")
    expected = f"Last Updated: {months[int(updated[1]) - 1]} {int(updated[2])}, {updated[0]}"
    assert expected in text, f"PRIVACY.md must carry '{expected}'"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Built macOS .app to inspect")
    parser.add_argument("--language", choices=LANGUAGES, help="Check only this language (for translators)")
    parser.add_argument("--document", choices=DOCUMENTS, help="Check only this document (for translators)")
    args = parser.parse_args()
    checked = 0
    for name in ([args.document] if args.document else DOCUMENTS):
        source = content((ROOT / "CivoCloudManager/en.lproj" / name).read_text())
        for language in ([args.language] if args.language else LANGUAGES):
            path = ROOT / "CivoCloudManager" / f"{language}.lproj" / name
            raw = path.read_text()
            translated = content(raw)
            assert f"lang: {language} |" in raw.splitlines()[0], path
            assert translated and "DigitalFreedom Global LLC" in translated, path
            assert "{{" not in translated and "⟪KEEP" not in translated, path
            if name == "Impressum.md":
                assert not UNPUBLISHED_PHONE.search(translated), f"Unpublished contact data in {path}"
            normalized_source, source_dates = normalize_dates(source, "en")
            normalized_translation, translated_dates = normalize_dates(translated, language)
            assert source_dates == translated_dates, f"Critical date differs: {path}"
            assert not document_date_problems(name, translated_dates), f"Wrong document date: {path}"
            if name == "PrivacyPolicy.md":
                assert not find_forbidden_disclosures(translated), f"Vendor not used by this app: {path}"
            assert name not in LINK_GUARDED_DOCUMENTS or not find_unbundled_links(translated), f"Link to a document that is not bundled: {path}"
            if language == "en" and name in NEW_ENGLISH_DOCUMENTS:
                assert not find_typographic_characters(translated), f"Typographic characters: {path}"
            assert signature(normalized_source) == signature(normalized_translation), f"Content structure differs: {path}"
            if language != "en":
                assert translated != source, f"Untranslated document: {path}"
            if args.app:
                bundled = args.app / "Contents/Resources" / f"{language}.lproj" / name
                assert bundled.read_bytes() == path.read_bytes(), f"Missing or stale bundle resource: {bundled}"
            checked += 1
    if not (args.language or args.document):
        check_root_privacy()
    print(f"Validated {checked} legal documents in {len(set(LANGUAGES) if not args.language else {args.language})} languages."
          + (" Built app resources match." if args.app else ""))


if __name__ == "__main__":
    main()
