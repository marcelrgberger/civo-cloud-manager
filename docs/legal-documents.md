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
that unrelated template changes have been imported. The other six documents keep
their earlier source versions. Other product-specific terms and disclosures
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
section numbering, critical legal dates, numerical values, links and company details. Add
`--app '/path/to/Civo Cloud Manager.app'` to verify that all 112 documents are
actually included in the built app. Swift tests cover language resolution and
English fallback behavior.
