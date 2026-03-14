# frozen_string_literal: true

RSpec.describe Legion::Extensions::PragmaticInference::Helpers::PragmaticEngine do
  subject(:engine) { described_class.new }

  let(:quality_violating_scores) { { quality: 0.1, quantity: 0.9, relevance: 0.8, manner: 0.9 } }
  let(:compliant_scores)         { { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 } }

  def add_utterance(speaker: 'alice', speech_act: :assert, scores: compliant_scores)
    engine.analyze_utterance(
      content:      'test utterance',
      speaker:      speaker,
      speech_act:   speech_act,
      maxim_scores: scores
    )
  end

  describe '#analyze_utterance' do
    it 'stores and returns an Utterance' do
      utterance = add_utterance
      expect(utterance).to be_a(Legion::Extensions::PragmaticInference::Helpers::Utterance)
    end

    it 'stores the utterance by id' do
      utterance = add_utterance
      expect(engine.utterances[utterance.id]).to eq(utterance)
    end

    it 'records history entry' do
      add_utterance
      expect(engine.history).not_to be_empty
    end

    it 'trims utterances when at capacity' do
      stub_const('Legion::Extensions::PragmaticInference::Helpers::Constants::MAX_UTTERANCES', 3)
      3.times { add_utterance }
      initial_ids = engine.utterances.keys.dup
      add_utterance
      expect(engine.utterances.keys).not_to include(initial_ids.first)
    end
  end

  describe '#detect_violations' do
    it 'returns violations for low-scoring maxims' do
      utterance = add_utterance(scores: quality_violating_scores)
      violations = engine.detect_violations(utterance_id: utterance.id)
      expect(violations.map { |v| v[:maxim] }).to include(:quality)
    end

    it 'returns empty array for compliant utterance' do
      utterance = add_utterance(scores: compliant_scores)
      violations = engine.detect_violations(utterance_id: utterance.id)
      expect(violations).to be_empty
    end

    it 'returns empty array for unknown utterance id' do
      expect(engine.detect_violations(utterance_id: 'nonexistent')).to eq([])
    end

    it 'classifies severe violation as :violating' do
      utterance = add_utterance(scores: { quality: 0.05, quantity: 0.9, relevance: 0.9, manner: 0.9 })
      violations = engine.detect_violations(utterance_id: utterance.id)
      quality_violation = violations.find { |v| v[:maxim] == :quality }
      expect(quality_violation[:violation_type]).to eq(:violating)
    end

    it 'classifies moderate violation as :flouting' do
      utterance = add_utterance(scores: { quality: 0.2, quantity: 0.9, relevance: 0.9, manner: 0.9 })
      violations = engine.detect_violations(utterance_id: utterance.id)
      quality_violation = violations.find { |v| v[:maxim] == :quality }
      expect(quality_violation[:violation_type]).to eq(:flouting)
    end

    it 'classifies mild violation as :opting_out' do
      utterance = add_utterance(scores: { quality: 0.4, quantity: 0.9, relevance: 0.9, manner: 0.9 })
      violations = engine.detect_violations(utterance_id: utterance.id)
      quality_violation = violations.find { |v| v[:maxim] == :quality }
      expect(quality_violation[:violation_type]).to eq(:opting_out)
    end
  end

  describe '#generate_implicature' do
    it 'adds an implicature to the utterance' do
      utterance = add_utterance
      result = engine.generate_implicature(utterance_id: utterance.id, inferred_meaning: 'indirect request')
      expect(result).to eq('indirect request')
      expect(utterance.implicatures.size).to eq(1)
    end

    it 'returns nil for unknown utterance' do
      result = engine.generate_implicature(utterance_id: 'unknown', inferred_meaning: 'something')
      expect(result).to be_nil
    end
  end

  describe '#speaker_profile' do
    it 'returns profile for a speaker with utterances' do
      add_utterance(speaker: 'bob', scores: compliant_scores)
      add_utterance(speaker: 'bob', scores: compliant_scores)
      profile = engine.speaker_profile(speaker: 'bob')
      expect(profile[:speaker]).to eq('bob')
      expect(profile[:utterance_count]).to eq(2)
      expect(profile[:compliance_by_maxim].keys).to match_array(%i[quality quantity relevance manner])
    end

    it 'returns empty profile for unknown speaker' do
      profile = engine.speaker_profile(speaker: 'unknown')
      expect(profile[:utterance_count]).to eq(0)
    end
  end

  describe '#by_speech_act' do
    it 'filters utterances by speech act' do
      add_utterance(speech_act: :question)
      add_utterance(speech_act: :assert)
      add_utterance(speech_act: :question)
      result = engine.by_speech_act(speech_act: :question)
      expect(result.size).to eq(2)
    end
  end

  describe '#by_speaker' do
    it 'filters utterances by speaker' do
      add_utterance(speaker: 'alice')
      add_utterance(speaker: 'bob')
      result = engine.by_speaker(speaker: 'alice')
      expect(result.size).to eq(1)
    end
  end

  describe '#most_violated_maxim' do
    it 'returns nil when no utterances' do
      expect(engine.most_violated_maxim).to be_nil
    end

    it 'returns the most commonly violated maxim' do
      3.times { add_utterance(scores: { quality: 0.1, quantity: 0.9, relevance: 0.9, manner: 0.9 }) }
      add_utterance(scores: { quality: 0.9, quantity: 0.1, relevance: 0.9, manner: 0.9 })
      engine.utterances.each_value { |u| engine.detect_violations(utterance_id: u.id) }
      expect(engine.most_violated_maxim).to eq(:quality)
    end
  end

  describe '#overall_cooperation' do
    it 'returns 0.0 when no utterances' do
      expect(engine.overall_cooperation).to eq(0.0)
    end

    it 'returns mean compliance across utterances' do
      add_utterance(scores: { quality: 1.0, quantity: 1.0, relevance: 1.0, manner: 1.0 })
      add_utterance(scores: { quality: 0.0, quantity: 0.0, relevance: 0.0, manner: 0.0 })
      expect(engine.overall_cooperation).to be_within(0.01).of(0.5)
    end
  end

  describe '#reinforce' do
    it 'increases utterance confidence' do
      utterance = add_utterance
      original_confidence = utterance.confidence
      engine.reinforce(utterance_id: utterance.id)
      expect(utterance.confidence).to be > original_confidence
    end
  end

  describe '#decay_all' do
    it 'decreases confidence of all utterances' do
      u1 = add_utterance
      u2 = add_utterance
      c1 = u1.confidence
      c2 = u2.confidence
      engine.decay_all
      expect(u1.confidence).to be < c1
      expect(u2.confidence).to be < c2
    end
  end

  describe '#to_h' do
    it 'returns stats hash with expected keys' do
      add_utterance
      h = engine.to_h
      expect(h).to include(:utterance_count, :overall_cooperation, :most_violated_maxim,
                           :history_size, :speakers)
    end
  end
end
