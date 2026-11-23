# Spec: Today Screen & Daily Loop

## Requirements
1. **WHEN** the Today tab opens, **THE SYSTEM SHALL** display the baby in today's costume, today's need tag, and 1-2 sentences of baby greeting.
2. **WHEN** today's 3 check-ins are presented, **THE SYSTEM SHALL** display Water, Prenatal Vitamin, and the Need of the Day (or Rest when need is Water/Vitamin).
3. **WHEN** the mother taps the Need of the Day check-in, **THE SYSTEM SHALL** display a star and update the baby line to an approved thank-you message.
4. **WHEN** all 3 check-ins are ticked, **THE SYSTEM SHALL** show an approved gentle goodbye line ("That's us for today").
5. **WHEN** a new day starts, **THE SYSTEM SHALL** start with blank check-ins and normal greeting without mentioning missed days or yesterday.

## Tasks
- [x] 1. Prototype Today tab with baby speech, need tag, and 3 check-in tiles
- [x] 2. Connect daily rotation algorithm for the 6 maternal needs
- [x] 3. Implement hop animation on Need of the Day completion
- [x] 4. Store daily completion timestamps locally
