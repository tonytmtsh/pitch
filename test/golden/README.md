# Golden Tests Documentation

This document explains how to work with golden tests in the Pitch Flutter app.

## What are Golden Tests?

Golden tests (also called screenshot tests) capture visual snapshots of widgets and compare them against previously saved "golden" images. They help ensure visual consistency and catch unintended UI changes.

## Golden Tests in this Project

We have golden tests for:

1. **PlayingCardView** (`test/golden/playing_card_view_test.dart`)
   - Tests various card states: different suits, highlighted, disabled, face up/down
   - Covers representative hands with multiple cards

2. **Current Trick Panel** (`test/golden/current_trick_panel_test.dart`)
   - Tests trick display with different highlight states
   - Shows partial and complete tricks
   - Tests turn highlighting for different positions

## Running Golden Tests

### Prerequisites

Make sure Flutter is installed and web support is enabled:
```bash
flutter config --enable-web
flutter pub get
```

### Running Tests

To run all golden tests:
```bash
flutter test test/golden/
```

To run a specific golden test file:
```bash
flutter test test/golden/playing_card_view_test.dart
```

## Updating Golden Files

### When to Update

Update golden files when:
- You intentionally change the UI appearance
- You add new test cases
- The tests fail due to expected visual changes

### How to Update

To update/generate golden files, use the `--update-goldens` flag:

```bash
# Update all golden files
flutter test --update-goldens

# Update specific test file's goldens
flutter test test/golden/playing_card_view_test.dart --update-goldens
```

### Golden File Location

Golden files are stored in:
```
test/golden/goldens/
├── current_trick_panel_complete_trick.png
├── current_trick_panel_empty.png
├── current_trick_panel_north_turn.png
├── current_trick_panel_partial_trick.png
├── playing_card_view_individual_states.png
└── playing_card_view_representative_hand.png
```

## CI/CD Integration

Golden tests run automatically in CI. When they fail:

1. **Expected failures**: If you changed UI intentionally, update the goldens locally and commit the new golden files
2. **Unexpected failures**: Review the UI changes to ensure they're correct

### Committing Golden Files

Golden image files should be committed to the repository:
```bash
git add test/golden/goldens/
git commit -m "Update golden test images"
```

## Test Structure

### PlayingCardView Tests

Tests cover:
- **Different suits**: Spades (♠), Hearts (♥), Diamonds (♦), Clubs (♣)
- **Different ranks**: A, K, Q, J, 10, 9, 8, 7, 6, 5, 4, 3, 2
- **States**: Normal, highlighted, disabled, face down
- **Edge cases**: Empty card code

### Current Trick Panel Tests

Tests cover:
- **Partial tricks**: Some players have played, others pending
- **Complete tricks**: All 4 players have played
- **Turn highlighting**: Current player's position highlighted in teal
- **Empty state**: No current trick

## Troubleshooting

### Test Failures

If golden tests fail:

1. **View the diff**: Flutter test output shows where images differ
2. **Check intentional changes**: Did you modify the UI intentionally?
3. **Update if needed**: Use `--update-goldens` if changes are expected
4. **Review carefully**: Ensure changes match your expectations

### Platform Differences

Golden tests can be sensitive to:
- Font rendering differences between platforms
- Pixel density variations
- Color profile differences

For consistency, consider running golden tests in a controlled environment (like CI).

### Common Issues

1. **Fonts not loaded**: Ensure custom fonts are properly configured
2. **Async rendering**: Use `await tester.pumpAndSettle()` for async content
3. **Widget size**: Explicitly set container sizes for predictable layouts

## Adding New Golden Tests

When adding new golden tests:

1. Create the test file in `test/golden/`
2. Follow the existing pattern for test structure
3. Use descriptive golden file names
4. Run with `--update-goldens` to generate initial images
5. Verify the generated images look correct
6. Commit both test code and golden images

## Example Test Structure

```dart
testWidgets('descriptive test name', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: YourWidget(),
      ),
    ),
  );

  await expectLater(
    find.byType(Scaffold),
    matchesGoldenFile('descriptive_filename.png'),
  );
});
```

This ensures visual stability and helps catch unintended UI regressions.