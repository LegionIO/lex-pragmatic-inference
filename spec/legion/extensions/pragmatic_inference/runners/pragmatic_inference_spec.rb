# frozen_string_literal: true

require 'legion/extensions/pragmatic_inference/client'

RSpec.describe Legion::Extensions::PragmaticInference::Runners::PragmaticInference do
  let(:client) { Legion::Extensions::PragmaticInference::Client.new }

  let(:compliant_scores) { { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 } }
  let(:violating_scores) { { quality: 0.05, quantity: 0.9, relevance: 0.9, manner: 0.9 } }

  def analyze(speaker: 'alice', speech_act: :assert, scores: compliant_scores)
    client.analyze_utterance(
      content:      'test content',
      speaker:      speaker,
      speech_act:   speech_act,
      maxim_scores: scores
    )
  end

  describe '#analyze_utterance' do
    it 'returns success with a valid speech act' do
      result = analyze
      expect(result[:success]).to be true
      expect(result[:utterance_id]).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'returns overall_compliance' do
      result = analyze(scores: compliant_scores)
      expect(result[:overall_compliance]).to be_a(Float)
    end

    it 'rejects invalid speech act' do
      result = client.analyze_utterance(
        content: 'test', speaker: 'alice', speech_act: :perform, maxim_scores: {}
      )
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_speech_act)
    end

    it 'includes violated_maxims in result' do
      result = analyze(scores: violating_scores)
      expect(result[:violated_maxims]).to include(:quality)
    end

    it 'reports no violations for compliant utterance' do
      result = analyze(scores: compliant_scores)
      expect(result[:violated_maxims]).to be_empty
    end
  end

  describe '#detect_maxim_violations' do
    it 'detects violations for low-scoring utterance' do
      analyzed = analyze(scores: violating_scores)
      result = client.detect_maxim_violations(utterance_id: analyzed[:utterance_id])
      expect(result[:success]).to be true
      expect(result[:violation_count]).to be >= 1
      expect(result[:violations].map { |v| v[:maxim] }).to include(:quality)
    end

    it 'returns zero violations for compliant utterance' do
      analyzed = analyze(scores: compliant_scores)
      result = client.detect_maxim_violations(utterance_id: analyzed[:utterance_id])
      expect(result[:violation_count]).to eq(0)
    end

    it 'rejects short utterance_id' do
      result = client.detect_maxim_violations(utterance_id: 'ab')
      expect(result[:success]).to be false
    end
  end

  describe '#generate_pragmatic_implicature' do
    it 'adds implicature to existing utterance' do
      analyzed = analyze
      result = client.generate_pragmatic_implicature(
        utterance_id:     analyzed[:utterance_id],
        inferred_meaning: 'speaker implies indirect request'
      )
      expect(result[:success]).to be true
      expect(result[:inferred_meaning]).to eq('speaker implies indirect request')
    end

    it 'fails for unknown utterance' do
      result = client.generate_pragmatic_implicature(
        utterance_id:     SecureRandom.uuid,
        inferred_meaning: 'something'
      )
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:utterance_not_found)
    end

    it 'rejects short inferred_meaning' do
      analyzed = analyze
      result = client.generate_pragmatic_implicature(
        utterance_id:     analyzed[:utterance_id],
        inferred_meaning: 'ab'
      )
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_inferred_meaning)
    end

    it 'rejects short utterance_id' do
      result = client.generate_pragmatic_implicature(utterance_id: 'x', inferred_meaning: 'valid meaning here')
      expect(result[:success]).to be false
    end
  end

  describe '#speaker_pragmatic_profile' do
    it 'returns profile for existing speaker' do
      analyze(speaker: 'bob')
      analyze(speaker: 'bob')
      result = client.speaker_pragmatic_profile(speaker: 'bob')
      expect(result[:success]).to be true
      expect(result[:utterance_count]).to eq(2)
      expect(result[:compliance_by_maxim]).to be_a(Hash)
    end

    it 'returns empty count for unknown speaker' do
      result = client.speaker_pragmatic_profile(speaker: 'unknown_person')
      expect(result[:success]).to be true
      expect(result[:utterance_count]).to eq(0)
    end

    it 'rejects short speaker name' do
      result = client.speaker_pragmatic_profile(speaker: 'ab')
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_speaker)
    end
  end

  describe '#utterances_by_speech_act' do
    it 'returns utterances matching speech act' do
      analyze(speech_act: :question)
      analyze(speech_act: :question)
      analyze(speech_act: :warn)
      result = client.utterances_by_speech_act(speech_act: :question)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end

    it 'rejects invalid speech act' do
      result = client.utterances_by_speech_act(speech_act: :perform)
      expect(result[:success]).to be false
      expect(result[:error]).to eq(:invalid_speech_act)
    end
  end

  describe '#utterances_by_speaker' do
    it 'returns utterances for given speaker' do
      analyze(speaker: 'charlie')
      analyze(speaker: 'charlie')
      analyze(speaker: 'dave')
      result = client.utterances_by_speaker(speaker: 'charlie')
      expect(result[:success]).to be true
      expect(result[:count]).to eq(2)
    end

    it 'rejects short speaker name' do
      result = client.utterances_by_speaker(speaker: 'xy')
      expect(result[:success]).to be false
    end
  end

  describe '#most_violated_maxim' do
    it 'returns nil maxim when no utterances' do
      result = client.most_violated_maxim
      expect(result[:success]).to be true
      expect(result[:maxim]).to be_nil
    end

    it 'identifies the most violated maxim' do
      3.times do
        analyzed = analyze(scores: { quality: 0.1, quantity: 0.9, relevance: 0.9, manner: 0.9 })
        client.detect_maxim_violations(utterance_id: analyzed[:utterance_id])
      end
      analyzed = analyze(scores: { quality: 0.9, quantity: 0.1, relevance: 0.9, manner: 0.9 })
      client.detect_maxim_violations(utterance_id: analyzed[:utterance_id])

      result = client.most_violated_maxim
      expect(result[:maxim]).to eq(:quality)
    end

    it 'includes a description for the violated maxim' do
      analyzed = analyze(scores: violating_scores)
      client.detect_maxim_violations(utterance_id: analyzed[:utterance_id])
      result = client.most_violated_maxim
      expect(result[:description]).to be_a(String) if result[:maxim]
    end
  end

  describe '#overall_cooperative_compliance' do
    it 'returns 0.0 when no utterances' do
      result = client.overall_cooperative_compliance
      expect(result[:success]).to be true
      expect(result[:cooperation]).to eq(0.0)
    end

    it 'computes mean compliance' do
      analyze(scores: { quality: 1.0, quantity: 1.0, relevance: 1.0, manner: 1.0 })
      analyze(scores: { quality: 0.0, quantity: 0.0, relevance: 0.0, manner: 0.0 })
      result = client.overall_cooperative_compliance
      expect(result[:cooperation]).to be_within(0.01).of(0.5)
    end
  end

  describe '#update_pragmatic_inference' do
    it 'returns success with decay info' do
      result = client.update_pragmatic_inference
      expect(result[:success]).to be true
      expect(result[:decay_rate]).to eq(Legion::Extensions::PragmaticInference::Helpers::Constants::DECAY_RATE)
    end

    it 'decays utterance confidence' do
      analyze
      before_cooperation = client.overall_cooperative_compliance[:cooperation]
      client.update_pragmatic_inference
      after_cooperation = client.overall_cooperative_compliance[:cooperation]
      expect(after_cooperation).to be <= before_cooperation
    end
  end

  describe '#pragmatic_inference_stats' do
    it 'returns stats hash' do
      analyze
      result = client.pragmatic_inference_stats
      expect(result[:success]).to be true
      expect(result[:utterance_count]).to eq(1)
      expect(result).to include(:overall_cooperation, :most_violated_maxim, :history_size, :speakers)
    end
  end
end
