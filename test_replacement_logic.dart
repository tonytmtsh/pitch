#!/usr/bin/env dart

// Simple verification script to test the replacement logic without Flutter UI
import 'dart:io';
import '../lib/services/mock_pitch_service.dart';
import '../lib/state/table_store.dart';

void main() async {
  print('Testing Replacement Selection Logic...\n');
  
  final mockService = MockPitchService();
  final store = TableStore(mockService, 't1');
  
  // Test 1: Initial state
  print('1. Initial state:');
  await store.refresh();
  print('   My cards: ${store.myCards}');
  print('   Selected cards: ${store.selectedCardsForDiscard}');
  print('   Can request replacements: ${store.canRequestReplacements}');
  print('   Has replacement in progress: ${store.hasReplacementInProgress}\n');
  
  // Test 2: Card selection
  print('2. Testing card selection:');
  if (store.myCards.isNotEmpty) {
    final testCard = store.myCards.first;
    print('   Selecting card: $testCard');
    store.toggleCardSelection(testCard);
    print('   Selected cards: ${store.selectedCardsForDiscard}');
    print('   Contains $testCard: ${store.selectedCardsForDiscard.contains(testCard)}\n');
    
    // Test 3: Deselection
    print('3. Testing card deselection:');
    store.toggleCardSelection(testCard);
    print('   Selected cards after deselection: ${store.selectedCardsForDiscard}\n');
    
    // Test 4: Request replacements
    print('4. Testing replacement request:');
    store.toggleCardSelection(testCard);
    if (store.myCards.length > 1) {
      store.toggleCardSelection(store.myCards[1]);
    }
    print('   Selected for replacement: ${store.selectedCardsForDiscard}');
    store.requestReplacementsForSelected();
    print('   After request - selected: ${store.selectedCardsForDiscard}');
    print('   Has replacement in progress: ${store.hasReplacementInProgress}');
    
    // Wait a bit for async operation
    await Future.delayed(Duration(milliseconds: 100));
    print('   Replacements pending: ${store.replacementsAll.length}');
    if (store.replacementsAll.isNotEmpty) {
      final replacement = store.replacementsAll.first;
      print('   Discarded: ${replacement.discarded}');
      print('   Drawn: ${replacement.drawn}');
    }
  }
  
  print('\n✅ Replacement selection logic test completed!');
}