# lex-pragmatic-inference

Gricean cooperative maxims and conversational implicature engine for the LegionIO cognitive architecture.

## What It Does

Implements H.P. Grice's Cooperative Principle: Quality, Quantity, Relevance, and Manner. Analyzes utterances for maxim compliance, detects violations (including flouting, direct violation, and opting out), and generates pragmatic implicatures — the gap between what was said and what was meant. Tracks per-speaker compliance profiles and identifies which maxim is most frequently violated.

## Usage

```ruby
client = Legion::Extensions::PragmaticInference::Client.new

# Analyze an utterance for maxim compliance
result = client.analyze_utterance(
  content:      'Can you pass the salt?',
  speaker:      'agent_alice',
  speech_act:   :request,
  maxim_scores: { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 }
)
# => { success: true, utterance_id: '...', overall_compliance: 0.887, violated_maxims: [] }

# Detect violations (checks scores < 0.5 for each maxim)
client.detect_maxim_violations(utterance_id: result[:utterance_id])

# Add a pragmatic implicature
client.generate_pragmatic_implicature(
  utterance_id:     result[:utterance_id],
  inferred_meaning: 'indirect request for action, not ability check'
)

# Speaker profile
client.speaker_pragmatic_profile(speaker: 'agent_alice')
# => { speaker: 'agent_alice', utterance_count: 1,
#      compliance_by_maxim: { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 },
#      overall_compliance: 0.887 }

# System-wide metrics
client.most_violated_maxim
client.overall_cooperative_compliance

# Periodic decay
client.update_pragmatic_inference
```

## Gricean Maxims

| Maxim | Description |
|-------|-------------|
| `:quality` | Be truthful, have evidence |
| `:quantity` | Be informative, not more than needed |
| `:relevance` | Be relevant to the conversation |
| `:manner` | Be clear, brief, orderly, unambiguous |

## Speech Acts

`:assert`, `:question`, `:request`, `:promise`, `:warn`, `:inform`, `:suggest`

## Development

```bash
bundle install
bundle exec rspec
bundle exec rubocop
```

## License

MIT
