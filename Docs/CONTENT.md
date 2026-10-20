# Nana — Curriculum and Content Guide

Status: **Draft v1, pending medical review.** Last updated 2026-10-20.

Content files:
- `Nana/Resources/Content/en/curriculum.json` — the Essential (MVP) lessons, full content
- `Nana/Resources/Content/en/sources.json` — every source the lessons cite

---

## 1. Purpose

Nana teaches young adults (18–25) in Bali and the rest of Indonesia the sexual-health facts they need to protect themselves and their partners. It does this through ~1-minute daily lessons, paired with a discreet condom container. Many users had little reliable sex education, because the topic is taboo locally and myths are common (see §7).

This document is for the product team and for medical, cultural and legal reviewers. It explains:
- what we teach and why,
- where every fact comes from,
- how we decided the number of lessons (we did not guess a number),
- what still needs to be checked locally before launch.

## 2. What we did, and why

1. **Collected authoritative sources** (§3). We opened and read every source we cite. When a page could not be opened, we did not cite it (§11).
2. **Built a topic inventory** across 7 tracks, using the UNESCO *International Technical Guidance on Sexuality Education* (ITGSE, 2018) as the backbone. Its 15–18+ learning objectives, mainly in Key Concepts 4, 5 and 8, are the closest match to our 18–25 audience.
3. **Tagged every topic** Essential, Good to know, or Expert, using the written criteria in §4. Each tag has a one-line reason.
4. **Chunked the Essential topics into lessons.** A lesson is 2–4 short cards plus exactly 1 quick-check question, about 1 minute in total. One lesson covers one action or one idea. The Essential tier is the MVP.
5. **Wrote full content for all 27 Essential lessons.** Good-to-know and Expert topics are listed here with their scope and intended sources only.
6. **Localized only where we had a source.** Wherever a local fact is not confirmed, the lesson has a `localNote`, and §9 lists them all.
7. **Validated the JSON** with a script. It checks that the JSON is valid, ids are unique kebab-case, there are 2–4 cards and 2–4 options, `answerIndex` is valid, headlines are ≤ 60 characters, bodies are ≤ 280 characters, every `sourceId` exists, and order numbers are continuous within each track.

## 3. Source hierarchy and inclusion rules

**Hierarchy** (when sources disagree, the higher one wins):
1. UN normative guidance: WHO fact sheets and guidelines, UNAIDS, UNESCO ITGSE.
2. National health agencies: Kemenkes RI (Indonesia's Ministry of Health), CDC (US), NHS (UK), US state health departments.
3. Peer-reviewed research: the global condom-error review, and Indonesian or Balinese survey studies.
4. Reputable news reports that quote Kemenkes officials. We used these **only** for Indonesian service facts, because we could not open any primary Kemenkes page (§11). Every claim from this tier carries a `localNote`.

**Inclusion rules:**
- We cite only sources we actually opened (accessed 2026-10-20).
- We give numbers only when a source states them, and we name the source in the card's `statCaption`.
- No absolute claims. Condoms "greatly lower risk"; they do not "prevent" every infection.
- No dosing instructions for any medicine (PEP, PrEP, EC, antibiotics). Lessons send users to a health worker.
- PEP is always described with WHO's timing: "as soon as possible, ideally within 24 hours, no later than 72 hours", plus "go to a clinic or emergency service".
- We do not invent local facts. When something is not sourced, we leave it out or flag it.

## 4. Tiering criteria

| Tier | A topic is in this tier if it meets **at least one** of these | Ships |
|---|---|---|
| **Essential** | **E1** It directly prevents HIV/STI transmission or unintended pregnancy. **E2** It prevents a common harmful error or a harmful belief (a myth that leads to unprotected sex or to avoiding care). **E3** It is needed to seek care in time (time-critical windows, where to go, what to ask for). **E4** It prevents harm to another person (consent). | MVP, full content |
| **Good to know** | It improves understanding, confidence or wellbeing, but it is not the immediate protective step. Or it is protective but mostly delivered by health systems (for example, childhood vaccines), or it applies to a smaller subgroup. | Post-MVP, listed here |
| **Expert** | It is specialist, clinical or legal detail. It changes often, needs professional judgement, or could cause harm if simplified (for example, regimens, resistance, the legal process). | Not planned for in-app lessons. Referral or deep-dive only |

Rule for edge cases: if a topic is protective but the user's action is only "ask a health worker" and local availability is unclear, it stays Essential when the time window is short (PEP, EC). Otherwise it is Good to know (for example, HPV vaccine catch-up).

## 5. Curriculum map

### 5.1 Lesson counts per tier

| Track | ITGSE mapping | Essential | Good to know | Expert |
|---|---|---|---|---|
| protection — Protection | KC 8.1, 8.3 (condom steps, correct and consistent use) | 6 | 5 | 1 |
| stis — STIs | KC 8.3 | 4 | 5 | 2 |
| hiv — HIV | KC 8.2, 8.3 | 4 | 4 | 2 |
| testing — Testing and care | KC 8.3, 5.5 (finding help) | 3 | 3 | 1 |
| consent — Consent and relationships | KC 4.2, 4.1, 5.3, 1.2 | 4 | 5 | 1 |
| body — Body and health | KC 6.1, 6.2, 8.1, 2.3 | 2 | 6 | 1 |
| myths — Myths and stigma | KC 8.2, 2.3, 5.4 | 4 | 3 | 0 |
| **Total** | | **27** | **31** | **8** |

### 5.2 How the count of 27 was derived

The count was not set in advance. It came from these steps:
1. We listed every topic in the ITGSE 15–18+ objectives for KC 4, 5 and 8, plus the related KC 1, 2 and 6 objectives. We added the topics our sources showed are high-risk errors or local myths (Sanders 2012; Wirawan 2022; KPAP 2007). This gave 66 topics.
2. We tagged each topic with §4's criteria. 27 met E1–E4.
3. We sized each Essential topic. A topic became one lesson if it fits in 3 cards of ≤ 280 characters each plus one check. We merged topics that share one action: "taking it off" went into "putting it on", and "one condom at a time" went into "lube". We split topics that contain two separate actions: PEP and EC each have their own lesson, and there is also a combined "if it breaks" lesson for the moment of crisis.
4. Result: 27 Essential topics became 27 lessons (1:1 after merging and splitting). Every Essential lesson has 3 cards.

At one lesson per day, the MVP takes about 4 weeks.

### 5.3 Essential lessons (MVP, full content in curriculum.json)

Each row gives the criterion that made the lesson Essential, the one-line reason, and its sources (ids from sources.json).

**Protection**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | protection-what-condoms-do | E1: Condoms are the only single method with "triple protection". Correct use is what makes them work (98% vs 82% for pregnancy). | who-condoms-qa-2022, nhs-condoms-2024, cdc-condom-brief-2024, who-sti-factsheet-2025 |
| 2 | protection-correct-use | E1/E2: ITGSE asks learners to "demonstrate the steps for correct condom use". CDC gives the on/off steps. | cdc-condom-external-2024, nhs-condoms-2024, sanders-condom-errors-2012, unesco-itgse-2018 |
| 3 | protection-common-mistakes | E2: The global review (50 studies, 14 countries) found errors are common worldwide. Late use, no space at the tip and upside-down use are more common than breakage. | sanders-condom-errors-2012, cdc-condom-external-2024 |
| 4 | protection-lube-and-doubling | E2: Oil-based products break latex. Doubling up causes splits. WHO, CDC and NHS all agree. | who-condoms-qa-2022, cdc-condom-external-2024, cdc-condom-use-2024, nhs-condoms-2024 |
| 5 | protection-storage-heat | E2: Heat and friction damage condoms (CDC). Store below 40°C, out of direct sun (MDH). This is very relevant in tropical Bali, and for a product that stores condoms. | cdc-condom-external-2024, mdh-condom-storage-2017, nhs-condoms-2024, who-condoms-qa-2022 |
| 6 | protection-if-it-breaks | E3: The PEP window (72 h) and the EC window (120 h) are time-critical. NHS advises urgent help. | who-pep-guidelines-2024, cdc-pep-2024, who-ec-factsheet-2021, nhs-condoms-2024, nhs-stis-2024 |

**STIs**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | stis-what-they-are | E1/E3: There are 1 million+ curable STIs per day worldwide. Knowing that most are curable encourages care. | who-sti-factsheet-2025 |
| 2 | stis-no-symptoms | E3: "STIs are often asymptomatic" (WHO). Waiting for symptoms is the main reason people do not test. | who-sti-factsheet-2025, nhs-stis-2024 |
| 3 | stis-how-they-spread | E1: Oral sex and skin-to-skin spread (herpes, HPV, syphilis) set real expectations about what condoms can do. | who-sti-factsheet-2025, who-hsv-factsheet-2025, who-hpv-factsheet-2024 |
| 4 | stis-getting-treated | E3: WHO reports gonorrhoea resistance and the importance of partner treatment. NHS says no sex until treatment is complete. | who-sti-factsheet-2025, nhs-stis-2024 |

**HIV**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | hiv-how-it-spreads | E1/E2: Correct routes, plus the non-routes that drive stigma. | who-hiv-factsheet-2026, cdc-hiv-causes-2024 |
| 2 | hiv-treatment-uu | E1: Undetectable = untransmittable (UNAIDS, WHO). Free ARV in Indonesia (flagged). | unaids-uu-2018, who-hiv-factsheet-2026, who-sti-factsheet-2025, antara-kemenkes-hiv-free-2023 |
| 3 | hiv-pep | E3: Time-critical. Start as soon as possible, ≤ 72 h (WHO 2024). Required by the brief. | who-pep-guidelines-2024, cdc-pep-2024, unesco-itgse-2018 |
| 4 | hiv-prep | E1: A WHO-recommended prevention method (several forms). ITGSE asks learners to define PrEP "if locally available". Local availability is flagged. | who-hiv-factsheet-2026, who-condoms-qa-2022, unesco-itgse-2018 |

**Testing and care**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | testing-why-test | E3: "Testing is the only way to know" (ITGSE). The right to voluntary, confidential testing. | unesco-itgse-2018, who-sti-factsheet-2025, nhs-stis-2024, who-hiv-factsheet-2026 |
| 2 | testing-timing-results | E3: WHO says retest after 28 days following a recent exposure, and a positive result needs a confirmation test. NHS says some STIs take up to 7 weeks to show. | who-hiv-factsheet-2026, nhs-stis-2024 |
| 3 | testing-where-to-go | E3: Users need to know where to go. Puskesmas offer free HIV tests (Kemenkes, via news reports; flagged). | detik-kemenkes-hiv-test-2018, antara-kemenkes-hiv-free-2023, suarasurabaya-kemenkes-testing-2026, unesco-itgse-2018 |

**Consent and relationships**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | consent-what-it-is | E4: ITGSE 4.2. Consent can be revoked "at any point". | unesco-itgse-2018, who-vaw-factsheet-2026 |
| 2 | consent-when-not-possible | E4: ITGSE lists alcohol, drugs, power, poverty and GBV as factors that affect consent. | unesco-itgse-2018, who-vaw-factsheet-2026 |
| 3 | consent-talking-about-protection | E1: ITGSE 8.3 calls for negotiation and refusal skills for safer sex. Condom use is "the responsibility of both". | unesco-itgse-2018 |
| 4 | consent-if-something-happened | E3/E4: Survivors need PEP and EC within their windows. WHO says violence leads to STIs, HIV and unintended pregnancy. | who-vaw-factsheet-2026, who-pep-guidelines-2024, who-ec-factsheet-2021 |

**Body and health**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | body-preventing-pregnancy | E1: Dual protection. Condom effectiveness numbers. Both partners are responsible (ITGSE 8.1). | who-fp-factsheet-2025, nhs-condoms-2024, unesco-itgse-2018 |
| 2 | body-emergency-contraception | E3: The 5-day window, sooner is better, and EC is not abortion (WHO). | who-ec-factsheet-2021, unesco-itgse-2018 |

**Myths and stigma**
| # | id | Criterion: reason | Sources |
|---|---|---|---|
| 1 | myths-you-can-tell | E2: Only 14.1% of unmarried Indonesians aged 15–25 had comprehensive HIV knowledge (IDHS 2017). | wirawan-jpmph-2022, who-sti-factsheet-2025, unesco-itgse-2018 |
| 2 | myths-condoms-have-holes | E2: A documented Indonesian myth (KPAP Jakarta, 2007) that discourages condom use. Lab evidence shows latex blocks pathogens (CDC, WHO). | kpap-jakarta-condom-myth-2007, cdc-condom-use-2024, who-condoms-qa-2022, nhs-condoms-2024 |
| 3 | myths-pulling-out | E2: WHO says withdrawal is "less reliable", and it gives no STI protection. | who-fp-factsheet-2025, who-sti-factsheet-2025, who-ec-factsheet-2021, who-pep-guidelines-2024 |
| 4 | myths-hiv-stigma | E2: 85.9% of the same IDHS 2017 sample showed stigmatising attitudes. Stigma deters testing (ITGSE; a Kemenkes official cited privacy and stigma). | wirawan-jpmph-2022, unaids-uu-2018, who-hiv-factsheet-2026, cdc-hiv-causes-2024, unesco-itgse-2018, antara-kemenkes-hiv-free-2023 |

**Essential total:** protection 6, stis 4, hiv 4, testing 3, consent 4, body 2, myths 4 = **27**.

### 5.4 Good-to-know topics (post-MVP; title, scope, intended sources)

These are not written yet. Each topic is planned as one lesson unless noted. Reason for the tier: these build understanding or confidence but are not the immediate protective step (§4).

**Protection (5)**
- *Internal (female) condoms*: what they are and how they differ. Sources: ITGSE KC 8.1, CDC internal-condom page.
- *Barriers for oral sex*: dental dams and condoms for oral sex. Sources: CDC condom brief, NHS STIs.
- *Fit, feel and erection worries*: fit and feel problems are common reasons people stop using condoms (Sanders 2012). Sources: Sanders 2012, NHS.
- *Latex allergy and non-latex condoms*. Sources: WHO condoms Q&A (polyurethane), NHS.
- *Getting and carrying condoms discreetly*: where to buy, cost, disposal. Sources: local research needed (no source yet).

**STIs (5)**
- *HPV and the HPV vaccine*: common, ~90% clear on their own, vaccine. Reason: protective, but adult catch-up availability in Indonesia is unverified. Sources: who-hpv-factsheet-2024, Kemenkes immunisation programme (to find).
- *Hepatitis B and its vaccine*: sexual transmission, the vaccine is "nearly 100%" protective. Sources: who-hepb-factsheet-2026.
- *Herpes in more depth*: outbreaks, spread without symptoms. Sources: who-hsv-factsheet-2025.
- *Syphilis and pregnancy*: 1.1 million pregnant women infected in 2022. Sources: who-sti-factsheet-2025.
- *Chlamydia, gonorrhoea and trichomoniasis: a closer look*. Sources: WHO STI fact sheet, NHS condition pages.

**HIV (4)**
- *HIV self-testing*: how it works, and that a positive result needs confirmation. Sources: who-hiv-factsheet-2026, WHO HIV self-testing guidance.
- *Living well with HIV and disclosure*. Sources: ITGSE KC 8.2, WHO HIV fact sheet.
- *HIV and pregnancy (preventing transmission to the baby)*. Sources: WHO HIV fact sheet.
- *Voluntary medical male circumcision (VMMC)*: what it does and does not do. Sources: ITGSE KC 8.3, WHO.

**Testing and care (3)**
- *What happens at a test visit*: reduces fear of the first visit. Sources: local Puskesmas procedures (to verify).
- *Telling a partner about a result*: partner notification. Sources: who-sti-factsheet-2025, ITGSE KC 5.3.
- *Cervical screening*: from age 25–30; WHO interval guidance. Sources: who-hpv-factsheet-2024, Kemenkes screening programme (to find).

**Consent and relationships (5)**
- *Healthy and unhealthy relationships*: controlling behaviour, IPV signs. Sources: who-vaw-factsheet-2026, ITGSE KC 1.2, 4.1.
- *Online safety, sexting and image-based abuse*. Sources: ITGSE KC 4.3.
- *Talking about wants and boundaries*. Sources: ITGSE KC 5.3.
- *Gender norms and double standards*. Sources: ITGSE KC 3, KC 4.2.
- *Supporting a friend*. Sources: ITGSE KC 5.5, 8.3.

**Body and health (6)**
- *Sexual and reproductive anatomy*. Sources: ITGSE KC 6.1.
- *The menstrual cycle and fertility*. Sources: ITGSE KC 6.2–6.3.
- *Normal discharge vs. signs to check*. Sources: NHS.
- *Contraception methods in more detail*: pills, injections, implants, IUDs. Sources: who-fp-factsheet-2025.
- *Sexual health as wellbeing*: WHO's definition, pleasure, body image. Sources: WHO sexual health topic page, ITGSE KC 6.4, 7.
- *Sexual orientation and gender identity: inclusion basics*. Sources: ITGSE KC 1.3, 3.

**Myths and stigma (3)**
- *More local myths*: for example "washing after sex prevents STIs", antibiotics "before sex", virginity myths. Reason: we need a local myth survey before writing these, because we will not invent prevalence. Sources: to be found (Udayana or PKBI Bali research; focus groups).
- *Values, religion and sexual health: having the conversation*. Sources: ITGSE KC 2.1, 2.3.
- *Porn and media literacy*. Sources: ITGSE KC 5.4.

### 5.5 Expert topics (8; referral or deep-dive only)

| Track | Topic | Why Expert |
|---|---|---|
| protection | Condom standards and quality marks in Indonesia (SNI/BPOM) | Regulatory detail, not verified |
| stis | Antimicrobial resistance and treatment regimens | Clinical, changes often, dosing |
| stis | Syndromic management vs. lab diagnosis | Clinical practice detail |
| hiv | PrEP regimens (daily/event-driven, injectables) | Dosing must come from a clinician |
| hiv | Viral load monitoring and treatment failure | Clinical |
| testing | Window periods by test type (antibody, antigen/antibody, NAT) | Technical, varies by test |
| consent | Indonesian law: age of consent, sexual violence law (UU TPKS), criminal code, reporting | Legal; needs Indonesian legal review |
| body | Pregnancy options counselling | Legal and clinical sensitivity |

## 6. Mascot growth thresholds

| Stage | Unlocks at | Reasoning |
|---|---|---|
| **Seed** | 0 lessons (start) | Everyone starts here. No barrier. |
| **Sprout** | **9 lessons** (⅓ of 27) | About 9 days of daily use: early, visible progress inside the first two weeks, when drop-off is highest. If the user follows the recommended path (§6.1), 9 lessons covers all of Protection plus the core STI lessons, which is a meaningful milestone. |
| **Bloom** | **27 lessons** (all Essential) | Bloom means "you know the essentials". It is tied to the complete MVP content, not to a streak, so it never rewards speed over learning. |

Notes:
- Thresholds should be stored as data, not hard-coded. If the Essential count changes after medical review, set Sprout = round(Essential ÷ 3) and Bloom = Essential count.
- Count only completed lessons (all cards viewed and the quick-check answered). A wrong answer still counts. The explanation is shown calmly whether the answer was right or wrong, so there is no penalty.
- Good-to-know lessons can later add stages after Bloom (for example "Flourish"). They should not change Bloom.

### 6.1 Recommended daily path (interleaved)

1–6 Protection 1–6 → 7–8 STIs 1–2 → 9 HIV 3 (PEP) → 10–11 Consent 1–2 → 12–13 Testing 1–2 → 14 Body 2 (EC) → 15–16 STIs 3–4 → 17–18 HIV 1–2 → 19 Testing 3 → 20 Consent 3 → 21 Body 1 → 22–23 Myths 1–2 → 24 HIV 4 → 25 Consent 4 → 26–27 Myths 3–4.

Why this order: the time-critical actions (PEP, EC, "if it breaks") all come within the first two weeks.

## 7. Context: why this content, for this audience

- Among 22,864 unmarried Indonesians aged 15–25 (IDHS 2017), only **14.1%** had comprehensive HIV knowledge, and **85.9%** showed stigmatising attitudes. About a fifth had nobody to talk to about sex. Friends were the most common confidants (55.2% in the abstract; 56.1% in the paper's results). [wirawan-jpmph-2022; authors from Udayana University, Denpasar]
- Among 12,691 Indonesian women aged 15–24, 53.95% had stigmatising attitudes, and more HIV knowledge was linked to less stigma. [arifin-bmcph-2022] (We did not use this paper's misconception percentages. Its tables are ambiguous about whether they report correct or incorrect answers.)
- Among 1,200 Denpasar high-school students (2016), 55.6% had sufficient knowledge of STIs and HIV/AIDS. The authors note that SRH is "taboo and sensitive" and seen as "inappropriate for unmarried people" in Bali, and they recommend comprehensive sexuality education. [pradnyani-ghmj-2019]
- The Sanders review shows condom errors are common worldwide. This is why Protection has 6 lessons. [sanders-condom-errors-2012]

## 8. Tone and writing guidelines

- **Calm, warm, direct, non-judgemental.** No fear tactics, no guilt, no moralising. Never imply that sex outside marriage is shameful. Never imply that it is required either.
- **Inclusive.** Use "partner", not gendered assumptions. Say "a penis" or "the vagina", not "his" or "her". Mention anal and oral sex plainly where relevant.
- **Plain English for translation.** Short sentences (aim for ≤ 15 words). No idioms, slang, puns or phrasal-verb chains. Explain each acronym the first time (STI, PEP, PrEP, EC, ART). Use "you".
- **Limits:** headline ≤ 60 characters, body ≤ 280 characters, 2–4 cards, exactly 1 quick-check with 2–4 options. The explanation must make sense whether the answer was right or wrong.
- **Claims:** use hedged verbs ("lowers", "greatly reduces", "can"). Put numbers only in stat cards, with the source in `statCaption`.
- **Medicine:** never give doses, schedules or brand-specific instructions. Always say "a health worker will explain".
- **Privacy:** `neutralTitle` is always "Today's lesson". Notifications and previews must not reveal the topic.
- **Nana tips:** optional, ≤ 1 sentence, encouraging. Never a medical claim.
- **Distractor options** must be plausible myths, not jokes, so they teach something. ("Only if you are drunk too" in consent-when-not-possible is borderline and should be reviewed.)

## 9. Localization notes and claims needing local verification

General:
- The local terms "Puskesmas" and "Ministry of Health (Kemenkes)" are used. Translators should keep "Puskesmas" untranslated.
- Translation into Bahasa Indonesia needs a native-speaker health communicator. Check that "consent" and "STI (IMS)" use the terms young people actually use.
- **Not invented:** we did not add hotlines, clinic names, prices or legal statements, because none could be verified from a primary source.

Lessons with a `localNote` (must be resolved before launch):
| Lesson | What to verify |
|---|---|
| protection-lube-and-doubling | Which oils and lotions are commonly used as lube in Bali (coconut oil is given as an example of a cooking oil). |
| protection-storage-heat | Whether the motorbike-seat-box example is appropriate (inferred from the < 40°C guidance, not measured). |
| protection-if-it-breaks | **Where PEP and EC are available in Bali, cost, whether a prescription is needed.** |
| stis-getting-treated | Whether a specific note on self-medication with over-the-counter antibiotics is needed (no local source found). |
| hiv-treatment-uu | Free ARV at Puskesmas and government hospitals (source: ANTARA quoting Kemenkes, 2023). |
| hiv-pep | **Which Bali facilities give PEP to the public, cost, out-of-hours access.** |
| hiv-prep | PrEP eligibility, forms and Bali sites. Secondary sources suggest it is limited to key populations. |
| testing-timing-results | Whether NHS's "up to 7 weeks" fits the tests used in Indonesia. |
| testing-where-to-go | **Free HIV testing at Puskesmas** (detikHealth 2018, ANTARA 2023, Suara Surabaya 2026). Also STI services, hours, ID/BPJS requirements, and how unmarried young adults are treated. |
| consent-if-something-happened | **Verified survivor services and referrals in Bali.** Legal options were left out pending legal review. |
| body-preventing-pregnancy | Access to contraception for unmarried young adults. |
| body-emergency-contraception | **EC availability (pharmacy or prescription), copper IUD access, legal status.** |
| myths-condoms-have-holes | Whether the "porous condom" myth (documented 2007) is still current among young people in Bali. |

Bold = blocks the `pep` and `testing` help actions. These must be filled with verified local data before launch.

## 10. Known gaps

1. **No primary Kemenkes source was opened.** Indonesian service facts rely on news reports quoting Kemenkes officials. Kemenkes guidelines (PEP/PPP, PrEP 2023, the IMS/HIV programme) should be obtained and cited.
2. **No recent Bali-specific myth data for 18–25s.** The Denpasar study (2016 data) covers high-school students. A local myth survey or focus groups are recommended before writing the remaining myth lessons.
3. **Condom-error prevalence figures** from Sanders 2012 were not available (we could only open the abstract page), so the lessons cite no percentages from it.
4. **Storage temperature** comes from a US state health department (MDH 2017, based on WHO 2003). The WHO/UNFPA 2023 storage recommendations page was found, but its content could not be read.
5. **Typical-use condom effectiveness** comes from NHS (98% / 82%). WHO's Q&A gives only a laboratory 99.5% figure.
6. **Internal condoms, dental dams, HPV and HepB vaccine access** are deferred to Good to know.
7. **Legal context** (age of consent, sexual violence law, criminal code on extramarital sex) is not covered and needs Indonesian legal review. This matters for the privacy and safety framing of the app itself.
8. **No accessibility or reading-level test** has been run yet. A Flesch-type check after translation is recommended.

## 11. Sources we tried but could not use

These were not cited because they could not be opened or read:
- kemkes.go.id / ayosehat.kemkes.go.id: no current page was found or opened. The Kemenkes PrEP guideline (2023) was not retrieved.
- Sanders et al. 2012 full text (CSIRO redirect, ResearchGate 403, Southampton eprints 403). Only the University of Kentucky abstract page was used.
- DOAJ record for Wirawan 2022 (403). The JPMPH journal page was used instead.
- Planned Parenthood condom page (403). MedlinePlus (DNS failure). North Dakota HHS condom instructions (connection refused). FDA condom page (404).
- WHO/UNFPA condom storage recommendations 2023 (the landing page has no content; the PDF was not read).
- A Puskesmas IMS/HIV service standard PDF on sippn.menpan.go.id (404).
- UNAIDS Indonesia country page (opened, but it had no figures).

## 12. Review status

**All 27 lessons: `pending` — medical review required. A named reviewer is required.**

Sign-off needed before launch:
| Review | Reviewer (name, qualification) | Date | Status |
|---|---|---|---|
| Medical (Indonesian physician, sexual health / HIV) | — | — | pending |
| Local services verification (Bali Dinas Kesehatan / Puskesmas contact) | — | — | pending |
| Cultural and youth review (Bali, 18–25) | — | — | pending |
| Legal (Indonesia) | — | — | pending |
| Translation (Bahasa Indonesia) | — | — | not started |

After review, set each lesson's `review` field to `{"status": "approved", "reviewer": "<name>", "date": "YYYY-MM-DD"}`.

## 13. References

All accessed 2026-10-20.

1. UNESCO, UNAIDS, UNFPA, UNICEF, UN Women, WHO. *International technical guidance on sexuality education: An evidence-informed approach* (revised edition). 2018. https://aa.unfpa.org/sites/default/files/pub-pdf/ITGSE.pdf (landing page: https://www.unesco.org/en/articles/international-technical-guidance-sexuality-education-evidence-informed-approach) — id `unesco-itgse-2018`
2. WHO. *Sexually transmitted infections (STIs)* fact sheet. 10 Sep 2025. https://www.who.int/news-room/fact-sheets/detail/sexually-transmitted-infections-(stis) — `who-sti-factsheet-2025`
3. WHO. *HIV and AIDS* fact sheet. 27 Jul 2026. https://www.who.int/news-room/fact-sheets/detail/hiv-aids — `who-hiv-factsheet-2026`
4. WHO. *WHO updates guidelines to enhance access to HIV post-exposure prophylaxis*. 22 Jul 2024. https://www.who.int/news/item/22-07-2024-who-updates-guidelines-to-enhance-access-to-hiv-post-exposure-prophylaxis — `who-pep-guidelines-2024`
5. WHO. *Condoms* Q&A. 1 Dec 2022. https://www.who.int/news-room/questions-and-answers/item/condoms — `who-condoms-qa-2022`
6. WHO. *Herpes simplex virus* fact sheet. 30 May 2025. https://www.who.int/news-room/fact-sheets/detail/herpes-simplex-virus — `who-hsv-factsheet-2025`
7. WHO. *Human papillomavirus and cancer* fact sheet. 5 Mar 2024. https://www.who.int/news-room/fact-sheets/detail/human-papilloma-virus-and-cancer — `who-hpv-factsheet-2024`
8. WHO. *Hepatitis B* fact sheet. 28 Jul 2026. https://www.who.int/news-room/fact-sheets/detail/hepatitis-b — `who-hepb-factsheet-2026`
9. WHO. *Emergency contraception* fact sheet. 9 Nov 2021. https://www.who.int/news-room/fact-sheets/detail/emergency-contraception — `who-ec-factsheet-2021`
10. WHO. *Family planning/contraception methods* fact sheet. 3 Jul 2025. https://www.who.int/news-room/fact-sheets/detail/family-planning-contraception — `who-fp-factsheet-2025`
11. WHO. *Violence against women* fact sheet. 18 Jun 2026. https://www.who.int/news-room/fact-sheets/detail/violence-against-women — `who-vaw-factsheet-2026`
12. UNAIDS. *Undetectable = untransmittable*. 20 Jul 2018. https://www.unaids.org/en/resources/presscentre/featurestories/2018/july/undetectable-untransmittable — `unaids-uu-2018`
13. CDC. *How to Use an External Condom*. 3 Apr 2024. https://www.cdc.gov/condom-use/resources/external.html — `cdc-condom-external-2024`
14. CDC. *Condom Fact Sheet In Brief*. 18 Apr 2024. https://www.cdc.gov/CONDOMEFFECTIVENESS/brief.html — `cdc-condom-brief-2024`
15. CDC. *Condom Use: An Overview*. 19 Jan 2024. https://www.cdc.gov/condom-use/index.html — `cdc-condom-use-2024`
16. CDC. *How HIV Spreads*. 25 Nov 2024. https://www.cdc.gov/hiv/causes/index.html — `cdc-hiv-causes-2024`
17. CDC. *Post-Exposure Prophylaxis (PEP)*. 2 Dec 2024. https://www.cdc.gov/hiv/prevention/pep.html — `cdc-pep-2024`
18. NHS. *Condoms*. Reviewed 26 Jan 2024. https://www.nhs.uk/contraception/methods-of-contraception/condoms/ — `nhs-condoms-2024`
19. NHS. *Sexually transmitted infections (STIs)*. Reviewed 13 May 2024. https://www.nhs.uk/conditions/sexually-transmitted-infections-stis/ — `nhs-stis-2024`
20. Minnesota Department of Health. *Condom Storage and Distribution Guidelines*. 10 Oct 2017. https://www.health.mn.gov/diseases/hiv/partners/storage.pdf — `mdh-condom-storage-2017`
21. Sanders SA, Yarber WL, Kaufman EL, Crosby RA, Graham CA, Milhausen RR. Condom use errors and problems: a global view. *Sexual Health* 2012;9(1):81–95. doi:10.1071/SH11095. https://scholars.uky.edu/en/publications/condom-use-errors-and-problems-a-global-view/ — `sanders-condom-errors-2012`
22. Wirawan GBS, Gustina NLZ, Januraga PP. Open communication about reproductive health is associated with comprehensive HIV knowledge and a non-stigmatising attitude among Indonesian youth. *J Prev Med Public Health* 2022;55(4):342–350. doi:10.3961/jpmph.21.581. https://www.jpmph.org/journal/view.php?doi=10.3961/jpmph.21.581 — `wirawan-jpmph-2022`
23. Arifin H, et al. HIV-related knowledge, information, and their contribution to stigmatization attitudes among females aged 15–24 years: regional disparities in Indonesia. *BMC Public Health* 2022;22:637. doi:10.1186/s12889-022-13046-7. https://pmc.ncbi.nlm.nih.gov/articles/PMC8976340/ — `arifin-bmcph-2022`
24. Pradnyani PE, Putra IGNE, Astiti NLEP. Knowledge, attitude, and behavior about sexual and reproductive health among adolescent students in Denpasar, Bali, Indonesia. *Global Health Management Journal* 2019;3(1):31–39. https://distantreader.org/stacks/journals/ghmj/ghmj-554.pdf — `pradnyani-ghmj-2019`
25. ANTARA News. *Kemenkes pastikan pengobatan HIV/AIDS gratis di faskes pemerintah*. 29 Nov 2023. https://jambi.antaranews.com/berita/563478/kemenkes-pastikan-pengobatan-hiv-aids-gratis-di-faskes-pemerintah — `antara-kemenkes-hiv-free-2023`
26. detikHealth. *Tes HIV-AIDS dan Obatnya Tersedia Gratis!* 3 Dec 2018. https://health.detik.com/berita-detikhealth/d-4328725/tes-hiv-aids-dan-obatnya-tersedia-gratis — `detik-kemenkes-hiv-test-2018`
27. Suara Surabaya. *Pemerintah Perluas Layanan Tes HIV untuk Memutus Rantai Penularan*. 26 Jul 2026. https://www.suarasurabaya.net/?p=912585 — `suarasurabaya-kemenkes-testing-2026`
28. Medicastore (KPAP DKI Jakarta press release). *Kondom sebagai salah satu alternatif pencegahan HIV/AIDS*. 28 Sep 2007. https://medicastore.com/artikel/1921/kondom-sebagai-salah-satu-alternatif-pencegahan-hivaids — `kpap-jakarta-condom-myth-2007`
