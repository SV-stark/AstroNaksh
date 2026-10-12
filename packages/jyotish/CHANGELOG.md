# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [2.20.7] - 2026-10-09

### Fixed
- **Transit window inversion & negative orb** (`transit_service.dart`):
  - In `_createTransitAspect`, `exactOrb` was taking a signed orb difference that could be negative, causing `startDate` to fall after `endDate` when constructing transit event windows. `exactOrb` is now always non-negative (`orb.abs()`), and `halfSpanDays` in `findTransitEvents` takes `aspect.exactOrb.abs() / relativeSpeed`, guaranteeing `startDate <= exactDate <= endDate`.
- **Atmakaraka retrograde Rahu reverse degree calculation** (`dasha_service.dart`, `jaimini_service.dart`):
  - In `DashaService`, `_getAtmakaraka` previously computed Rahu's degree as raw `longitude % 30.0`, ignoring retrograde movement and bypassing `CalculationFlags.nodeType`. It now delegates directly to `JaiminiService.getAtmakaraka`, which measures retrograde Rahu's distance traversed in sign as `30.0 - (longitude % 30.0)`. Added `const JaiminiService()` constructor.
- **Varshaphala 60-year Jovian cycle anchor** (`varshapal_service.dart`):
  - In `calculateVarshapal`, unified samvatsara determination directly with `getCurrentVarshaNumber(varshaDateTime)` (anchored to Prabhava 1987), eliminating the dead unanchored Jupiter-6° branch and unused Jupiter lookup.
- **Vajra and Yava Nabhasa Yogas presence rule** (`yoga_service.dart`):
  - In `vajra_yoga` and `yava_yoga`, removed the over-restrictive `all*` conjuncts that were mathematically incompatible with maximum planetary elongations (Mercury/Venus 90° from Sun). Conformed to PyJHora BVR-84/85 presence rules: `hasBeneficIn1 && hasBeneficIn7 && hasMaleficIn4 && hasMaleficIn10` for Vajra, and reciprocal for Yava.
- **Varshaphala Egyptian Hadda bounds** (`varshapal_service.dart`):
  - Conformed Gemini, Leo, and Scorpio term bounds in `_getHaddaLord` to classical *Hayanaratna* and *Tajaka Neelakanthi* Egyptian bounds rather than Ptolemy's modified bounds, correcting Mercury's hadda at 11°–19° Scorpio and Jupiter at 19°–24° Scorpio.
- **Varshaphala Maasa period duration** (`varshapal_service.dart`):
  - In `_addMaasaDuration`, scaled month lengths to 1/12th of the solar year (`365.24219 / 12` ≈ 30.437 days) instead of fixed 30 days, so the 12 periods fully span the annual return year.
- **Varshaphala Dina-Ratri Lord day/night evaluation** (`varshapal_service.dart`):
  - In `determineVarshesh`, evaluated `isDay` from the natal birth chart (`natalChart`) rather than the annual solar return chart, conforming to the classical Janma-kalina rule and PyJHora parity.
- **AspectService exactOrb sign normalization** (`aspect_service.dart`):
  - Enforced `exactOrb: orb.abs()` in `_createAspect`, ensuring orbs are consistently positive across degree-based calculations.

### Tests
- Added `test/confirmed_fixes_test.dart` (5 comprehensive test suites) verifying:
  - Transit aspect windows and non-negative `exactOrb` via `getTransitPositions` and `getTransitEvents`.
  - Atmakaraka consistency between DashaService and JaiminiService with retrograde Rahu reverse degree traversal.
  - Varshaphala Samvatsara 1-60 cycle coverage and 2026 Paraabhava alignment.
  - Vajra and Yava yoga dual-pole occupancy gating.
  - Vipareetha Raja Yoga negative and positive cross-dusthana test cases.

---

## [2.20.6] - 2026-10-09

### Fixed
- **`findTransitEvents` fabricated the aspect window** (`transit_service.dart`):
  - The `startDate`/`endDate` of every transit event were set to `exactDate ± 3 × intervalDays`, i.e. derived from the sampling interval rather than from the aspect itself. A 1-degree orb between two slow planets yields a window of months, and a wide orb between fast planets yields hours, yet both got the identical fabricated span. The window is now computed as `exactOrb / relativeSpeed` days either side, where the relative speed is the difference between the transiting and natal bodies' `longitudeSpeed`. A degenerate zero relative speed falls back to the sampling interval.

### Tests
- Added `test/classical_data_tables_test.dart` (6 tests) giving first-ever coverage to the two data tables that previously had none:
  - **`naturalRelationships`** pinned to the table derived from the BPHS 3.55 rule, all 42 directed pairs, plus the four deliberately asymmetric pairs most likely to be "tidied" into symmetry, plus the Panchadha Maitri arithmetic.
  - **Bhinnashtakavarga fixed totals** checked on two unrelated births, since 48/49/39/54/56/52/39 → 337 is a property of the tables rather than of any chart. This is the hard checksum B.V. Raman describes: a single mis-transcribed house list moves the total.
  - **Minimum required Shadbala** pinned to BPHS 27.32-33, with the Sun's 390 virupas called out explicitly and asserted *not* to be 300.

---

## [2.20.5] - 2026-10-09

### Fixed
- **`ArgumentService.calculateArgalaForPlanet` reported every Argala as unobstructed** (`argala_service.dart`):
  - `isObstructed` was hard-coded to `false` with a "simplified" comment, while `calculateArgalaForHouse` — the other half of the same public API — computed Virodha Argala properly. The two methods therefore disagreed on every chart. Obstructing houses are now looked up with the same offsets the house-based method uses (12th obstructs the 2nd; 10th and 9th obstruct the 4th and 5th; 3rd obstructs the 11th).
- **`DashaResult.precisionWarning` understated timing drift by ~3 orders of magnitude** (`dasha_service.dart`):
  - The warning reported `uncertainty / 60 * 0.2` days — 0.2 days for a one-hour uncertainty. The real figure is the fractional nakshatra error (one minute of clock error is 1/1440 of the Moon's synodic day) times the first dasha's years, which for a 20-year dasha is **~304 days**. Because the whole timeline is shifted by the same amount, that error propagates to every subsequent dasha boundary, so it is now reported as such.
- **`_deduplicateEvents` collapsed genuinely distinct exact aspects** (`transit_service.dart`):
  - The dedupe key bucketed `exactDate` into 7-day windows, so any two events sharing a transiting planet, natal body and aspect type within the same week collapsed into one — a Tuesday exact opposition and a Thursday exact trine to the same natal planet could not both be reported. The key is now the full identifying tuple including the exact instant.
- **Junction searches could return a silently wrong instant** (`panchanga_service.dart`):
  - `getTithiJunction`, `getNakshatraJunction` and `getYogaJunction` bisect a 48-hour window and return the converged bound with no check that it is actually the requested junction. Because the Moon-Sun elongation advances ~585 degrees across that span — more than a full cycle — the target angle is crossed **twice** inside the window, and a signed-difference bisection assumes monotonicity and can converge on either. The wrong crossing is ~29.5 days out. Each search now verifies its result and throws a `StateError` naming the actual offset instead of returning a plausible-looking wrong timestamp.
- **`_getAtmakaraka` used the 7-karaka scheme, contradicting the rest of the library** (`dasha_service.dart`):
  - It iterated only `Planet.traditionalPlanets`, so a chart whose Rahu held the highest degree got a different Atmakaraka from `JaiminiService.getAtmakaraka` and the facade's `getCharaKarakas`, both of which default to the eight-karaka scheme. Now consistent.

### Verified, not changed
- **Yogini enum** audited as having Mangala/Pingala swapped. Not a defect: classically Mangala is ruled by the Moon and Pingala by the Sun, which is what the enum declares. The nakshatra-to-Yogini starting index `(nakshatraIndex + 3) % 8` is also correct, matching the Ashwini→Bhramari, Ardra→Mangala, Krittika→Ulka, Mrigashira→Sankata assignment.
- **`HouseSystem.getHouseForLongitude` silent house-1 fallback** — already throws `ArgumentError` listing the malformed cusps.
- **`CalculationFlags.fromJson` silent enum defaults** — already throws `ArgumentError` for unrecognised `system`, `nodeType` and `siderealMode`, with identifier matching preferred over the legacy label.
- **`AspectService.getPlanetsAspectingSign` counting same-sign as aspecting** — already returns `true` only for the 6th-house separation.

---

## [2.20.4] - 2026-10-09

### Verified
- **Purnimanta naming confirmed against the authoritative 2026 festival calendar.** The Krishna-paksha offset was audited as wrong on the theory that a Purnimanta month straddling two Amanta months cannot follow a fixed offset. It can, and the convention is externally verifiable: 19 April 2026 (Akshaya Tritiya) is Vaishakha in *both* calendars; 1 May 2026 is Vaishakha Purnima / Buddha Purnima, so Purnimanta Vaishakha ends that day; 2 May 2026 is therefore Krishna Pratipada of Purnimanta Jyeshtha while Amanta Vaishakha still runs to ~17 May. All four expectations now hold as regression tests.
- **Gana Milan Varna table confirmed.** The nakshatra-to-Varna assignments were audited as outliers, specifically Hasta and Uttara Phalguni as Shudra. Both are correct: Kalidasa's *Poorvakalamrut* Ch. 3 shloka 93, the Madhaviya Grantha and B.V. Raman's *Muhurta* all list Hasta and Uttara Phalguni among the six Shudra nakshatras, and all three agree on every one of the 27 assignments.

### Changed
- **Documentation only, no behaviour change**:
  - `_getNakshatraVarna` now cites the actual sources (*Poorvakalamrut* Ch. 3 shloka 93, Madhaviya Grantha, B.V. Raman) and states explicitly that all three agree on every assignment, including the two that were questioned.
  - The Hora Lagna rate comment now spells out the unit trap — the classical rule is 30 degrees per 2.5 **ghatis**, which is one hour, not 2.5 hours — and records that the earlier revision's 2.5x error came from reading it as hours. This distinguishes it from the alternative "one sign per 2.5 hours" formulation.

### Tests
- Added a `matches the authoritative 2026 festival calendar` case to `test/round7_fixes_test.dart` pinning Purnimanta names to externally verifiable festival dates (Akshaya Tritiya 19 Apr, Buddha Purnima 1 May, and the Krishna Pratipada on 2 May) alongside the corresponding Amanta month, so the naming is checked against ground truth rather than only against an internal invariant.

---

## [2.20.3] - 2026-10-09

### Fixed
- **Special Lagnas anchoring** (`special_lagnas_service.dart`):
  - Hora and Ghati Lagna are now anchored on the Sun's longitude at **sunrise** — the start of the elapsed interval — rather than on the Sun at the birth moment. Anchoring on the birth Sun while adding hours measured from sunrise counted the Sun's own motion across that window twice, an error of roughly 1 degree per hour of elapsed time (~6 degrees for a 6-hour gap), so the bias scales with birth hour.
  - New optional `sunLongitudeAtSunrise` parameter on `SpecialLagnasService.calculateSpecialLagnas` and the `Jyotish` facade pins the anchor exactly when the caller already knows it. When omitted it is derived by rewinding the chart's Sun with its own `longitudeSpeed`, accurate to < 0.01 degrees.
- **FFI error-buffer handling** (`ephemeris_service.dart`):
  - All five `swe_*` error buffers now allocate with `calloc` and release with `calloc.free`. One site freed a `calloc`-allocated buffer with `malloc.free`, and the other four still allocated with `malloc` despite a comment explaining that an unwritten buffer must read as a genuine empty string rather than stale heap bytes — so the empty-error case remained non-deterministic on those paths. The rationale stated at the call site now holds everywhere.
- **Unbounded divisional-chart cache** (`divisional_chart_service.dart`):
  - The cache is now an LRU bounded at 512 entries. `VedicChart.isVargottama` holds a `static` shared `DivisionalChartService`, and `_cache` had no eviction, so the cache was process-global and grew without limit across every chart ever computed — an unbounded leak in any long-lived app or server.
- **Purnimanta month naming** (`masa_service.dart`):
  - The Amanta month name — used as the basis for both calendars — is now derived from the exact bisected **new-moon boundary** instead of being extrapolated from the current instant with a mean synodic rate. Previously the Adhika test used the bisected boundary while the month name came from a mean-rate estimate of the current Sun, so the two could disagree near a sankranti.
  - The Purnimanta offset (Amanta name advanced by one during Krishna paksha, unchanged during Shukla paksha) is unchanged: it is a pure calendar convention needing no astronomical estimate, so it is now layered on top of the exact boundary-derived Amanta month rather than being folded into an approximation.
  - `_calculateAmantaMonth` and `_calculatePurnimantaMonth` (the mean-rate estimators) were removed.

### Migration Notes
- **`Rashi.name` and `SiderealMode.name` now return the enum identifier**, not the display label. `Rashi.aries.name` is `'aries'` (previously `'Aries'`); `SiderealMode.lahiri.name` is `'lahiri'` (previously `'Lahiri'`). Use `Rashi.label` / `SiderealMode.label` for display, and `.name` for persistence, cache keys and matching. `CalculationFlags.toJson`/`fromJson` and the divisional-chart cache key already use the identifier, so serialised data is unaffected.
  - `lib/` was grepped for comparisons of `.name` against labels — there are none, so the library itself is internally consistent.
  - External code doing `rashi.name == 'Aries'` or `siderealMode.name == 'Lahiri'` will silently stop matching and must switch to `.label`.

### Tests
- Replaced the `Special Lagnas` test, which re-derived the implementation (`(250 + 6*30) % 360 = 70`) and therefore validated nothing, with an independent derivation: a Sun travelling 1 degree/day stands at 249.75 after a 6-hour rewind, giving Hora Lagna 69.75 and Ghati Lagna 339.75 — values that the previous birth-moment anchoring cannot produce. A pinned-anchor case is covered too.
- Added `test/round7_fixes_test.dart` (3 tests): the paksha-aware Purnimanta invariant checked daily across a full year (exercising both halves of the cycle, and the days either side of a sankranti), boundary/Adhika consistency, and LRU eviction with cache-hit identity preserved.

### Verification
- `flutter analyze` — no issues.
- `flutter test` — 232 passing (was 229).

---

## [2.20.2] - 2026-10-09

### Fixed
- **Ashtakoota Compatibility Tables**:
  - Varna Koota: replaced the incomplete 26-of-27 nakshatra table — under which only Mula reached the `Shudra` fallback, producing a 12/10/4/1 distribution found in no classical source — with the complete Dakshin-Bharat serpentine classification (7 Brahmin, 7 Kshatriya, 7 Vaishya, 6 Shudra), sourced from the Madhaviya Grantha / Muhurta tables and cross-verified against two independent transcriptions that agree exactly.
  - Yoni Koota: replaced the four-value matrix (`{0, 2, 3, 4}`) with the classical five-tier Muhurta Chintamani / Saravali matrix, restoring the missing `1 = inimical` band. The seven sworn-enemy pairs (Horse/Buffalo, Elephant/Lion, Goat/Monkey, Serpent/Mongoose, Dog/Deer, Cat/Rat, Cow/Tiger) remain the only cells scoring 0, and the matrix stays symmetric.
  - Gana Koota: replaced the non-standard symmetric 3/0 scoring with the directional Parashari table — same gana 6, Deva groom + Manushya bride 6, the reverse 5, Rakshasa groom + Deva bride 1, all remaining cross-gana pairs 0.
- **Shadbala**:
  - Saptavargaja Bala: removed the non-existent `exalted => 60 Virupas` tier together with the non-classical 22.5 / 7.5 / 3.75 / 1.875 grades. The planet is now scored against the lord of the sign it occupies in each of the seven vargas, per BPHS Ch. 27 v.2-4 (Moolatrikona 45, own sign 30, great friend 20, friend 15, neutral 10, enemy 4, great enemy 2). This brings Sthana Bala back inside the classical 480-Virupa ceiling, which the old table could exceed.
  - Chesta Bala: un-transposed *Manda* (30) and *Mandatara* (15), which were reversed relative to the table the remaining bands already followed.
  - Saptavargaja Moolatrikona range for the Moon corrected to Taurus 4°–20°; 0°–3° of Taurus is the exaltation point and is not part of the Moolatrikona.
- **Nitya Yoga Lords**:
  - Replaced the scrambled ruling-planet table — which gave a 6/5/4/4/3/3/2 distribution, impossible for a seven-planet rotation over 27 entries — with the classical nine-planet Parashari cycle (Saturn, Mercury, Ketu, Venus, Sun, Moon, Mars, Rahu, Jupiter) repeated three times, so each planet rules exactly three of the 27 yogas. The `nature` classification (malefic = 1, 6, 9, 10, 13, 15, 17, 19, 27) was verified correct and left unchanged.
- **Yoga Detection**:
  - Gaja-Kesari Yoga now enforces all three of its stated conditions. Previously only the quadrant-from-Moon test was applied, so a Jupiter debilitated in Capricorn with no benefic association and no cancellation was reported as a full Gaja-Kesari.
  - A chart missing any of the seven traditional planets now raises `StateError` from `detectNatalYogas` instead of substituting house 1 / Aries and fabricating yoga results from invented data.
- **Jaimini Arudha**:
  - `_getStrongerLord` now selects the *unassociated* co-lord for Scorpio (Mars/Ketu) and Aquarius (Saturn/Rahu), consistent with the own-sign rule immediately above it, which already preferred the candidate not tied up in the sign.
- **Divisional Charts**:
  - Ketu's varga placement is now derived from Ketu's own natal longitude (Rahu + 180°) run through the varga mapping, rather than from the already-projected Rahu. The two are equivalent for evenly divided vargas, so D2/D3/D4/D9/D10/D12/D16/D20/D24/D40/D45/D60 are unaffected, but D30 Trimsamsa and D249 did not commute with a 180° rotation and reported the wrong sign.
- **Dasha**:
  - The Mars/Ketu and Saturn/Rahu co-lord comparisons in `_getSignLordAdvanced` now count the lunar nodes themselves. `VedicChart.getPlanetsInHouse` iterates only the seven traditional planets, so a lone node previously always scored zero conjunctions while a lone Mars or Saturn scored its own presence — a structural bias towards the traditional lord.
- **Panchanga**:
  - `AdhikaMasaType.nija` is now returned when the preceding lunar month was Adhika. Previously it was never produced at all, so a Nija month was indistinguishable from any other ordinary month.
- **Manglik Dosha**:
  - Parihara 16 (Mars conjunct Jupiter or Moon) no longer fabricates an Aries Jupiter from a missing planet, which could spuriously cancel the dosha.
- **Error Handling**:
  - A missing Moon, Venus or Jupiter in `CompatibilityService` now raises `StateError`, and an unrecognised nakshatra name raises `ArgumentError`. These replace silent `?? 0` / `?? 'Ashwini'` / `?? 1` defaults that scored a coupling against fabricated Aries or Ashwini data. Callers relying on the previous permissive behaviour must handle these exceptions.
  - Removed a second `return 1` in `calculateYoni` that shadowed the new unknown-nakshatra check.

### Tests
- Added `test/classical_table_fixes_test.dart` (11 tests) covering the Varna, Yoni, Gana and Nitya-Yoga tables, including the 7/7/7/6 Varna distribution, the five-tier Yoni scale, the directional Gana table, and the three-yogas-per-planet Nitya-Yoga distribution.
- Added `test/divisional_ketu_fix_test.dart` (3 tests) covering Ketu's independent D30 projection and its preserved opposition to Rahu in the evenly divided D9.
- Extended `test/natal_yoga_test.dart` with a negative Gaja-Kesari case (kendra from Moon without benefic support) and a positive case. The previous assertion encoded the incomplete single-condition rule and has been replaced.
- Total passing tests grew from 215 to 229.

---

## [2.20.1] - 2026-10-08

### Fixed
- **Ashtakavarga Rebuild (BPHS Parashara Parity)**:
  - Replaced planetary contributor tables in `Ashtakavarga` with canonical 12x7 matrices, restoring exact classical totals: Sun 48, Moon 49, Mars 39, Mercury 54, Jupiter 56, Venus 52, Saturn 39, and Sarvashtakavarga sum of 337.
  - Corrected `getTotalBindusForHouse(h)` in `Ashtakavarga` to count from the Ascendant sign instead of hardcoded Aries.
  - Implemented BPHS Chapter 68 Trikona Shodhana zero-preservation rule: if any sign in a trikona has 0 bindus, no reduction is made; if all three are equal, all become 0; else deduct the minimum from the other two.
  - Fixed `calculateHousePinda` in `AshtakavargaService` to measure from the Ascendant sign.
  - Updated `getFavorableTransitSigns(aav, planet)` to evaluate the queried planet's specific BAV ($\ge 4$ bindus).
- **Shadbala Motional & Temporal Strengths**:
  - Fixed Chesta Bala: Retrograde speed returns 0.0 virupas (resolving +60 virupa inflation into *ishtaPhala*); stationary motion (`speed.abs() < 0.05`) returns 15.0; *Chara* direct motion returns 60.0; *Atichara* returns classical 7.5.
  - Zeroed Moon Chesta Bala to prevent double-counting *Paksha Bala*.
  - Added Planetary War strength (*Yuddha Bala*) into Kala Bala via `GrahaYuddhaService` (+30 for victor, -30 for defeated), removing unneeded clamp that masked war deductions.
  - Re-anchored modern Jovian year to Prabhava epoch (1987, JD 2446885.5) using 361.0220 days, eliminating non-monotonic cycle drift in Samvatsara Lord calculation.
  - Classified waxing crescent Moon (Shukla Paksha 0°–180°) as benefic in Drik Bala.
  - Corrected aspect strength multiplier ladder so only Mars (90°/210°), Jupiter (120°/240°), and Saturn (60°/270°) receive full strength (1.0), and partial aspects receive 0.25.
  - Corrected Sun minimum required Shadbala to 300.0 virupas (5.0 Rupas per BPHS), and added node thresholds (`meanNode: 360.0`, `trueNode: 360.0`, `ketu: 300.0`, `saturn: 300.0`) in `_minimumShadbala`.
- **Bhava Chalit & House Strength**:
  - Corrected mid-cusp boundary index arithmetic in `BhavaChalitService` (`midCusps[(i + 11) % 12]` entering, `midCusps[i]` exiting).
  - Preserved Whole Sign house invariant so Whole Sign natal and varga charts (`'Whole Sign (Varga)'`) strictly match Rashi placements (0 shifted planets).
  - Added Ketu to `BhavaChalit.shiftedPlanets`.
  - Corrected aspect vector to `(houseCusp - planetLongitude + 360) % 360` in `HouseStrengthService` (aspects cast forward from planet to cusp).
  - Removed artificial `virupas * 4.8` multiplier in `BhavaBalaService`, and updated `BhavaStrengthCategory` enum thresholds directly to raw virupas (480-∞ veryStrong, 420-480 strong, 360-420 moderate, 300-360 weak, 0-300 veryWeak).
- **Dignity, Compatibility & Natural Friendship**:
  - Reordered `moolaTrikona` check before `ownSigns` in `DivisionalChartService`, restoring the 45.0 Saptavargaja and 18.0 Vimsopaka tiers for Sun, Mars, Mercury, Venus, and Saturn.
  - Natural friendship (Naisargika Maitri) in `RelationshipCalculator`: BPHS Moolatrikona-derived directed relations preserved across all charts.
  - Fixed Tara Koota in `CompatibilityService` to use 3-cycle grouping (`group != 2` awards 1.5 points).
  - Corrected Jupiter deep debilitation degree to 275.0° (Capricorn 5°) in `VedicChartService`.
  - Corrected Abhijit Nakshatra end longitude to 280.8888889° in `nakshatra.dart`.
  - Consistently aligned transit special aspects to directed Parashari drishti (Mars 4th at 90°, 8th at 210° forward).
  - Clamped `totalBala` in `ShadbalaService` to $\ge 0.0$ so negative Planetary War (Yuddha Bala) deductions preserve signal without allowing total Shadbala or Shadbala ratio to drop below zero.
  - Replaced deprecated `CalculationFlags.defaultFlags()` with `CalculationFlags.traditionalist()` in `TransitService`, dynamically aligned transit node type to `natalChart.flags.nodeType`, and added transit Ketu calculation.
  - Added Rahu and Ketu to sign planet counting in `JaiminiService` and `ArudhaPadaService`.
  - Added JSON serialization (`toJson` and `fromJson`) for `CalculationFlags`, and preserved `calculationFlags`, `positionInSub`, and `subSpan` in `VedicChart` and `VedicPlanetInfo` roundtrips.
- **Panchanga & Dasha Systems**:
  - Anchored Amanta lunar month calculation to Sun's longitude at preceding New Moon (Amavasya), ensuring month name constancy across the full synodic cycle across mid-month Sankrantis.
  - Fixed Yogini dasha starting index offset (`(nakshatraIndex + 3) % 8`), Ashtottari nakshatra group distribution `[4, 3, 4, 3, 4, 3, 4, 2]` (Rahu 4, Venus 2), exact duration millisecond consistency, Mahadasha level 0 / Antardasha level 1 bookkeeping.
  - Kalachakra dasha: synchronized `duration` to exact milliseconds matching `endDate`.
  - Fixed `DashaPeriod.isActiveAt` boundary to `!date.isBefore(startDate) && date.isBefore(endDate)` (`[startDate, endDate)`), eliminating false-negatives at exact transition points.
  - Updated `YogaInfo.nature` and `YogaDetails` (Vajra 15) to consistently reflect classical inauspicious Nitya Yogas (Vishkumbha 1, Vajra 15, Parigha 19) and corrected Karana nature classification.
  - Fixed `AstrologyTimeService.localToUtc` and `utcToLocal` fallbacks to construct explicit UTC/local representations instead of defaulting to host machine's local timezone.
  - Corrected Narayana dasha subperiods: rotated to start from `mahadashaSign` and normalized proportions by total years so all 12 subperiods execute without premature truncation.
- **Divisional Charts (D5 & D30) & Classical Algorithms**:
  - Fixed D5 Panchamsa signs to strictly adhere to BPHS Ch. 6 Sloka 8: odd signs map to `[Aries, Aquarius, Sagittarius, Gemini, Libra]`, even signs map to `[Taurus, Virgo, Pisces, Capricorn, Scorpio]`.
  - Fixed D30 Trimsamsa degree scaling: degrees in varga signs now scale proportionally within each unequal span across 30° instead of linear modulus.
  - Exposed public `calculateVargaLongitude` on `DivisionalChartService` and cached service instance in `VedicChart.isVargottama`.
  - Implemented complete 5-point Panchadha Maitri arithmetic in `RelationshipCalculator.calculateCompound` (+2 Great Friend to -2 Great Enemy), handling neutral temporary relationships accurately.
  - Excluded `Planet.moon` from Lagna Kendra check in `kemadruma_yoga` evaluation.
  - Corrected opposition aspect `exactOrb` to `angularDiff - 180`, ensuring proper `isApplying`/`isSeparating` detection.
  - Added negative angle and wrap-around guards across `Rashi`, `PlanetPosition`, and `VedicChart.getHouseForLongitude`.
  - Made `CalculationFlags.fromJson` enum matching case-insensitive and aliased both node enum keys in `TransitService`.

---

## [2.20.0] - 2026-09-18

### Added
- **Multi-Isolate Concurrency & `JyotishCompute`**:
  - Implemented `JyotishCompute` (`jyotish_compute.dart`) providing safe, serialized background isolate computation via `JyotishCompute.run()` off the Flutter UI isolate.
  - Documented Swiss Ephemeris C process-global static state and isolate concurrency constraints on `EphemerisService`.
- **Fast-Path Daily Sunrise Arithmetic**:
  - Added `VedicTime.fromSunrises(time, currentSunrise, nextSunrise)` to calculate precise Vedic time directly from pre-computed daily sunrise bounds without hitting native C-FFI.
  - Implemented daily sunrise bounds caching in `VedicDigitalClock` and `VedicAnalogClock`, eliminating 2–4Hz native C-FFI polling and reducing UI thread battery/CPU overhead.
- **Integration & Widget Test Suites**:
  - Added `test/widget_rendering_test.dart` exercising `VedicChartView` (North & South styles), `VedicDigitalClock`, `VedicAnalogClock`, and CustomPainter repaint behavior.
  - Added `test/comprehensive_services_test.dart` testing previously uncovered services (`AspectService`, `StrengthAnalysisService`, `GocharaVedhaService`, `JaiminiService`, `ArudhaPadaService`, `TajakaService`, `NadiService`).
  - Total passing tests grew to 190 tests (+20 new tests) with +933 additional covered lines.

### Refactored & Optimized
- **CustomPainter Repaint Performance**:
  - Implemented property-based equality checks in `shouldRepaint()` across `NorthIndianChartPainter` and `SouthIndianChartPainter`, eliminating wasteful repaint cycles and text layout recalculations on ancestor widget rebuilds.
- **Data Model Const Optimization**:
  - Refactored `GeographicLocation` constructor to be `const` with assert initializers, converting call sites across services and tests to `const` allocations.
- **Clock Widget Lifecycle**:
  - Improved `VedicDigitalClock` and `VedicAnalogClock` to properly react to controller and location changes in `didUpdateWidget()`.

### Fixed & Packaging
- **Android Gradle Cleanup**:
  - Removed redundant `android/build.gradle.kts` and unified Android configuration in `android/build.gradle` under namespace `com.jyotish` and version `2.20.0`.
- **Windows Binary Bundling**:
  - Added `jyotish_bundled_libraries` to `windows/CMakeLists.txt` to ensure `swisseph.dll` is automatically bundled with host Flutter application executables.
- **iOS Linker & Sandboxing Compatibility**:
  - Updated `ios/jyotish.podspec` to version `2.20.0`.
  - Added `DynamicLibrary.process()` and dynamic framework fallback loading in `swisseph_bindings.dart` for standard iOS app sandbox compliance.

---

## [2.19.0] - 2026-08-25

### Added
- **Public API & Facade Expansion**:
  - Added `getSamvatInfo({required dateTime, required location})` on `Jyotish` facade for Vikram, Shaka, Gujarati Samvat and 60-year Jovian Samvatsara calculations.
  - Added `getAyana({required dateTime, required location})` on `Jyotish` facade for Uttarayana and Dakshinayana solar course determinations.
  - Added `getPravishte({required dateTime, required location})` on `Jyotish` facade for solar day (1–31) and solar sign month calculations.
  - Added `calculateYoni(boyNakshatra, girlNakshatra)` on `Jyotish` facade for classical 14x14 animal matrix compatibility scoring.
  - Added `calculateDashaCompatibility(boyChart, girlChart)` and `checkDoshas(boyChart, girlChart)` forwarding methods to the `Jyotish` facade.
  - Added `VedicChartView` Flutter widget in `chart_renderer.dart` wrapping `NorthIndianChartPainter` and `SouthIndianChartPainter` for declarative UI chart rendering.
- **macOS Platform Support**:
  - Added `macos/jyotish.podspec` and macOS FFI plugin headers/stubs to support macOS desktop builds out of the box.
- **Continuous Integration**:
  - Added GitHub Actions CI workflow (`.github/workflows/ci.yml`) covering code formatting, static analysis (`flutter analyze`), and unit test suite execution (`flutter test`).

### Refactored & Optimized
- **Dependency Streamlining**:
  - Removed `dartx` from `dependencies` and migrated all 9 import sites across `lib/` to standard, idiomatic Dart collections, Map comprehensions, and `DateTime` methods.
  - Dropped 32 transitive dependencies (`analyzer`, `args`, `shelf`, `yaml`, `crypto`, etc.) from downstream consumer application bundles.
  - Removed `test` from `dev_dependencies` and migrated all test suites to `package:flutter_test`.
- **Documentation & AI Agent Skills Alignment**:
  - Fully repaired `API_REFERENCE.md`: corrected signature drifts, documented 16 previously omitted facade methods, removed phantom duplicate model blocks, and added model documentation for `SamvatInfo`, `Ayana`, `PravishteInfo`, `MasaInfo`, and `SpecialYoga`.
  - Synchronized `SKILL.md` with active codebase method signatures, record syntax (`.tithiNumber`, `.start`, `.end`), and calculation gotchas (Brahma Muhurta, Abhijit Muhurta).

### Changed & Breaking Changes
- **Facade Exception Contract**:
  - The `Jyotish` facade now rethrows specific `JyotishException` subclasses (`CalculationException`, `PolarRegionException`, `InitializationException`, `ValidationException`, `AyanamsaMismatchException`) directly, ensuring `on CalculationException` and `on PolarRegionException` catch blocks work as documented.
- **Obliquity & Rise/Set Exception Propagation**:
  - `EphemerisService.getObliquity()` now throws `CalculationException` when Swiss Ephemeris C fails instead of returning a hardcoded `23.44°`. Callers in extreme conditions should handle `on CalculationException`.
  - `EphemerisService.getRiseSet()` now only returns `null` for legitimate circumpolar / polar region events and throws `CalculationException` on calculation failures.
- **Cache Key Timezone Awareness & LRU Eviction**:
  - Added `location.timezone` to cache keys in `EphemerisService` (`_planetPositionCache`, `_housesCache`, `_sunriseSunsetCache`) to prevent incorrect cache hits when calculating for identical timestamps in different timezones. Cache eviction updated to true LRU.
- **Process-Global C Concurrency Lock & Ephemeris Singleton**:
  - Unified Swiss Ephemeris synchronization under `SwissEphBindings.lock` across `EphemerisService` and `EclipseService` to prevent native C state corruption.
  - `EphemerisService()` now returns a shared singleton instance by default, with `EphemerisService.standalone()` available for isolated lifecycles.
  - Added event loop yields (`await Future.delayed(Duration.zero)`) inside `EclipseService` batch prediction loops to prevent UI frame starvation.
- **Shadbala Aspect Precision**:
  - Replaced strict floating-point equality (`== 180.0`) with epsilon tolerance (`< 1e-4`) in `_getAspectStrengthMultiplier()` and `_getMaxOrbForAspect()`.
- **SDK Floor Bump**:
  - Bumped minimum Dart SDK constraint in `pubspec.yaml` to `sdk: ">=3.8.0 <4.0.0"` for compatibility with `flutter_lints: ^6.0.0`.
- **Packaging & Repository Hygiene**:
  - Excluded `ephe/` data files, compiled binaries (`.dll`, `.so`, `.dylib`), and `doc/api/` from pub packaging via `.pubignore`.
  - Untracked committed Gradle cache files in `android/.gradle/`.
  - Harmonized `.github/CONTRIBUTING.md` with `CONTRIBUTING.md`.

---

## [2.18.0] - 2026-07-22

### Added
- **Data Model Serialization & Immutability (`toJson`, `fromJson`, `copyWith`)**:
  - Implemented 2-way JSON serialization (`toJson()` / `fromJson()`) and `copyWith()` state manipulation across core models (`VedicChart`, `PlanetPosition`, `VedicPlanetInfo`, `HouseSystem`, `DashaPeriod`, `DashaResult`).
- **Dependency Optimization & Cleanup**:
  - Moved `intl` to `dev_dependencies` (used strictly in test verification).
  - Explicitly pinned `test: ^1.24.0` in `dev_dependencies` for `package:test` test suites.
  - Enhanced `swisseph_bindings` and `ephemeris_service` with `package:path` for robust cross-platform path building and normalization.
- **Structured Service Logging**:
  - Integrated `Logger` from `package:logging` across core services (`VedicChartService`, `PanchangaService`, `DashaService`, `ShadbalaService`) for calculation diagnostics and warning reporting.
- **Documentation & Unit Tests**:
  - Added `test/serialization_test.dart` covering JSON serialization and `copyWith` state manipulation.
  - Updated `USAGE.md` and `API_REFERENCE.md` with new model API signatures and serialization usage guides.

## [2.17.0] - 2026-07-04

### Added
- **Calculation Caching & Memoization**:
  - Implemented memory-bounded in-memory caching (max 5,000 items) inside `EphemerisService` for high-precision Swiss Ephemeris FFI calls, covering planetary positions, house systems, and sunrise/sunset timings.
  - Exposed `clearCache()` on the `Jyotish` core facade.
- **Astro-Chart Rendering Engine**:
  - Added a new `chart_renderer.dart` module providing high-fidelity SVG exports (`VedicChart.toSVG()`) for both South Indian (grid-based) and North Indian (diamond-based) chart styles.
  - Exposed Flutter `CustomPainter` canvas painter classes (`SouthIndianChartPainter` and `NorthIndianChartPainter`) to natively draw astrological charts in Flutter widgets.
- **Dynamic Timezone Database Loading**:
  - Added `loadTimezoneDatabase(List<int> bytes)` to allow developers to dynamically load newer IANA `.tzf` timezone databases at runtime without needing library updates.
- **Lazy Dasha Streams**:
  - Implemented `streamVimshottariDasha()` yielding nested Dasha periods lazily as a Dart stream to prevent memory bloat when scanning micro-periods.
- **Ashtakavarga Reductions (Shodhana) & Shodhya Pinda Corrections**:
  - Corrected sign multipliers (Rashi Gunakara) and planetary multipliers (Graha Gunakara) in `AshtakavargaService` to match classical Parashari values.
  - Corrected Graha Pinda calculation to evaluate only occupied signs in the birth chart using the occupying planet's multiplier.
- **Vimshopaka Bala Point Scale Corrections**:
  - Updated dignity points in `_getVimshopakaPoints` to align with the classical Parashari 20-point scale.

## [2.16.0] - 2026-06-20

### Added
- **Auspicious Muhurtas Comprehensive Scoring Engine**:
  - Implemented `MuhurtaScoringService` to evaluate time suitability on a 0-100% scale using weighted scores for Tithis, Nakshatras, Weekdays (Varas), Yogas, and Karanas, along with optional native Tarabalam/Chandrabalam factors.
  - Added `scanMuhurtaSuitability` to scan and identify the most auspicious Muhurtas over a specified window.
- **Specialized Jaimini & Nakshatra Dasha Systems**:
  - Exposed and fully tested Jaimini Chara Dasha, Narayana Dasha, and Kalachakra Dasha engines via `Jyotish` core and facade APIs, supporting sub-period sequences and balance calculations.
- **Double-Precision Junction Guardrails**:
  - Added coordinate snapping (`_adjustJunctionBoundary` and `_snapKPLongitude`) with a `1e-11` precision margin in `DivisionalChartService` and `KPService` to protect division and sign boundaries from floating-point representation errors.
  - Applied epsilon subtraction guardrails to Vimshottari dasha sub-lord division boundaries to eliminate edge-case errors.
- **Polar Region Sunrise/Sunset Fallbacks**:
  - Implemented a robust polar region fallback in `PanchangaService`. When Swiss Ephemeris returns `null` for sunrise/sunset (during polar day/night), it calculates apparent solar noon (meridian transit) and splits the day/night into equal 12-hour segments to prevent downstream service crashes.
- **Rahu/Ketu Node Type Consistency**:
  - Updated Ketu calculation logic in `EphemerisService` to check `CalculationFlags.nodeType` and resolve dynamically from either `Planet.trueNode` or `Planet.meanNode` matching Rahu, preventing node alignment mismatch.
- **Altitude Propagation**:
  - Propagated observer elevation/altitude to `VedicChart` and all local astronomical sub-services (Shadbala, Prashna, Muhurtas, etc.) to replace sea-level defaults and improve precision.

## [2.15.0] - 2026-06-19

### Added
- **High-Precision End-Times & Junctions for Nakshatras and Yogas**:
  - Implemented `getNakshatraEndTime`, `getYogaEndTime`, `getNakshatraJunction`, and `getYogaJunction` in [PanchangaService](file:///E:/jyotish-flutter-library-fork/lib/src/panchanga/panchanga_service.dart) using high-precision binary search.
  - Refactored `getTithiEndTime` and `getTithiJunction` wrap-around boundary logic using signed angular differences to prevent search direction bugs near 360°/0° crossings.
- **KP Sub-Sub-Sub-Lord (SSSL) Support**:
  - Added the `subSubSubLord` field to the `KPDivision` class and implemented `_calculateSubSubBoundaries` and `_calculateSubSubSubLord` in [KPService](file:///E:/jyotish-flutter-library-fork/lib/src/systems/kp_service.dart) to support micro-level astrological event timing.
- **Dynamic Obliquity of the Ecliptic in Shadbala**:
  - Implemented dynamic obliquity calculations using Swiss Ephemeris (`SE_ECL_NUT` / planet ID `-1`) in `EphemerisService.getObliquity`.
  - Integrated dynamic obliquity into Shadbala's `_calculateAyanaBala` to replace the static `23.45°` hardcoded constant.
- **Time-Varying & Ayanamsa-Specific Precession Corrections**:
  - Refactored planetary velocity corrections in `calculatePlanetPosition` to calculate the precession rate dynamically by taking the difference between tomorrow's and today's ayanamsa. This automatically accounts for both time-varying precession drift and ayanamsa-specific reference frames.
- **Exposed Atmospheric Refraction Parameters**:
  - Exposed `atmosphericPressure` and `atmosphericTemperature` parameters in `calculatePanchanga` to allow precise Sunrise/Sunset calculations under variable local atmospheric conditions.

## [2.14.0] - 2026-05-31

### Added
- **Natal & Conjunction Dosha Detection Engine**:
  - Implemented a comprehensive, high-precision dosha detection module at par with PyJHora, capable of identifying 8 key Vedic astrological flaws (Doshas) in natal charts.
  - **Kala Sarpa Dosha**: Detects if all traditional planets are hemmed between Rahu and Ketu. Resolves 12 specific types (Anant, Kulik, Vasuki, Shankhapal, Padma, Mahapadma, Takshak, Karkotak, Shankhachur, Ghatak, Vishdhar, Sheshnag) based on Rahu's house placement.
  - **Manglik Dosha**: Evaluates Mars placement relative to Lagna, Moon, and Venus. Integrates 17 BV Raman exceptions (such as Leo/Aquarius sign, Yoga Karaka Lagna, combustion, conjunctions with Jupiter/Moon, aspect from Saturn, and retrograde status) to calculate accurate Manglik cancellation status.
  - **Pitru Dosha**: Scans ancestral karmic afflictions using 5 classical rules (such as Sun/Moon/Rahu in the 9th house, Ketu in the 4th house, and Saturn/Mars afflictions to Sun/Moon/Nodes). Includes detailed remedies and factors matched.
  - **Guru Chandala Dosha**: Identifies Jupiter-Rahu/Ketu conjunctions, including planet strength evaluation to determine if Jupiter is stronger, which mitigates/cancels the dosha.
  - **Ganda Moola Dosha**: Scans if the Moon at birth is in one of the 6 Ketu/Mercury junction Nakshatras (Ashlesha, Magha, Jyeshtha, Mula, Revati, Ashwini).
  - **Kalathra Dosha**: Checks for natural malefic placements in spouse/partner houses (1st, 2nd, 4th, 7th, 8th, and 12th) from Lagna and Moon.
  - **Ghata & Shrapit Conjunction Doshas**: Scans for Mars-Saturn (Ghata) and Saturn-Rahu (Shrapit) conjunctions in the same house.
  - Exposed `checkNatalDoshas(chart)` through the main `Jyotish` facade, and `DoshaService().calculateFullDoshaReport(chart)` for direct usage.
  - Added unit test suite `test/dosha_test.dart` to verify logic accuracy.

## [2.13.0] - 2026-05-31

### Added
- **Natal & Raja Yoga Detection Engine**:
  - Implemented a comprehensive, high-precision yoga detection module at par with PyJHora, capable of identifying 287 different standard and Raja yogas in natal charts.
  - Added support for Sun/Moon flanking configurations (Vesi, Vosi, Sunapha, Anapha, Duradhara, Kemadruma Yogas).
  - Added full evaluation for Pancha Mahapurusha Yogas (Ruchaka, Bhadra, Hamsa, Malavya, Sasa).
  - Added complete Nabhasa Yogas suite (3 Aasraya Yogas, 2 Dala Yogas, 8 Aakriti Yogas, 7 Sankhya Yogas).
  - Added core Raja Yogas (Dharma-Karmadhipati, Vipareetha, and Neecha-Bhanga) with automatic debilitation cancellation rules.
  - Added `NatalYoga` model representing a detected yoga, its criteria, benefits, presence status, and dynamic explanation.
  - Added a high-level delegate method `detectNatalYogas(VedicChart chart)` in `Jyotish` core.
  - Added unit test suite `test/natal_yoga_test.dart` to verify logic correctness using mock longitudinal configurations.
- **Vedic Clock & Vedic Time Enhancements**:
  - Added round-trip conversion method `toDateTime()` in `VedicTime` to calculate Gregorian `DateTime` from traditional Vedic time (Ghati, Vighati, Lipta).
  - Refactored `VedicDigitalClock` and `VedicAnalogClock` widgets to use modern Flutter `super.key` and non-deprecated `.withValues(alpha: ...)` for color opacities.
  - Cleaned up all compile warnings and static analysis lints across newly introduced modules (such as unused variables, comment references, and curly brace block control flow).

## [2.12.0] - 2026-05-30

### Added
- **Tajika Varshapal (Solar Return) Engine Enhancements**:
  - **True Solar Return Moment**: High-precision binary search on UTC time to find the exact millisecond the transiting Sun returns to its natal longitude, with clean local timezone conversion.
  - **Panchavargiya Bala**: Standard 5-fold planetary strength calculation (Kshetra, Hadda, Drekkana, Navamsa, and Uccha Bala).
  - **Varshesh Determination**: Precise Year Lord selection utilizing the five candidate planets (Panchadhikaris) with aspect checks to Lagna and priority tie-breaking.
  - **Mudda Dasha**: Scaled annual Vimshottari periods based on the annual Moon's Nakshatra, adjusting start balance and cycling through all planetary periods.

---

## [2.11.0] - 2026-05-25

### Added
- **Calculation Stability & Concurrency**:
  - Enhanced thread-safety and shared locking across background astronomical calculations.
  - Improved Julian Day translation accuracy for boundary dates.

---

## [2.10.0] - 2026-05-18

### Added
- **Tree-Shaking & Modular Barrel Files**: Added 9 independent barrel files representing logically isolated sub-modules. Consumers can now import micro-targeted modules directly instead of the heavy all-in-one barrel to optimize compiled bundle sizes and avoid cross-module export leaks:
  - `package:jyotish/core.dart` — Common models, enums, calculation flags, and base exceptions (`Jyotish`, `GeographicLocation`, `CalculationFlags`, `Planet`, `Rashi`, etc.)
  - `package:jyotish/analysis.dart` — Chart structures, divisional charts, compatibility Guna Milan, aspects, progeny, event timing, and Sudarshan Chakra
  - `package:jyotish/astronomy.dart` — Precision coordinate translations, astronomy time service, Udaya Lagna, and ephemeris structures
  - `package:jyotish/muhurta.dart` — Auspicious timings, Hora/Choghadiya services, Gowri Panchangam, Tarabalam/Chandrabalam, and ritual selectors
  - `package:jyotish/nadi.dart` — Nadi leaf prediction engines and services
  - `package:jyotish/panchanga.dart` — Core 5 limbs of time (Tithi, Vara, Nakshatra, Yoga, Karana) and Masa services
  - `package:jyotish/strength.dart` — Shadbala, Bhava Bala, Vimshopak Bala, Graha Avasthas, and Planetary friendship relations
  - `package:jyotish/systems.dart` — Astrological engine systems (Dasha, Ashtakavarga, KP System, Varshapal, Jaimini, Prashna, Argala, Arudha Pada)
  - `package:jyotish/transit.dart` — Planetary movements, Sade Sati, transit events, Gochara Vedha, and Sarvatobhadra Chakra
- **Module Isolation & Safety**: Internal types like `VedhaSeverity` in `sarvatobhadra.dart` are hidden from external exports in `transit.dart` to prevent implementation detail leakage.
- **Tree Shaking Verification Test Suite**: Added a robust test suite (`test/tree_shaking_test.dart`) with 119 unit tests to guarantee clean compilation boundaries, verify correct export counts per module, validate selective import usage, and ensure module isolation.

---

## [2.9.1] - 2026-05-17

### Added
- **Julian Day Helper**: Added `dateTimeToJulianDay` as a public method in `EphemerisService` to allow external consumers to convert timezone-aware Dart `DateTime` objects to high-precision Julian Day floats.

---

## [2.9.0] - 2026-05-16

### Added
- **JSON Serialization**: Full serialization support via `toJson()` across core models (`VedicChart`, `HouseSystem`, `VedicPlanetInfo`, `KetuPosition`, `PlanetPosition`). Deeply nested objects are natively supported for easier cross-isolate processing and caching.
- **Sanskrit Localization (IAST)**:
  - `Planet` enum now includes `sanskritName` (e.g., `Sūrya`, `Candra`).
  - Added `ascendantSignSanskrit` to `HouseSystem`.
  - Added `nakshatraSanskrit` to `PlanetPosition` using proper IAST (e.g., `Āśleṣā`).

### Fixed
- **Jaimini Chara Karakas**: Fixed calculation to include the full 7 or 8 Karaka ranking system (AK, AmK, BK, etc.). Default behavior respects the 8-Karaka scheme. Exposed via `getCharaKarakas()`.
- **Chara Dasha Sub-periods**: Resolved a bug where `levels` parameter was ignored. Chara Dasha now recursively calculates sub-periods (Antardashas) to the requested depth. Mahadasha levels correctly reflect depth `0`.
- **Cleanup**: Removed circular `KPService` imports in configuration flags.

---

## [2.8.0] - 2026-05-02

### Added — Special Muhurta Yogas
Implemented high-precision calculation of specialized Vedic auspicious and repetitive Yogas. These are automatically identified based on the overlap of Weekday, Tithi, and Nakshatra periods.

- **Sarvartha Siddhi Yog**: Weekday + Nakshatra combinations for general success in all activities.
- **Amrit Siddhi Yog**: Highly powerful Weekday + Nakshatra pairings for significant tasks.
- **Guru Pushya Yog**: The "King of Yogas" occurring when Thursday coincides with Pushya Nakshatra.
- **Ravi Pushya Yog**: Highly auspicious timing when Sunday coincides with Pushya Nakshatra.
- **Dwi Pushkar Yog**: Repetitive Yoga (Sun/Tue/Sat + Bhadra Tithi + Dwi-pada Nakshatra) that doubles the result of an event (good or bad).
- **Tri Pushkar Yog**: Repetitive Yoga (Sun/Tue/Sat + Bhadra Tithi + Tri-pada Nakshatra) that triples the result of an event.

#### Updated API
- **`Muhurta` model**: Added `specialYogas` field containing a list of `SpecialYoga` objects active for the day.
- **`MuhurtaService`**: Updated `calculateMuhurta` to optionally accept `tithiPeriods` and `nakshatraPeriods` to enable these calculations.
- **`SpecialYoga`**: New model representing a yoga period with `type`, `startTime`, `endTime`, and `isAuspicious` flag.

---

## [2.7.0] - 2026-04-10

### Added
- **Astronomical Precision Updates**:
  - Fine-tuned topocentric parallax corrections for lunar and planetary rise/set times.
  - Enhanced twilight and diurnal circle approximations for non-polar regions.

---

## [2.6.0] - 2026-02-25

### Added — High-Precision Eclipse & API Completeness
We have vastly improved the calculation of solar and lunar eclipses by exposing and integrating explicit local visibility functions from the underlying Swiss Ephemeris C-library (`swe_sol_eclipse_when_loc`, `swe_lun_eclipse_when`, etc.). 

- **Local Solar Eclipse Precision**: `EphemerisService.getEclipseData()` now accurately determines if a solar eclipse is visible at the provided `GeographicLocation`. It no longer defaults to global visibility, but instead accurately computes local obscuration magnitudes, contact times, and duration.
- **Accurate Lunar Penumbral Phases**: Fixed bugs where `P4` (Penumbral End) contact times were mapping to incorrect pointers in memory. Lunar Eclipses now capture global `P1` and `P4` accurately alongside the primary `U1` to `U4` umbral contacts.
- **`calculateLunarEclipseHow`** — wraps `swe_lun_eclipse_how`; returns umbral
  and penumbral magnitudes and 20 eclipse attributes at a given moment.
- **`findLunarEclipseWhen`** — wraps `swe_lun_eclipse_when`; returns the full
  `tret[0..9]` contact-time array for the next eclipse after a given JD.

#### New `EclipseData` Fields
| Field | Description |
|---|---|
| `penumbralMagnitude` | Fraction of Moon's diameter in penumbra (e.g. 2.18) |
| `penumbralStartTime` | P1 – first contact with penumbra |
| `penumbralEndTime` | P4 – last contact with penumbra |
| `partialStartTime` | U1 – first contact with umbra |
| `partialEndTime` | U4 – last contact with umbra |
| `totalStartTime` | U2 – total phase begins |
| `totalEndTime` | U3 – total phase ends |
| `moonrise` | Moonrise at observer's location (UTC) |
| `moonset` | Moonset at observer's location after moonrise (UTC) |

#### New `EclipseData` Getters
| Getter | Description |
|---|---|
| `localStartTime` | Later of U1 and moonrise (eclipse visible start for observer) |
| `localEndTime` | Earlier of U4 and moonset (eclipse visible end for observer) |
| `localDuration` | Duration of eclipse as seen from observer's location |
| `isPenumbralOnly` | True when magnitude ≤ 0 but penumbral magnitude > 0 |
| `sutakForSensitive` | 3-hour Sutak for children, elderly, and the sick |

#### Updated Sutak Logic
`sutakStartTime` and `sutakForSensitive` now anchor to `localStartTime`
(moonrise if after U1) rather than global U1. This correctly models the
traditional rule that Sutak applies from when the eclipse is *observable* at
the observer's location.

#### `getRiseSet` Enhancement
Added optional `searchFromExactTime` parameter (default `false`). When `true`,
the search begins at the exact DateTime provided rather than the start-of-day
UTC — used internally to find moonset *after* moonrise.

#### Verification (New Delhi — 03 March 2026 Total Lunar Eclipse)
```
P1 – 14:14 IST  [Ref: 14:16]   ✅
U1 – 15:20 IST  [Ref: 15:21]   ✅
U2 – 16:34 IST  [Ref: 16:35]   ✅
Max – 17:03 IST [Ref: 17:04]   ✅
U3 – 17:32 IST  [Ref: 17:33]   ✅
U4 – 18:47 IST  [Ref: 18:46]   ✅
P4 – 19:53 IST  [Ref: 19:52]   ✅
Umbral Magnitude  1.1482  [Ref: 1.14]   ✅
Penumbral Mag     2.1814  [Ref: 2.18]   ✅
Local Start  18:22 IST   [Ref: 18:26]   ✅
Local End    18:47 IST   [Ref: 18:46]   ✅
```

## [2.5.0] - 2026-02-25

### Added — `AstrologicalSystem` Enum & System Clarity

This release formalises the split between the **Traditional Parashari / KN Rao**
paradigm and the **Krishnamurti Paddhati (KP)** system. Mixing paradigms was a
source of subtle, silent bugs (e.g., KP Sub-Lord tables computed against Lahiri
ayanamsa). Library users now get compile-time clarity, runtime guard-rails, and
**automated configuration** (using `CalculationFlags.kp()` now automatically
selects the Placidus house system).

#### New: `AstrologicalSystem` enum (`calculation_flags.dart`)

```dart
enum AstrologicalSystem { traditional, kp }
```

| Value | Ayanamsa | House System | Node | Use for |
|---|---|---|---|---|
| `traditional` | Lahiri | Whole-Sign / Equal | Mean Node (BPHS) | Parashari, KN Rao, BPHS, Jaimini, Shadbala, all Dasha systems |
| `kp` | KP VP291 | **Placidus** (mandatory) | True Node | KP Sub-Lords, Significators, Ruling Planets, cuspal interlinks |

#### Updated: `CalculationFlags`

- **New field**: `system` (`AstrologicalSystem`, default `traditional`).
- **New convenience getters**: `isKP` and `isTraditional`.
- **Updated `copyWith`**: now accepts `system` parameter.
- **Updated `toString`**: includes `system` name.
- All factory constructors now explicitly set `system`:
  - `CalculationFlags.traditionalist()` → `AstrologicalSystem.traditional`
  - `CalculationFlags.modernPrecision()` → `AstrologicalSystem.traditional`
  - `CalculationFlags.kp()` → `AstrologicalSystem.kp`
  - `CalculationFlags.sidereal()`, `.siderealLahiri()`, `.topocentric()`, `.withNodeType()` → `AstrologicalSystem.traditional`

#### Updated: `VedicChart`

- **New getter**: `flags` — returns `calculationFlags ?? CalculationFlags.traditionalist()`.
  Only the existing nullable `calculationFlags` field is stored; the getter is a
  zero-breaking-change convenience accessor.

#### Updated: `KPService` — system guard-rails

`calculateKPData()` and `calculateRulingPlanets()` now assert that the supplied
chart was created with `CalculationFlags.kp()`. A clear `StateError` is thrown
if a traditional-system chart is passed by mistake:

```
StateError: calculateKPData requires CalculationFlags.kp()
(AstrologicalSystem.kp + KP VP291 ayanamsa).
Received system: traditional, ayanamsa: lahiri.
Create the chart with CalculationFlags.kp() and houseSystem: "P"
(Placidus) before calling KP-specific services.
```

### Migration Guide

Existing code that does **not** pass `CalculationFlags` to `calculateVedicChart`
continues to work unchanged (defaults to `traditional`).

Existing code that uses `KPService` and passes a non-KP chart will now receive a
`StateError` at runtime. Fix by ensuring the chart is created with the KP flags:

```dart
// Before (silently wrong — Lahiri ayanamsa used with KP tables):
final chart = await jyotish.calculateVedicChart(...);
final kpData = await jyotish.calculateKPData(chart); // ← no guard-rail

// After (correct — fails fast if wrong flags used):
final chart = await jyotish.calculateVedicChart(
  ...,
  houseSystem: 'P',               // Placidus — mandatory for KP
  flags: CalculationFlags.kp(),   // ← KP VP291 ayanamsa + system tag
);
final kpData = await jyotish.calculateKPData(chart); // ← guard-rail passes
```

## [2.4.0] - 2026-02-25

### Fixed — Missing API Surface & Implementations

- **Panchanga Service API Extension**: Exposed 5 advanced Panchanga methods directly on the `Jyotish` facade (`calculateAbhijitMuhurta`, `calculateBrahmaMuhurta`, `calculateNighttimeInauspicious`, `getTithiJunction`, `getMoonPhaseDetails`). Exported the corresponding models.
- **Gochara Vedha API Extension**: Exposed 3 transit obstruction methods (`hasMutualVedha`, `findFavorablePeriodsWithoutVedha`, `getVedhaRemedies`) and exported their models.
- **Strength Analysis API Extension**: Exposed alternate `getStrengthBhavaBala` and batch `getAllPlanetsVimshopakBala`. Exported related models.
- **Tajaka Saham Expansion**: Increased calculated Sahams from 3 to 14, implementing classical daytime/nighttime reversal logic.
- **Sarvatobhadra Chakra**: Refactored the simplified offset logic into the accurate classical 27-star Nakshatra Vedha lookup table mapping (Frontal, Left, Right aspects).
- **Graha Avastha Deeptadi**: Added the 9 `DeeptadiAvastha` states (Mood/Condition) derived from planetary dignity, combustion, and retrograde status. Added this state to the `GrahaAvastha` model.
- **Event Timing Dual-Scoring**: Enhanced the `EventTimingService` scoring engine to jointly evaluate both the Mahadasha and Antardasha lords' transits (and their Vedhas) when generating favorable event windows.

## [2.3.0] - 2026-02-25

### Added — Professional Features (Phase 2)

Integrated 9 advanced features for professional astrology analysis:
- **Configurable Ayanamsa per Chart**: Threaded `CalculationFlags` through all services to allow per-chart Ayanamsa overrides.
- **Graha Avastha**: Added `Baladi` (age-based) and `Jagratadi` (alertness-based) states mapping dignity and signs.
- **Strength Summary Report**: New `StrengthReportService` aggregating Shadbala, Vimshopaka, and Avastha.
- **Kalachakra Antardashas**: Added proportional sub-period distribution based on BPHS logic.
- **Event Timing (Dasha + Transit)**: New engine combining Dasha periods with Gochara Vedha and house transit analysis for event scoring.
- **D-10 Career Analysis**: Professional career domain analysis based on Dashamsha lord and strong planets.
- **KP 249-Division Table**: Complete system generate the 249 sub-lord boundaries with high precision.
- **Sarvatobhadra Chakra**: Transit Vedha analysis on the 27-star Nakshatra lattice for obstruction detection.
- **Tajaka Enhancements**: Annual chart expansions including Muntha, Sahams (Punya/Vidya), and Tajaka Yogas.

## [2.2.0] - 2026-02-25

### Fixed — Vedic System Accuracy & Strength Logic

This major accuracy release addresses several core discrepancies in planetary strength and relationship logic.

#### Core Models & Relationships
- **Moon→Venus Relationship**: Corrected to **Neutral** (0) per BPHS. Previously incorrectly set to Enemy (-1).
- **Rahu/Ketu Natural Relations**: Added Rahu (acts like Saturn) and Ketu (acts like Mars) entries to `RelationshipCalculator` to support full Panchadha logic.
- **Ketu Direction**: Fixed `KetuPosition.longitudeSpeed` to match Rahu exactly (negation removed).
- **Combustion Refs**: Mercury (12°/14°) and Venus (8°/10°) orbs now tighten in retrograde. All planets now use specialized orbs per BPHS rules.

#### Dignity & Friendship
- **Panchadha Maitri Implementation**: Refactored `VedicChartService` and `DivisionalChartService` to use a two-pass house mapping. Dignities now correctly account for **Temporal (Tatkalika)** friendship in every chart.
- **Vimshopaka Points**: Fixed MoolaTrikona value to 18 points (previously 10).

#### Dasha System Corrections
- **Narayana Dasha**: Fixed sign counting direction. Even signs now correctly count in reverse.
- **Yogini Dasha**: Removed incorrect +3 offset from starting lord index. Ashwini now correctly starts with Mangala.
- **Ashtottari Dasha**: Added support for 2 levels (Antardashas) with proportional segment allocation.

#### Shadbala & Aspects
- **Natonnata Bala**: Replaced binary 60/0 logic with a proportional **Day/Night arc gradient**. Strength peaks at temporal mid-points (Noon/Midnight).
- **Chesta Bala**: Implemented the traditional **8-state motion classification** (Vakra, Anuvakra, Vikala, etc.) based on planetary speed vs mean speed.
- **Rashi Drishti**: Exposed `getRashiAspects` bridge in `AspectService` for Jaimini sign-based aspects.

#### Ashtakavarga & Jaimini
- **Shodhana (Reductions)**: Implemented full **Trikona Shodhana** (trine) and **Ekadhipati Shodhana** (ownership) reductions.
- **Pinda Calculations**: Added **Rashi Pinda** and **Graha Pinda** (Yoga Pinda) with specialized multipliers for sign lords and Nodes.
- **Dual Ownership**: Implemented Mars/Ketu (Scorpio) and Saturn/Rahu (Aquarius) dual-lordship logic for sign-based dashas.
- **Atmakaraka**: Precision calculation of the **Soul Planet** based on the highest degree in natal chart.

#### KP System Accuracy
- **Significator Prediction**: Fixed **C & D significators** to use dynamically calculated Placidus house cusps instead of fixed 30° sign maps, aligning with high-precision KP software.

### Added
- **Unit Tests**: Added `relationship_test.dart`, `dignity_test.dart`, `bhava_chalit_test.dart`, and `dasha_accuracy_test.dart`.

## [2.1.0] - 2026-02-24

### Fixed — Vedic Astrology Accuracy (Panchanga & Compatibility)

This release corrects several significant discrepancies between the library's
calculations and widely-followed Vedic astrology principles (BPHS, Muhurta
Chintamani, Surya Siddhanta).

#### Panchanga (`panchanga.dart`, `panchanga_service.dart`)

- **Tithi 15 distinction**: `TithiInfo` now has separate `shuklaTithiNames` and
  `krishnaTithiNames` lists. Tithi 15 of Shukla Paksha is correctly named
  **"Purnima"** and Tithi 15 of Krishna Paksha is correctly named **"Amavasya"**.
  The old merged list `tithiNames` has been replaced with the static helper
  `TithiInfo.nameFromNumber(int tithiNumber)` which selects the correct name
  based on paksha. `masa_service.dart` is updated to use the same helper.
- **Moon illumination formula**: Corrected from an inverted linear formula
  (which showed 100% at New Moon) to the astronomically correct cosine formula:
  `((1 − cos(elongation × π/180)) / 2) × 100`. New Moon (0°) now correctly
  yields 0% and Full Moon (180°) yields 100%.
- **Moon phase names**: `_getMoonPhaseName()` previously only covered 0°–168°
  and returned "New Moon" for the entire Krishna Paksha (168°–360°). Now covers
  the full 0°–360° elongation range with correct Tithi-aligned thresholds
  (Purnima at 168°–192°, Krishna Ashtami at 264°–288°, etc.).
- **Brahma Muhurta**: Night duration was previously computed as `sunrise −
  same-day sunset`, yielding a negative value and placing Brahma Muhurta after
  sunrise. Now uses **previous day's sunset** for the correct nighttime duration.

#### Compatibility / Guna Milan (`compatibility_service.dart`)

All eight Kootas are now calculated per standard Vedic texts:

- **Yoni Koota**: Complete and correct animal map for all 27 nakshatras
  (Anuradha→Deer, Jyeshtha→Deer, Mula→Dog, P.Ashadha→Monkey,
  U.Ashadha→Mongoose, Shravana→Monkey, Dhanishta→Lion, Shatabhisha→Horse,
  P.Bhadrapada→Lion, U.Bhadrapada→Cow, Revati→Elephant — previously all
  mapped to "Tiger"). Separate friend/enemy pair logic added.
- **Varna Koota**: Classification reworked per BPHS (Brahmin: Krittika, Pushya,
  Ashlesha, Magha, U.Phalguni, Hasta, Swati, Anuradha, Shravana, P.Ashadha,
  P.Bhadrapada, Revati — and so on for other varnas).
- **Gana Koota**: Classification fixed per BPHS (Deva: Ashwini, Mrigashira,
  Punarvasu, Pushya, Hasta, Swati, Anuradha, Shravana, Revati; Manushya: 9;
  Rakshasa: Krittika, Ashlesha, Magha, Chitra, Vishakha, Jyeshtha, Mula,
  Dhanishta, Shatabhisha). Scoring: same = 6, Deva+Manushya = 3, any
  Rakshasa pair = 0.
- **Tara Koota**: Implemented the 9-tier classification (Janma, Sampat, Vipat,
  Kshema, Pratyari, Sadhaka, Vadha, Mitra, Ati-Mitra) based on Nakshatra
  distance from Moon.
- **Vashya Koota**: Added Rashi-based classification (Chatushpada, Manava,
  Jalachara, Vanachara, Keeta) to determine interpersonal control scores.
- **Graha Maitri Koota**: Was a stub returning 0. Now fully implemented with
  the BPHS natural planetary friendship table (friends/enemies/neutrals for
  each of the 7 traditional planets). Sign lords are looked up per classical
  rules (e.g. Mars rules Aries and Scorpio).
- **Bhakoot Koota**: Dosha check now covers all three problematic inter-sign
  relationships: **2/12, 5/9, and 6/8** (previously only checked for 6/12).
- **Nadi Koota**: Nadi (Adi/Madhya/Antya) now uses correct **cyclic modulo-3**
  grouping (`nakshatraIndex % 3`) instead of the incorrect sequential blocks of
  9 nakshatras.

#### Health & Doshas
- **Manglik Dosha**: Initial implementation of **Kuja Dosha** check (Mars in 1st, 2nd, 4th, 7th, 8th, or 12th houses) with high-precision longitude checking.

#### Dasha (`dasha_service.dart`)

- **Period precision**: All five Vimshottari Dasha levels (Mahadasha,
  Antardasha, Pratyantardasha, Sookshma, Prana) now use `Duration(milliseconds:)`
  instead of `Duration(days: .round())`. This prevents cumulative rounding
  errors that could cause drifts of days or weeks over a 120-year cycle.

### Changed API

| Symbol | Change |
|---|---|
| `TithiInfo.tithiNames` | **Replaced** by `TithiInfo.shuklaTithiNames`, `TithiInfo.krishnaTithiNames`, and `TithiInfo.nameFromNumber(int)` |
| `MoonPhaseDetails.illumination` | **Formula corrected** — values are now inverted relative to the old (wrong) output |

> **Migration note**: Any code referencing `TithiInfo.tithiNames[...]` directly
> must be updated to use `TithiInfo.nameFromNumber(tithiNumber)` or index into
> the appropriate paksha list. The old `tithiNames` list no longer exists.

## [2.0.0] - 2026-02-08


### Added

- **Strict Mode Validation for D249**
  - Added validation to ensure D249 uses new KP Ayanamsa only.
  - Throws `AyanamsaMismatchException` if an improper Ayanamsa is used on D249 calculation.

- **Polar Region Strictness**
  - Calculates checking for Absolute Latitude >= 66.5°.
  - Throws `PolarRegionException` when evaluating Placidus or Koch above the Arctic Circle.

- **True Node / Mean Node Configuration (Rahu/Ketu)**
  - Added new explicit standard factories `CalculationFlags.traditionalist()` and `CalculationFlags.modernPrecision()`.
  - Deprecated ambiguous `CalculationFlags.defaultFlags()`.
- **D249 - 249 Subdivisions (High-Precision Micro Analysis)**
  - Complete implementation of 249 subdivisions per zodiac sign
  - Ultra-fine granularity for advanced Vedic analysis (~0.12° per subdivision)
  - Odd sign mapping: starts from same sign, counts forward through 249 parts
  - Even sign mapping: starts from 9th sign, counts forward through 249 parts
  - Compatible with existing D1-D60 divisional chart infrastructure
  - Comprehensive test suite with 10+ test cases
  - API: `DivisionalChartType.d249`

- **Corrected Vara (Weekday) Calculation**
  - Updated `PanchangaService` to use Sunrise as the day boundary instead of midnight
  - Births between midnight and sunrise now correctly resolve to the previous day's planet lord
  - API: `jyotish.getVara()` is now asynchronous and requires `location`

- **Tithi End-Time Analysis**
  - New API for finding exact moments when a Tithi ends
  - Uses high-precision binary search with sub-second accuracy
  - API: `jyotish.getTithiEndTime()`

- **Shadbala (Six-fold Planetary Strength)**
  - Complete implementation of all 6 strength types:
    - Sthana Bala (Positional Strength)
    - Dig Bala (Directional Strength) 
    - Kala Bala (Temporal Strength)
    - Chesta Bala (Motional Strength)
    - Naisargika Bala (Natural Strength)
    - Drik Bala (Aspectual Strength)
  - `calculateShadbala()` - Calculate complete Shadbala for all planets
  - Strength categorization (Very Strong, Strong, Moderate, Weak, Very Weak)

- **Ashtakavarga Reductions (Shodhana)**
  - `applyTrikonaShodhana()` - Trine reduction for 1-5-9 groups
  - `applyEkadhipatiShodhana()` - Reduction for same sign ownership
  - `calculatePinda()` - Final planetary strength (Rupas calculation)

- **Panchanga Module**
  - Tithi, Yoga, Karana, and Vara calculations
  - High-precision sunrise and sunset times using Swiss Ephemeris
- **Ashtakavarga System**
  - Bhinnashtakavarga (BAV) for all planets
  - Sarvashtakavarga (SAV) calculation
  - Ashtakavarga-based transit strength analysis
- **KP System (Krishnamurti Paddhati)**
  - Support for KP-specific ayanamsas (New VP291, Khullar)
  - Sign, Star, Sub-Lord, and Sub-Sub-Lord calculations
  - House and planet significators
- **Special Transits**
  - Sade Sati (Saturn's 7.5 year transit) status and phase analysis
  - Dhaiya (Saturn's 2.5 year transit/Panoti) analysis
  - Panchak detection and precautions
- **Muhurta & Auspicious Timings**
  - Hourly Hora Lord calculation
  - Daytime and Nighttime Choghadiya periods
  - Inauspicious periods: Rahukalam, Gulikalam, and Yamagandam
  - Activity-based Muhurta filtering

- **Vedic Aspect Calculations (Graha Drishti)**
  - All planets aspect 7th house (opposition)
  - Mars special aspects (4th, 8th houses)
  - Jupiter special aspects (5th, 9th houses)
  - Saturn special aspects (3rd, 10th houses)
  - Applying/separating aspect detection
  - Aspect strength calculation

- **Transit Calculations**
  - Current planetary transits over natal positions
  - Transit house placements
  - Transit aspects to natal planets
  - Transit event prediction with date ranges

- **Dasha System Support**
  - Vimshottari Dasha (120-year cycle)
  - Yogini Dasha (36-year cycle)
  - Mahadasha, Antardasha, Pratyantardasha levels
  - Current period calculation
  - Birth time precision warnings

- **Yogini Dasha Antardashas**
  - Added support for sub-periods (Antardasha) in Yogini Dasha
  - Added support for sub-sub-periods (Pratyantardasha) in Yogini Dasha
  - Correctly displaying Yogini names (e.g., Mangala, Pingala) instead of planet names


### New API Methods

- `getAspects()` - Calculate all Vedic aspects between planets
- `getAspectsForPlanet()` - Get aspects involving a specific planet
- `getChartAspects()` - Calculate aspects from a VedicChart
- `getTransitPositions()` - Calculate transit positions relative to natal chart
- `getTransitEvents()` - Find significant transit events in a date range
- `getVimshottariDasha()` - Calculate Vimshottari dasha periods
- `getYoginiDasha()` - Calculate Yogini dasha periods
- `getCurrentDasha()` - Get active dasha periods at any date

### New Models

- `AspectType` - Enum of Vedic aspect types
- `AspectInfo` - Detailed aspect information
- `AspectConfig` - Aspect calculation configuration
- `TransitInfo` - Transit position data
- `TransitEvent` - Transit event details
- `TransitConfig` - Transit calculation configuration
- `DashaPeriod` - Dasha period data
- `DashaResult` - Complete dasha calculation result
- `DashaType` - Enum of dasha systems
- `Yogini` - Enum of Yogini dasha lords

### Improved

- **Precision**: Updated Panchak calculation to use precise Mean Daily Motion of Moon (13.176°) instead of approximation.
- **Ephemeris Service**: Enhanced support for rise/set transitions and topocentric corrections.
- **Vedic Chart**: Improved planet data model to support extended Vedic properties.

### Fixed

- **Planetary Friendship Calculations**
  - Now properly calculates friend, enemy, and neutral relationships
  - Added `greatFriend` (Adhi-Mitra) and `greatEnemy` (Adhi-Shatru) dignities
  - Affects dignity calculations in both Rashi and all D-Charts

- **D-Chart Dignity Calculations**
  - All divisional charts (D1-D60) now calculate dignities correctly
  - Dignities no longer default to "neutral" in D-Charts

- **Sade Sati Date Estimation**
  - Replaced constant `daysPerSign` with variable Saturn speed calculation
  - Now accounts for retrograde motion and sign-specific variations
  - More accurate start/end date predictions

- **Rahu/Ketu Distinguishability**
  - Added `lordName` field to `DashaPeriod` to properly distinguish Rahu from Ketu
  - Both planets display correctly in dasha output (e.g., "Rahu-Mercury-Venus")

- **KP Ayanamsa Calculation**
  - Now uses precise time-varying formula from Swiss Ephemeris
  - Uses `SiderealMode.krishnamurtiVP291` instead of hardcoded offset

- **Extended Dasha Support**
  - Added **Chara Dasha** (Jaimini sign-based dasha)
  - Added **Narayana Dasha**
  - Added **Ashtottari Dasha** (108-year cycle)
  - Added **Kalachakra Dasha**
  - `getDashaPeriods()` now supports all these systems

- **Jaimini Astrology Support**
  - **Atmakaraka** calculation (planet with highest degree)
  - **Karakamsa** (Atmakaraka in Navamsa) analysis
  - **Rashi Drishti** (Sign Aspects) per Jaimini rules

- **Sudarshan Chakra**
  - Complete analysis of Sun, Moon, and Ascendant charts combined
  - Visualizing planetary positions across all three reference points

- **Gochara Vedha (Transit Obstruction)**
  - Analysis of Vedha (obstruction) points for transiting planets
  - Determines if a transit's effect is blocked or modified by other planets

### Breaking Changes

- **`calculateKPData()` is now async** - Returns `Future<KPCalculations>` instead of `KPCalculations`
  - Migration: Add `await` before the call: `final kpData = await jyotish.calculateKPData(chart)`

## [1.0.1] - 2025-11-25

### Fixed

- Fixed package validation errors for pub.dev publishing
- Improved export organization (alphabetically sorted)

## [1.0.0] - 2025-10-19

### Added

- Initial release of Jyotish library
- Swiss Ephemeris integration via FFI
- Support for all major planets (Sun through Pluto)
- Lunar nodes (Mean and True Node)
- Lunar apogees (Black Moon Lilith)
- Major asteroids (Chiron, Pholus, Ceres, Pallas, Juno, Vesta)
- Tropical and sidereal zodiac calculations
- 40+ ayanamsa systems for sidereal calculations
- Geocentric and topocentric position calculations
- Retrograde detection
- Nakshatra (lunar mansion) calculations
- Zodiac sign and position calculations
- Speed/velocity calculations
- Comprehensive error handling
- Input validation
- Production-ready API
- Full documentation and examples
- Example Flutter app
- Platform support: Android, iOS, macOS, Linux, Windows

### Features

- High-precision astronomical calculations
- Easy-to-use API
- Batch planet calculations
- Flexible calculation flags
- Geographic location support with DMS conversion
- JSON serialization support
- Proper resource management

[2.19.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.19.0
[2.18.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.18.0
[2.17.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.17.0
[2.16.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.16.0
[2.15.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.15.0
[2.14.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.14.0
[2.13.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.13.0
[2.12.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.12.0
[2.11.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.11.0
[2.10.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.10.0
[2.9.1]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.9.1
[2.9.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.9.0
[2.8.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.8.0
[2.7.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.7.0
[2.6.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v2.6.0
[1.1.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.1.0
[1.0.1]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.0.1
[1.0.0]: https://github.com/rajsanjib/jyotish-flutter-library/releases/tag/v1.0.0
