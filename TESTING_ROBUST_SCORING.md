# Testing Guide: Robust Feedback System

## Quick Test Scenarios

### Test 1: Minimal Performance (Expected ~25-35%)
**Steps:**
1. Start a debate on any topic
2. Speak only ONE short argument (under 15 words)
3. End the debate
4. Check feedback scores

**Example**: "I think technology is good because it helps people."

**Expected Results:**
- All scores should be 0.25-0.45 range
- Feedback should mention:
  - "Limited engagement" or "minimal participation"
  - "Develop more detailed arguments"
  - "Engage in longer debates"
  - Specific word count suggestions

---

### Test 2: Below Average Performance (Expected ~40-50%)
**Steps:**
1. Start a debate
2. Make 2 short arguments (15-20 words each)
3. Don't directly address AI's counter-arguments
4. End the debate

**Example Messages:**
- "Technology improves education by providing access to information online."
- "Students can learn at their own pace with digital tools."

**Expected Results:**
- Scores in 0.35-0.55 range
- Rebuttal Quality should be low (~0.30)
- Feedback should mention:
  - "Need to address opposing viewpoints"
  - "Arguments lack depth"

---

### Test 3: Average Performance (Expected ~55-65%)
**Steps:**
1. Start a debate
2. Make 3 arguments (20-30 words each)
3. Use at least one logical connector ("because", "therefore")
4. Acknowledge one opposing point
5. End the debate

**Example Messages:**
- "Technology significantly enhances education because it provides instant access to vast information resources and enables personalized learning experiences."
- "While you mention distractions, studies show that when properly integrated, technology actually increases student engagement and retention rates."
- "Therefore, the benefits of educational technology outweigh the challenges when implemented with proper guidelines and teacher support."

**Expected Results:**
- Scores in 0.50-0.70 range
- Logic should be higher (~0.60-0.65)
- At least one rebuttal detected
- Feedback should be balanced (strengths + improvements)

---

### Test 4: Good Performance (Expected ~70-80%)
**Steps:**
1. Start a debate
2. Make 4-5 well-developed arguments (30+ words each)
3. Use multiple logical connectors
4. Directly address AI's points multiple times
5. Use specific examples
6. Maintain consistent position

**Example Messages:**
- "Climate action is economically imperative. Research from the Global Commission on Adaptation shows that investing $1.8 trillion in climate adaptation from 2020-2030 could generate $7.1 trillion in benefits. This demonstrates clear economic incentives beyond environmental concerns."
- "While you raise concerns about economic costs, you're overlooking opportunity costs. The fossil fuel industry employs 1.7 million globally, but renewable energy already employs 11 million. Therefore, transition actually creates net jobs."
- "I disagree that technology alone suffices. Norway invested heavily in electric vehicles but needed policy - tax incentives, free tolls, and purchase exemptions. Technology without policy framework fails to scale, as seen in early solar panel adoption."
- "Your point about developing nations is valid, however international climate finance mechanisms like the Green Climate Fund specifically address this. Developed nations committed $100 billion annually to support developing countries' transition."

**Expected Results:**
- Scores in 0.65-0.85 range
- High rebuttal quality (~0.70+)
- Good logic score (~0.75+)
- Feedback should be mostly positive with specific praise
- Improvements should be advanced suggestions

---

## Metrics to Verify

After each test, check that these calculations are reflected:

### Message Count
- Check overall feedback mentions the number of exchanges
- Low count (1-2) = significant score cap mentioned

### Word Count
- Average words per message should be displayed
- Short messages (<15 words) = clarity/articulation penalties mentioned

### Logical Connectors
- Count "because", "therefore", "thus", "hence", etc.
- Zero connectors = logic score feedback

### Rebuttals
- Count "but", "however", "disagree", "wrong", "actually"
- Zero rebuttals = rebuttal quality called out

### Vocabulary
- Unique words / total words
- Low ratio = articulation feedback

---

## Score Calibration Check

Run this calculation manually to verify:

```dart
// For minimal performance (1 message, <15 words):
Base score = 0.25

Clarity: 0.25 + (words > 20 ? 0.1 : 0.0) = 0.25
Logic: 0.25 + (connectors > 0 ? 0.1 : -0.1) = 0.15-0.35
Rebuttal: 0.25 + (rebuttals > 0 ? 0.1 : -0.15) = 0.10
Persuasiveness: 0.25 + (unique words > 30 ? 0.1 : 0.0) = 0.25
Coherence: 0.25 + (messages > 2 ? 0.05 : -0.1) = 0.15
Articulation: 0.25 + (vocab richness > 0.5 ? 0.15 : 0.0) = 0.25-0.40
Engagement: 0.25 + (avg words > 25 ? 0.1 : -0.05) = 0.20
Tone: 0.25 + 0.15 = 0.40

Average: ~0.24 (24%)
```

---

## UI Verification

Check that the feedback screen displays:

1. **Overall Score**: Percentage matching skill average
2. **Skill Breakdown**: Each of 8 skills with bars
3. **Strengths**: 3+ specific items (not generic)
4. **Improvements**: 3+ actionable items with examples
5. **Overall Feedback**: References specific performance metrics

---

## Edge Cases to Test

### Edge Case 1: Empty Debate
- Start and immediately end
- Should handle gracefully (error or minimal scores)

### Edge Case 2: Very Long Single Message
- One message with 200+ words
- Should still cap due to message count
- But may score higher on articulation/clarity

### Edge Case 3: Many Very Short Messages
- 5 messages of 5 words each
- Should penalize for brevity despite message count

### Edge Case 4: Perfect Debate
- 5+ messages, 50+ words each, rich vocabulary, multiple rebuttals
- Should achieve 80-90% (not 100% unless exceptional)

---

## Success Criteria

✅ **System is working correctly if:**
- 1 short argument → 25-35% overall
- 2-3 basic arguments → 40-55% overall  
- 3-4 good arguments with rebuttals → 60-75% overall
- 5+ excellent arguments with evidence → 75-90% overall
- Feedback is specific and references actual performance
- Improvements are actionable (not "practice more")

❌ **System needs adjustment if:**
- Any scenario consistently scores >20% above expected range
- Minimal performance gets >50%
- Generic feedback appears for fallback cases
- Scores don't vary based on clear quality differences

---

## Debug Mode

To verify calculations, check console logs:

```
AIService: User messages: X
AIService: Total words: Y
AIService: Average words per message: Z
AIService: Logical connectors used: N
AIService: Rebuttals attempted: M
```

These should match your expectations for the debate input.
