# lex-pragmatic-inference

**Level 3 Leaf Documentation**
- **Parent**: `/Users/miverso2/rubymine/legion/extensions-agentic/CLAUDE.md`
- **Gem**: `lex-pragmatic-inference`
- **Version**: 0.1.0
- **Namespace**: `Legion::Extensions::PragmaticInference`

## Purpose

Gricean cooperative maxims and conversational implicature engine. Implements H.P. Grice's Cooperative Principle: Quality, Quantity, Relevance, and Manner. Analyzes utterances for maxim compliance, detects violations (flouting, direct violation, opting out), generates pragmatic implicatures, tracks per-speaker compliance profiles, and identifies which maxim is most frequently violated across all utterances.

## Gem Info

- **Homepage**: https://github.com/LegionIO/lex-pragmatic-inference
- **License**: MIT
- **Ruby**: >= 3.4

## File Structure

```
lib/legion/extensions/pragmatic_inference/
  version.rb
  client.rb
  helpers/
    constants.rb         # MAXIMS, SPEECH_ACTS, VIOLATION_TYPES, rates, limits
    utterance.rb         # Utterance class — stores analysis, violations, implicatures
    pragmatic_engine.rb  # PragmaticEngine — manages utterances, profiles, decay
  runners/
    pragmatic_inference.rb  # Runner module
spec/
  helpers/constants_spec.rb
  helpers/utterance_spec.rb
  helpers/pragmatic_engine_spec.rb
  runners/pragmatic_inference_spec.rb
  client_spec.rb
```

## Key Constants

From `Helpers::Constants`:
- `MAX_UTTERANCES = 500`, `MAX_IMPLICATURES = 200`, `MAX_HISTORY = 300`
- `REINFORCEMENT_RATE = 0.1`, `DECAY_RATE = 0.02`
- `MAXIMS = %i[quality quantity relevance manner]`
- `VIOLATION_TYPES = %i[none flouting violating opting_out]`
- `SPEECH_ACTS = %i[assert question request promise warn inform suggest]`
- `MAXIM_DESCRIPTIONS`: human-readable description per maxim
- Violation classification by maxim score: `< 0.1` -> `:violating`, `< 0.3` -> `:flouting`, `< 0.5` -> `:opting_out`, `>= 0.5` -> `:none`

## Runners

| Method | Key Parameters | Returns |
|---|---|---|
| `analyze_utterance` | `content:`, `speaker:`, `speech_act:`, `literal_meaning:`, `domain:`, `maxim_scores: {}` | `{ success:, utterance_id:, overall_compliance:, violated_maxims: }` |
| `detect_maxim_violations` | `utterance_id:` | `{ success:, utterance_id:, violations:, violation_count: }` |
| `generate_pragmatic_implicature` | `utterance_id:`, `inferred_meaning:` | `{ success:, utterance_id:, inferred_meaning: }` |
| `speaker_pragmatic_profile` | `speaker:` | `{ success:, speaker:, utterance_count:, compliance_by_maxim:, overall_compliance: }` |
| `utterances_by_speech_act` | `speech_act:` | `{ success:, speech_act:, utterances:, count: }` |
| `utterances_by_speaker` | `speaker:` | `{ success:, speaker:, utterances:, count: }` |
| `most_violated_maxim` | — | `{ success:, maxim:, description: }` |
| `overall_cooperative_compliance` | — | `{ success:, cooperation:, utterance_count: }` |
| `update_pragmatic_inference` | — | applies decay to all utterance confidences |
| `pragmatic_inference_stats` | — | utterance count, cooperation score, most violated maxim, speakers |

## Helpers

### `Helpers::Utterance`
Stores single utterance analysis: `id`, `content`, `speaker`, `speech_act`, `literal_meaning`, `domain`, `maxim_scores` (hash), `violations` (array), `implicatures` (array), `confidence`. `overall_compliance` = mean of maxim scores. `violated_maxims` = maxims with score < 0.5. `add_implicature(meaning:)`. `update_confidence(delta)` clamps to [0, 1].

### `Helpers::PragmaticEngine`
Manages `@utterances` hash + `@history` array. `analyze_utterance` creates and stores utterance. `detect_violations` applies threshold-based classification per maxim. `generate_implicature` adds to utterance's implicature list. `speaker_profile` computes per-maxim compliance mean across all speaker utterances. `most_violated_maxim` tallies violations across all utterances. `reinforce(utterance_id:)` adds `REINFORCEMENT_RATE`. `decay_all` subtracts `DECAY_RATE` from all.

## Integration Points

- `analyze_utterance` processes utterances from `lex-mesh` or `lex-swarm` agent communication
- Maxim violations can feed `lex-trust` (quality violations -> lower integrity score)
- `overall_cooperative_compliance` can feed `lex-conflict` as a cooperation health metric
- `speaker_pragmatic_profile` can inform `lex-identity` behavioral fingerprinting
- `update_pragmatic_inference` called on each tick via `lex-cortex` phase handler

## Development Notes

- `analyze_utterance` validates `speech_act` against `SPEECH_ACTS` before storing
- Violation detection score thresholds: `< 0.1` = `:violating`, `< 0.3` = `:flouting`, `< 0.5` = `:opting_out`
- `overall_compliance` on Utterance = mean of all provided maxim scores
- `speaker_profile` returns empty `compliance_by_maxim` if speaker has no utterances
- `most_violated_maxim` returns nil if no violations have been detected
- Oldest utterances evicted (FIFO) when exceeding `MAX_UTTERANCES`
- All state is in-memory; reset on process restart
