# Legal documents

The operating company is **DigitalFreedom Global LLC**, trading as DigitalFreedom,
30 N Gould St, Ste N, Sheridan, WY 82801, United States. The company details come
from the sibling `legal` repository at commit `0888197bdf40025bae517e2c90c81059d1f2d578`.

The September 2026 update applies that repository's provider identity, contact
details, governing law, jurisdiction and corporate-assignment provisions to the
existing app documents. The legal notice (`Impressum.md`) was reconciled in
November 2026 with `website/IMPRESSUM.en.md` version 1.5.1 (legal repository
commit `5f5179f30150d295a5669c63d5da61c58f9d3100`) and with the publication
decisions in its README (commit `64ff983b509633443daf888011db8bc441722578`).
Among other things it adds the contact form, the "Why is the provider a US LLC?"
link, the security contact points and the insurance statement, and its
section 10 names the listed provisions for orientation without asserting
compliance. The trader telephone number is deliberately not published in any
bundled or root document; the checker rejects it in `Impressum.md`. Each
document's header records the relevant source and version; it does not claim
that unrelated template changes have been imported. The EULA and the Terms of Service were reconciled in November 2026 with
`apps/documents/EULA.en.md` version 1.4.0 and `shared/TERMS_OF_SERVICE.en.md`
version 2.2.0 (legal repository commit `38869f57052d1d70ccface206e68ab46be0c3326`,
both valid from 10 December 2026, which is why both carry that effective date and
must not be released earlier). They add the paid-up licence protection, the Apple
App Store additional terms (EULA section 19), the Australia and New Zealand
wording and the reworked territorial and consumer clauses. They are adapted to
this app, which is distributed only through the Apple App Store and sold as one
non-consumable Full Access purchase after a seven-day free period: Subscription
Terms, Fair Use Policy, Refund Policy, Legal Framework Overview, Support and
Update Policy, the Children's Privacy Notice, the Google Play section and the
Apple Business seats module are not part of the app and are omitted; the
matching clauses are stated inline instead (Terms section 7). The prescribed
Australian Consumer Law notice stays in English in every language. The Privacy Policy was reconciled in November 2026 with
`shared/PRIVACY_POLICY.en.md` version 2.3.2 (valid from 8 November 2026, legal
repository commit `cc9c4543cf0ed58be97cd3c9d38fc86781b04680`), which is why it
carries 8 November 2026 as its effective date while the other documents keep
September 2026; versions 2.4.0 and 2.5.0 (both valid from 10 December 2026) are not
used. Which sentences are historical text, newly incorporated text or removed text,
and the evidence for every data flow, legal basis and recipient, are recorded in
[privacy-applicability.md](privacy-applicability.md). `PushNotificationConsent.md`
is a short notice for the local notifications the app really uses, because the app
has no push delivery. The remaining documents keep their earlier source versions. Other product-specific terms and disclosures
retain their existing scope.

Seven documents ship in each of the 16 languages: `en`, `de`, `es`, `fr`, `it`,
`nl`, `pl`, `pt`, `zh-Hans`, `ja`, `ko`, `ar`, `hi`, `id`, `tr` and `ru`.
English is the source for the complete translations. Country-specific sections,
numbered provisions, links and company details are retained in every language.
`LegalDocument` resolves the system's preferred languages, including regional
variants, and explicitly falls back to English for unsupported languages or
missing, empty or unreadable translations. Maintenance comments are not displayed.

The bundle identifier, StoreKit product identifier and Keychain service identifiers
remain stable to preserve the existing App Store product, purchases and credentials.
They are technical identifiers, not the displayed legal entity.

Run `python3 scripts/check_legal_localizations.py` to check the document set,
section numbering, critical legal dates (including the effective dates of the EULA, the Terms of Service
and the Privacy Policy, which differ), vendors that never receive data of this app,
relative links to documents that are not bundled, numerical values, links and company details. Add
`--app '/path/to/Civo Cloud Manager.app'` to verify that all 112 documents are
actually included in the built app. Swift tests cover language resolution and
English fallback behavior.
