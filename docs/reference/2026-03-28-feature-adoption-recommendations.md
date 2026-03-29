# OSA / Lantern — Feature, Function & UI Improvement Recommendations

**Compiled: March 28, 2026**
**Based on:** Competitor analysis of SAS Survival Guide, Survival App, Survival AI (The Ark), Avenza Maps, OsmAnd+, Gaia GPS, OnX Hunt, Wild Edibles Forage, Seek by iNaturalist, Red Cross First Aid, and broader emergency preparedness app landscape.

---

## How This Document Is Organized

Each recommendation is categorized by the area of the app it would enhance, tagged with the competitor(s) that inspired it, and assessed for alignment with OSA's existing architecture, governance (CONSTITUTION.md), and scope boundaries. Recommendations that conflict with current safety policy are flagged accordingly.

---

## 1. Content & Knowledge Depth

### 1.1 Multimedia Content Layers
**Inspired by:** SAS Survival Guide (16 videos, photo galleries), Survival App (infographics, podcasts), Red Cross First Aid (step-by-step videos, illustrations)

OSA's handbook currently delivers text-based sections and quick cards. Competitor survival guides universally supplement text with embedded video demonstrations, high-resolution photo galleries (animal tracks, knots, edible plants, wound types), and infographics. The Red Cross First Aid app is especially effective with its illustrated step-by-step medical procedures that render clearly under stress.

**Recommendations:**
- Add support for inline illustrations and diagrams within handbook sections — even simple SVG-style line drawings for knot-tying, shelter construction, fire-starting techniques, and first aid procedures.
- Introduce a short-form video or animation slot per handbook section for critical physical skills (e.g., tourniquets, CPR rhythm, water purification). These would be bundled on-device as part of the seed content.
- Create an infographic card type alongside quick cards — a visual one-pager optimized for glanceability under stress, similar to what Survival App does well.

### 1.2 Expanded Seed Content Topics
**Inspired by:** SAS Survival Guide (extreme climate survival: polar, desert, tropical, sea), Wild Edibles Forage (250+ plant profiles with 14 categories each), Red Cross First Aid (comprehensive medical condition index)

OSA currently ships 11 chapters and 35 sections. The SAS Survival Guide covers the equivalent of 400+ pages of content across all climate zones and scenarios. Wild Edibles provides 250+ plant entries with photos, habitat, season, lookalikes, cautions, recipes, and medicinal uses — each essentially a structured data record.

**Recommendations:**
- Expand handbook to cover climate-specific survival (cold weather, desert, tropical, coastal/maritime) as distinct chapter groups.
- Add a structured "field reference" content type for plants, animals, fungi, and hazards — each entry having standardized fields (identification photos, habitat, season, cautions, uses, lookalikes). This aligns well with OSA's existing domain model pattern.
- Add a comprehensive first aid reference section modeled on the Red Cross's alphabetical condition index with step-by-step protocols.
- Include a knot reference section with animated or multi-frame illustrations, inspired by the Army Knots app.

### 1.3 Quiz & Knowledge Retention System
**Inspired by:** SAS Survival Guide (100+ question quiz), Red Cross First Aid (interactive quizzes with badges), Seek by iNaturalist (gamification with challenges and badges)

Multiple competitor apps use quizzes and gamification to help users internalize critical knowledge before they need it. The SAS Survival Guide has over 100 questions. Red Cross awards badges. Seek uses challenges and species-collection mechanics.

**Recommendations:**
- Add a "Practice" or "Drill" mode that presents scenario-based quiz questions drawn from handbook content. Questions could be multiple choice, timed identification (what plant is this?), or procedural ordering (what steps for treating shock?).
- Award completion badges or progress markers per chapter/topic — visible on the Home screen as a readiness indicator.
- Consider a "Weekly Drill" quick card that rotates through critical skills for periodic review.

---

## 2. Navigation, Mapping & Location

### 2.1 Offline Map Support
**Inspired by:** Avenza Maps (georeferenced PDF maps, GPS tracking, waypoints), OsmAnd+ (OpenStreetMap offline terrain maps, contour lines, hill shading), Gaia GPS (topographic layers, trail maps, measurement tools), OnX Hunt (150-mile downloadable areas, multiple resolution levels), Survival AI / The Ark (50-mile radius auto-download), Maps.me (fully offline turn-by-turn)

This is the single largest feature gap between OSA and the broader preparedness app ecosystem. Every serious offline survival app includes some form of downloadable maps. The Ark even auto-downloads a 50-mile radius around your location. Gaia GPS and OnX Hunt offer multiple resolution levels and rich layer support.

**Recommendations:**
- Introduce a map surface as a future milestone, using downloadable OpenStreetMap tile packs. Users would pre-download regions while online. The map view would show GPS position, allow waypoint marking, and display basic topographic features — all offline.
- Prioritize a "neighborhood/city" scale initially (5–25 mile radius) rather than full wilderness topo, since OSA's core user is a household preparedness planner.
- Add a compass and basic GPS coordinate display tool (even without full maps), since this is lightweight and immediately useful. Gaia GPS's rescue-ready coordinate formats (UTM, MGRS, lat/long) are a good model.
- Consider integration with the what3words system (as Avenza Maps does) for simplified location communication during emergencies.

### 2.2 GPS Track Recording & Waypoints
**Inspired by:** Avenza Maps (track recording with speed/elevation/time), Gaia GPS (breadcrumb trails, waypoint marking), OnX Hunt (waypoints with markup)

Even without full map tiles, GPS track recording is valuable for evacuation routes, documenting supply cache locations, and marking rally points.

**Recommendations:**
- Add a lightweight GPS track recorder that logs coordinates, timestamps, and optional notes — persisted locally in SwiftData.
- Allow users to create named waypoints (e.g., "Water source," "Rally point," "Cache") with optional notes and photos.
- Display tracks and waypoints on a minimal map view, or export as GPX for use in other apps.

### 2.3 Distance & Measurement Tools
**Inspired by:** Gaia GPS (measurement tool for on-the-spot distance checks), iPhone built-in Measure app

**Recommendation:**
- Add a simple distance estimator or measurement tool accessible from the Home screen for quick field calculations.

---

## 3. Identification & Field Reference

### 3.1 Visual Identification Support
**Inspired by:** Wild Edibles Forage (8 images per plant, poisonous lookalike comparisons), Seek by iNaturalist (real-time camera-based identification), Red Cross First Aid (visual guides for injuries)

Wild Edibles' strength is its multi-image approach with explicit "poisonous lookalikes" comparisons. Seek's real-time on-device identification using vision models is the gold standard. Red Cross uses clear visual hierarchies for medical procedures.

**Recommendations:**
- For any plant, animal, or hazard reference content, always include comparison images showing safe vs. dangerous lookalikes side by side.
- Explore on-device image recognition using Apple's Vision framework or Core ML for future versions — a user could photograph a plant and get matched against the local reference database. This aligns with OSA's offline-first principle since Core ML runs on-device.
- Add a "Visual First Aid" section with illustrated step-by-step procedures for the most common emergencies (choking, bleeding, burns, fractures, CPR).

### 3.2 Seasonal & Location-Aware Content
**Inspired by:** Wild Edibles Forage (seasonal data per plant, GPS-based location recording), Seek by iNaturalist (list of nearby organisms), Gaia GPS (weather integration)

**Recommendations:**
- Tag handbook sections and field reference entries with seasonal relevance and geographic applicability.
- On the Home screen, surface seasonally relevant content (e.g., wildfire prep in summer, hypothermia protocols in winter, storm prep during hurricane season).
- Consider a "What's relevant near me" feature that filters content based on the user's general region (PNW, coastal, mountain, desert) — selectable in Settings rather than requiring GPS.

---

## 4. Emergency & First Aid

### 4.1 Step-by-Step Emergency Protocols
**Inspired by:** Red Cross First Aid (alphabetical condition index, step-by-step "Give Care" procedures), Red Cross Resuscitation Suite (code cards, timed protocols, heads-up timers)

The Red Cross First Aid app's "Give Care" tab is its strongest feature — it provides actionable, sequential steps anyone can follow during a medical emergency. The newer Resuscitation Suite adds timed prompts for CPR cycles and medication delivery.

**Recommendations:**
- Create an "Emergency Protocols" quick-access section — a curated set of step-by-step procedures for the 10-15 most critical scenarios (CPR, choking, severe bleeding, burns, shock, allergic reaction, snake bite, hypothermia, heat stroke, broken bones, poisoning).
- Each protocol should be a large-type, single-step-per-screen flow (swipe to advance) optimized for shaking hands and high stress. This is distinct from the handbook's reference-style reading.
- Add an optional metronome/timer feature for CPR compression rhythm (100-120 BPM), inspired by Red Cross Resuscitation Suite and Pocket CPR.
- Include a "Nearest Hospital" feature using pre-cached facility data for the user's region, similar to Red Cross's offline hospital locator.

### 4.2 Emergency Contact & "I'm Safe" Messaging
**Inspired by:** Red Cross Emergency app ("I'm Safe" one-touch notification), Life360 (SOS button, family location sharing), FEMA app (family plan templates)

**Recommendations:**
- Add an "Emergency Contacts" section in Settings where users store key phone numbers and relationships.
- Implement a one-touch "I'm Safe" message composer that pre-fills an SMS to all emergency contacts with a configurable template (e.g., "I am safe. My location is [address/coordinates]. I will contact you when I can.").
- Add a "Family Emergency Plan" template in Checklists — a structured form for meeting points, out-of-area contacts, medical information, and pet plans.

---

## 5. Inventory & Supply Management

### 5.1 Enhanced Expiry & Restock Tracking
**Inspired by:** Preppr (AI-powered equipment documentation, inventory tracking), SAS Survival Guide (survival checklists)

OSA already has solid inventory with expiry dates and reorder thresholds. Several competitors offer more proactive supply management.

**Recommendations:**
- Add push notifications (local, not remote) for items approaching expiry date — configurable lead time (7 days, 30 days, 90 days).
- Implement a "Supply Readiness Score" on the Home screen — a simple percentage or visual indicator showing how prepared the household is based on recommended quantities vs. current inventory vs. expiring items.
- Add barcode/QR scanning for faster item entry using the device camera and on-device barcode recognition.
- Include recommended supply lists per scenario (72-hour kit, earthquake kit, wildfire evacuation bag, winter storm kit) that users can import into their inventory as target quantities.

### 5.2 Photo Documentation for Inventory
**Inspired by:** Wild Edibles Forage (GPS + photo per observation), Seek by iNaturalist (photo-based entries), Avenza Maps (photo annotation at locations)

**Recommendation:**
- Allow users to attach a photo to each inventory item — useful for documenting storage location, product labels, or condition. Photos stored locally in the app's container.

---

## 6. Assistant & AI Capabilities

### 6.1 Conversational History & Follow-Up
**Inspired by:** Survival AI / The Ark (conversational AI with sourced answers, study guide generation)

OSA's Ask surface currently handles single question-answer exchanges. The Ark offers a more conversational interaction model while still citing sources.

**Recommendations:**
- Add conversation context within a session — allow the user to ask follow-up questions that reference the previous answer without restating context.
- Show a "Recent Questions" history on the Ask screen so users can quickly return to previous answers.

### 6.2 Study Guide Generation
**Inspired by:** Survival AI / The Ark (offline study guides on various topics)

The Ark generates focused study guides from its knowledge base that users can browse offline.

**Recommendations:**
- Add a "Study Guide" generation feature where the assistant compiles a focused briefing on a topic (e.g., "Water purification methods") by assembling relevant handbook sections, quick cards, and imported knowledge into a single reading flow.
- These could be saved as Notes with a special "study guide" tag for later review.

### 6.3 Proactive Contextual Suggestions
**Inspired by:** The Ark (proactive guidance), Seek by iNaturalist (nearby organism suggestions), Red Cross (seasonal preparedness reminders)

**Recommendations:**
- Surface contextual suggestions on the Home screen based on season, weather conditions (when online), or user activity patterns (e.g., "You haven't reviewed your earthquake kit in 6 months").
- After a user completes a checklist, suggest related handbook sections or quick cards.

---

## 7. Communication & Connectivity

### 7.1 Offline Communication Tools
**Inspired by:** Survival AI / The Ark (offline texting via Bluetooth/mesh), SAS Survival Guide (Morse Code signaling device), Zello (push-to-talk over limited bandwidth), Signal (encrypted messaging)

The Ark recently added Bluetooth-based offline texting between devices. The SAS Survival Guide includes a Morse Code signaling tool. These represent communication capabilities that work when cellular networks are down.

**Recommendations:**
- Add a Morse Code tool — a flashlight-based signaling utility using the device's LED and a simple tap-to-send interface. This is lightweight, offline, and genuinely useful.
- Add a signal mirror guide and whistle-pattern reference in quick cards (3 blasts = distress).
- Explore Bluetooth-based device-to-device messaging for a future version — Apple's Multipeer Connectivity framework could enable short-range text exchange between nearby iPhones running OSA without any network.
- Include an emergency radio frequency reference card for common channels (NOAA weather, FRS/GMRS, amateur emergency nets).

### 7.2 Sun Compass & Orientation Tools
**Inspired by:** SAS Survival Guide (sun compass feature)

**Recommendation:**
- Add a sun compass utility that uses the device's location and time to calculate cardinal directions — useful when the digital compass is unreliable or as a backup.

---

## 8. UI/UX Improvements

### 8.1 Stress-Optimized Interface Modes
**Inspired by:** Red Cross First Aid (clear visual hierarchies for high-stress use), SAS Survival Guide (well-organized navigation), quick card design patterns across apps

OSA's quick cards already use large-type optimized layouts. This can be extended further.

**Recommendations:**
- Add an "Emergency Mode" that simplifies the entire UI to large buttons for the most critical functions: Emergency Protocols, Call 911, I'm Safe message, Quick Cards, and Flashlight. Activated via a prominent button on the Home screen or a long-press gesture.
- Increase touch target sizes throughout the app for gloved-hand or wet-hand operation.
- Add a high-contrast / dark mode optimized for nighttime or low-light conditions with red-tinted display option (preserves night vision).
- Implement haptic feedback for critical actions (completing a checklist step, sending an I'm Safe message).

### 8.2 Improved Search & Discovery
**Inspired by:** SAS Survival Guide (full-text search across entire book), OsmAnd+ (customizable map styles for different use cases), Red Cross (searchable alphabetical index)

OSA already has FTS5 search with BM25 ranking. The UX can be improved.

**Recommendations:**
- Add search suggestions/autocomplete based on popular queries and handbook section titles.
- Implement a "Browse by Scenario" entry point — instead of only chapter-based browsing, let users find content by situation (lost in woods, power outage, earthquake, flood, wildfire evacuation, winter storm).
- Add filtering in Library by content type (handbook sections, quick cards, imported knowledge) and by tag.
- Show "Related Content" links at the bottom of each handbook section (the app has related quick cards — extend this to related sections and imported knowledge).

### 8.3 Onboarding & Personalization
**Inspired by:** The Ark (proactive guidance based on situation), Gaia GPS (region-specific map downloads), OnX Hunt (state-specific content), FEMA (location-based alerts)

**Recommendations:**
- Add a first-launch onboarding flow that asks the user their region, household size, and primary concerns (earthquakes, hurricanes, wildfires, winter storms, general preparedness). Use this to prioritize content and checklist suggestions.
- Allow users to "pin" favorite handbook sections and quick cards to the Home screen for instant access to their most-needed content.
- Add a "Getting Started" checklist that guides new users through setting up their emergency contacts, creating their first inventory, and reviewing the most critical quick cards.

### 8.4 Widget & Lock Screen Support
**Inspired by:** Red Cross (quick access features), Weather apps (widget-based information), general iOS best practices

**Recommendations:**
- Create iOS Home Screen widgets showing supply readiness score, next expiring item, or a rotating quick card tip.
- Add a Lock Screen widget for instant access to Emergency Mode or the flashlight/signal tool.
- Leverage iOS Live Activities for active scenarios (e.g., when running through an emergency protocol checklist, show progress on the Lock Screen).

---

## 9. Data & Document Management

### 9.1 Document Vault
**Inspired by:** LastPass Families (encrypted document storage), FEMA (family plan templates), emergency preparedness best practices

**Recommendations:**
- Add a secure "Document Vault" for storing photos/scans of critical documents: insurance policies, IDs, medical records, prescriptions, pet vaccination records. Encrypted on-device using iOS Keychain-derived keys.
- This is one of the most universally recommended preparedness actions and no survival-focused app does it well.

### 9.2 Export & Sharing
**Inspired by:** Avenza Maps (KML/GPX/CSV export), Gaia GPS (track export), general app ecosystem interoperability

**Recommendations:**
- Add export capabilities for checklists (PDF or print-friendly format), inventory lists (CSV), and notes (plain text or markdown).
- Allow sharing quick cards or handbook excerpts via the iOS share sheet — useful for sending critical information to family members who don't have the app.

### 9.3 Offline Knowledge Expansion via Kiwix-Style Imports
**Inspired by:** Kiwix (super-compressed offline Wikipedia), The Ark (bundled expert knowledge), general offline knowledge tools

**Recommendations:**
- Explore a "Knowledge Pack" system where curated topic bundles (wilderness medicine, PNW wildfire preparedness, earthquake readiness) can be downloaded as add-on content packs. These would go through the existing import pipeline with trusted-source validation.
- This would allow OSA to remain lightweight at install (~11 MB) while offering depth on demand.

---

## 10. Tools & Utilities

### 10.1 Built-In Survival Tools
**Inspired by:** SAS Survival Guide (Morse Code device, sun compass), measurement apps, flashlight utilities

**Recommendations:**
- **Flashlight with SOS mode**: Use the device LED with automatic SOS pattern (... --- ...) toggling.
- **Whistle simulator**: High-frequency tone generator for attracting attention when a physical whistle isn't available.
- **Timer/Stopwatch**: For water purification timing, CPR cycles, medication schedules.
- **Unit converter**: Temperature (F/C), distance (miles/km), weight (lbs/kg), water volume (gallons/liters) — essential for following survival guides from different countries.
- **Declination calculator**: Magnetic declination for compass correction based on stored location.

### 10.2 Weather Integration (When Online)
**Inspired by:** Gaia GPS (weather forecasts, radar), OnX Hunt (wind direction/speed, sunrise/sunset), NWS app (severe weather alerts)

**Recommendations:**
- When online, show current weather conditions and severe weather alerts on the Home screen using NWS data (already a trusted source in OSA's allowlist).
- Cache the most recent weather data for offline reference.
- Display sunrise/sunset times and moon phase — useful for planning and navigation.

---

## 11. Accessibility & Inclusivity

### 11.1 Multi-Language Support
**Inspired by:** Red Cross First Aid (English/Spanish), Google Translate (offline language packs), FEMA (multi-language support)

**Recommendations:**
- Prioritize Spanish as the first additional language for all handbook content and UI strings.
- Consider offline translation capability for critical quick cards using on-device ML translation.

### 11.2 Accessibility Enhancements
**Inspired by:** Red Cross (screen reader support), general iOS accessibility best practices

**Recommendations:**
- Audit all screens for full VoiceOver support with meaningful labels.
- Ensure all illustrations and visual content have descriptive alt text.
- Add Dynamic Type support throughout the app if not already complete.
- Consider a simplified "large print" reading mode for handbook content.

---

## 12. Community & Social Features (Future Consideration)

### 12.1 Content Contribution Pipeline
**Inspired by:** Survival App (community contribution), iNaturalist (citizen science observations), OpenStreetMap (community mapping)

**Recommendations (post-v1):**
- Allow users to submit corrections or additions to handbook content through a moderated pipeline.
- Consider a "local knowledge" contribution feature where users can share region-specific tips (e.g., "Best water source in [area]") that go through editorial review before becoming available.

*Note: This would need careful alignment with OSA's grounding and review-before-use governance principles.*

---

## Priority Matrix

### High Impact, Lower Effort (Quick Wins)
- Morse Code signaling tool
- Emergency contacts & "I'm Safe" SMS composer
- Quiz/drill mode from existing content
- Scenario-based browsing ("Browse by Situation")
- Search autocomplete and suggestions
- Home screen widgets
- Flashlight with SOS mode
- CPR metronome timer
- Pinnable favorites on Home screen
- Getting Started onboarding checklist

### High Impact, Moderate Effort
- Step-by-step emergency protocol flow (swipe-per-step)
- Emergency Mode (simplified crisis UI)
- Illustrated first aid procedures
- Supply Readiness Score
- Push notifications for expiring items
- Document vault for critical papers
- Study guide generation from assistant
- Conversation history in Ask
- Export/sharing capabilities
- Sun compass utility
- Night vision (red-tinted) display mode

### High Impact, Higher Effort
- Offline map surface with downloadable regions
- GPS track recording and waypoints
- Multimedia content (video/animation in handbook)
- Expanded seed content (climate zones, 250+ plant reference)
- On-device plant/hazard image recognition
- Knowledge Pack download system
- Bluetooth device-to-device messaging
- Spanish language support
- Barcode scanning for inventory

---

## Alignment Notes

All recommendations are designed to respect OSA's core governance:

- **Offline-first**: Every feature works without connectivity; online features gracefully degrade.
- **Grounded answers only**: Quiz content, study guides, and protocol flows are derived from reviewed seed content — no model hallucination.
- **Safety boundaries preserved**: Foraging and medical content flagged as reference-only; no synthesis of unreviewed advice on sensitive topics.
- **Privacy-first**: Document vault uses on-device encryption; no personal data leaves the device.
- **Single-device, local-first**: No account system or cloud sync required for any feature.

---

## Sources

- [SAS Survival Guide — App Store](https://apps.apple.com/us/app/sas-survival-guide/id357811968)
- [Survival App — Offline Guidebook — App Store](https://apps.apple.com/us/app/survival-app-offline-guidebook/id1514768846)
- [Survival AI — The Ark — App Store](https://apps.apple.com/us/app/survival-ai-the-ark/id6746391165)
- [Avenza Maps — App Features](https://store.avenza.com/pages/app-features)
- [OsmAnd Maps — App Store](https://apps.apple.com/us/app/osmand-maps-travel-navigate/id934850257)
- [Gaia GPS — App Store](https://apps.apple.com/us/app/gaia-gps-mobile-trail-maps/id1201979492)
- [OnX Hunt — iPhone Features](https://www.onxmaps.com/hunt/app/features/iphone)
- [Wild Edibles Forage — App Store](https://apps.apple.com/us/app/wild-edibles-forage/id431504588)
- [Seek by iNaturalist — App Store](https://apps.apple.com/us/app/seek-by-inaturalist/id1353224144)
- [Red Cross First Aid — App Store](https://apps.apple.com/us/app/first-aid-american-red-cross/id529160691)
- [Red Cross Resuscitation Suite — Press Release](https://www.redcross.org/about-us/news-and-events/press-release/2025/american-red-cross-launches-innovative-resuscitation-app-for-rea.html)
- [TruePrepper — 10 Best Survival Apps](https://trueprepper.com/best-survival-apps/)
- [Batten Emergency — Top Emergency Preparedness Apps 2026](https://battenemergency.com/briefs/top-emergency-preparedness-apps-digital-tools/)
- [OsmAnd Review — Backdrop Journal](https://www.backdropjournal.com/kit-junkies/review-osmand-mapping)
- [Gaia GPS Review — Coffs Trails](https://www.coffstrails.com/review-of-gps-hiking-navigation-apps-why-i-use-gaiagps/)
