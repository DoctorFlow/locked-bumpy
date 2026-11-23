# Spec: This Week Tab

## Requirements
1. **WHEN** This Week tab opens, **THE SYSTEM SHALL** display the current gestational week (weeks 4 to 42) with approved developmental text from the baby.
2. **WHEN** the mother scrubs or navigates between weeks, **THE SYSTEM SHALL** show the corresponding approved card for that week.
3. **WHEN** displaying size, **THE SYSTEM SHALL** only show object comparisons (no clinical measurements) after medical approval.

## Tasks
- [x] 1. Implement gestational week calculation logic
- [ ] 2. Create week card model and JSON dataset for weeks 4 to 42
- [ ] 3. Build horizontal pager / week selector widget
