# Legal documents

The operating company is **DigitalFreedom Global LLC**, trading as DigitalFreedom,
30 N Gould St, Ste N, Sheridan, WY 82801, United States. The company details come
from the sibling `legal` repository at commit `0888197bdf40025bae517e2c90c81059d1f2d578`.

The September 2026 update applies that repository's provider identity, contact
details, governing law, jurisdiction and corporate-assignment provisions to the
existing app documents. The legal notice is taken from `website/IMPRESSUM.en.md`.
Each document's header records the relevant source and version; it does not claim
that unrelated template changes have been imported. Other product-specific terms
and disclosures retain their existing scope.

Seven documents ship in each of `en`, `de`, `es`, `fr`, `it`, `nl`, `pl` and `pt`.
English is the source for the complete translations. Country-specific sections,
numbered provisions, links and company details are retained in every language.
`LegalDocument` resolves the system's preferred languages, including regional
variants, and explicitly falls back to English for unsupported languages or
missing, empty or unreadable translations. Maintenance comments are not displayed.

The bundle identifier, StoreKit product identifier and Keychain service identifiers
remain stable to preserve the existing App Store product, purchases and credentials.
They are technical identifiers, not the displayed legal entity.

Run `python3 scripts/check_legal_localizations.py` to check the document set,
section numbering, numerical values, links and company details. Add
`--app '/path/to/Civo Cloud Manager.app'` to verify that all 56 documents are
actually included in the built app. Swift tests cover language resolution and
English fallback behavior.
