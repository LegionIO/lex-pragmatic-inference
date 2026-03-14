# lex-pragmatic-inference

Gricean cooperative maxims and conversational implicature engine for LegionIO brain-modeled agentic AI.

Implements H.P. Grice's Cooperative Principle: Quality, Quantity, Relevance, and Manner. Analyzes utterances for maxim compliance, detects violations (including flouting, direct violation, and opting out), and generates pragmatic implicatures — the gap between what was said and what was meant.

## Installation

```ruby
gem 'lex-pragmatic-inference'
```

## Usage

```ruby
client = Legion::Extensions::PragmaticInference::Client.new

result = client.analyze_utterance(
  content:      'Can you pass the salt?',
  speaker:      'alice',
  speech_act:   :request,
  maxim_scores: { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 }
)

client.generate_pragmatic_implicature(
  utterance_id:     result[:utterance_id],
  inferred_meaning: 'indirect request for action, not ability check'
)

client.speaker_pragmatic_profile(speaker: 'alice')
client.most_violated_maxim
client.overall_cooperative_compliance
```

## License

MIT
