# Mock data for offline UI and tests

This folder contains JSON snapshots to drive the UI without a backend. You can load these into Providers to simulate lobby, seating, bidding, replacements, tricks, and scoring.

Files:
- lobby.json — a realtime-like list of tables and presence
- table_10pt_full.json — a full table with 4 seats filled
- hand_dealt.json — hands for N/E/S/W after initial deal
- bidding_progress.json — bidding round states
- replacements.json — replacement requests and results per seat (10‑Point)
- trick_sequence.json — ordered plays for 6 tricks
- scoring_breakdown.json — per-hand scoring for both variants
