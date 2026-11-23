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
# effective date of EULA and Terms of Service (with day).
# Other numerical facts still use multisets; those checks do not prove their order.
DATE_FORMS = {
    "en": (r"September 2026", r"20 July 2025", r"11 March 2003", r"9 aprile 2003", r"November 2026", r"10 December 2026"),
    "de": (r"September 2026", r"20\. Juli 2025", r"11\. März 2003", r"9 aprile 2003", r"November 2026", r"10\. Dezember 2026"),
    "es": (r"septiembre de 2026", r"20 de julio de 2025", r"11 de marzo de 2003", r"9 de abril de 2003", r"noviembre de 2026", r"10 de diciembre de 2026"),
    "fr": (r"septembre 2026", r"20 juillet 2025", r"11 mars 2003", r"9 avril 2003", r"novembre 2026", r"10 décembre 2026"),
    "it": (r"settembre 2026", r"20 luglio 2025", r"11 marzo 2003", r"9 aprile 2003", r"novembre 2026", r"10 dicembre 2026"),
    "nl": (r"september 2026", r"20 juli 2025", r"11 maart 2003", r"9 aprile 2003", r"november 2026", r"10 december 2026"),
    "pl": (r"wrzesień 2026", r"20 lipca 2025", r"11 marca 2003", r"9 aprile 2003", r"listopad 2026", r"10 grudnia 2026"),
    "pt": (r"setembro de 2026", r"20 de julho de 2025", r"11 de março de 2003", r"9 aprile 2003", r"novembro de 2026", r"10 de dezembro de 2026"),
    "zh-Hans": (r"2026年9月", r"2025年7月20日", r"2003年3月11日", r"2003年4月9日", r"2026年11月", r"2026年12月10日"),
    "ja": (r"2026年9月", r"2025年7月20日", r"2003年3月11日", r"2003年4月9日", r"2026年11月", r"2026年12月10日"),
    "ko": (r"2026년 9월", r"2025년 7월 20일", r"2003년 3월 11일", r"2003년 4월 9일", r"2026년 11월", r"2026년 12월 10일"),
    "ar": (r"سبتمبر 2026", r"20 يوليو 2025", r"11 مارس 2003", r"9 أبريل 2003", r"نوفمبر 2026", r"10 ديسمبر 2026"),
    "hi": (r"सितंबर 2026", r"20 जुलाई 2025", r"11 मार्च 2003", r"9 अप्रैल 2003", r"नवंबर 2026", r"10 दिसंबर 2026"),
    "id": (r"September 2026", r"20 Juli 2025", r"11 Maret 2003", r"9 aprile 2003", r"November 2026", r"10 Desember 2026"),
    "tr": (r"Eylül 2026", r"20 Temmuz 2025", r"11 Mart 2003", r"9 Nisan 2003", r"Kasım 2026", r"10 Aralık 2026"),
    "ru": (r"сентябрь 2026", r"20 июля 2025", r"11 марта 2003", r"9 апреля 2003", r"ноябрь 2026", r"10 декабря 2026"),
}


def normalize_dates(text, language):
    counts = []
    for index, pattern in enumerate(DATE_FORMS[language]):
        text, count = re.subn(pattern, f"DATE_{chr(65 + index)}", text, flags=re.I)
        counts.append(count)
    return text, counts


def content(text):
    return re.sub(r"<!--.*?-->", "", text, flags=re.S).strip()


def signature(text):
    return {
        "date_sequence": re.findall(r"DATE_[A-F]", text),
        "headings": re.findall(r"^(#{1,6})\s+(\d+(?:\.\d+)*)?", text, re.M),
        "numbers": Counter(re.findall(r"\d+", text)),
        "links": Counter(re.findall(
            r"https?://[^\s<>`)]+|[\w.+-]+@[\w.-]+\.[A-Za-z]+|(?<=\]\()[^)]+", text
        )),
        "bullets": len(re.findall(r"^[-*] ", text, re.M)),
        "table_cells": text.count("|"),
        "company": {value: text.count(value) for value in COMPANY_DATA},
    }


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--app", type=Path, help="Built macOS .app to inspect")
    args = parser.parse_args()
    checked = 0
    for name in DOCUMENTS:
        source = content((ROOT / "CivoCloudManager/en.lproj" / name).read_text())
        for language in LANGUAGES:
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
            assert signature(normalized_source) == signature(normalized_translation), f"Content structure differs: {path}"
            if language != "en":
                assert translated != source, f"Untranslated document: {path}"
            if args.app:
                bundled = args.app / "Contents/Resources" / f"{language}.lproj" / name
                assert bundled.read_bytes() == path.read_bytes(), f"Missing or stale bundle resource: {bundled}"
            checked += 1
    print(f"Validated {checked} legal documents in {len(LANGUAGES)} languages."
          + (" Built app resources match." if args.app else ""))


if __name__ == "__main__":
    main()
