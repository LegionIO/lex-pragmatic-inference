# frozen_string_literal: true

RSpec.describe Legion::Extensions::PragmaticInference::Helpers::Utterance do
  let(:utterance) do
    described_class.new(
      content:      'Can you pass the salt?',
      speaker:      'alice',
      speech_act:   :request,
      maxim_scores: { quality: 0.9, quantity: 0.8, relevance: 0.9, manner: 0.95 }
    )
  end

  describe '#initialize' do
    it 'assigns a UUID id' do
      expect(utterance.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'sets content and speaker' do
      expect(utterance.content).to eq('Can you pass the salt?')
      expect(utterance.speaker).to eq('alice')
    end

    it 'sets speech act' do
      expect(utterance.speech_act).to eq(:request)
    end

    it 'initializes violations and implicatures as empty arrays' do
      expect(utterance.violations).to be_empty
      expect(utterance.implicatures).to be_empty
    end

    it 'clamps confidence to valid range' do
      u = described_class.new(content: 'x', speaker: 'a', speech_act: :assert, confidence: 5.0)
      expect(u.confidence).to eq(1.0)
    end

    it 'defaults missing maxim scores to DEFAULT_CONFIDENCE' do
      u = described_class.new(content: 'x', speaker: 'a', speech_act: :assert, maxim_scores: {})
      expect(u.maxim_scores[:quality]).to eq(0.5)
    end
  end

  describe '#overall_compliance' do
    it 'returns mean of maxim scores' do
      expected = (0.9 + 0.8 + 0.9 + 0.95) / 4.0
      expect(utterance.overall_compliance).to be_within(0.001).of(expected)
    end
  end

  describe '#violated_maxims' do
    it 'returns maxims with score below 0.5' do
      u = described_class.new(
        content:      'test',
        speaker:      'bob',
        speech_act:   :inform,
        maxim_scores: { quality: 0.1, quantity: 0.9, relevance: 0.8, manner: 0.3 }
      )
      expect(u.violated_maxims).to include(:quality, :manner)
      expect(u.violated_maxims).not_to include(:quantity, :relevance)
    end

    it 'returns empty array when all maxims compliant' do
      expect(utterance.violated_maxims).to be_empty
    end
  end

  describe '#add_implicature' do
    it 'adds an inferred meaning' do
      utterance.add_implicature(meaning: 'requesting action, not asking ability')
      expect(utterance.implicatures.size).to eq(1)
      expect(utterance.implicatures.first[:meaning]).to eq('requesting action, not asking ability')
    end

    it 'does not exceed MAX_IMPLICATURES' do
      Legion::Extensions::PragmaticInference::Helpers::Constants::MAX_IMPLICATURES.times do |i|
        utterance.add_implicature(meaning: "meaning #{i}")
      end
      utterance.add_implicature(meaning: 'one more')
      expect(utterance.implicatures.size).to eq(
        Legion::Extensions::PragmaticInference::Helpers::Constants::MAX_IMPLICATURES
      )
    end
  end

  describe '#update_confidence' do
    it 'increases confidence by delta' do
      original = utterance.confidence
      utterance.update_confidence(0.1)
      expect(utterance.confidence).to be_within(0.001).of(original + 0.1)
    end

    it 'clamps at ceiling' do
      utterance.update_confidence(10.0)
      expect(utterance.confidence).to eq(1.0)
    end

    it 'clamps at floor' do
      utterance.update_confidence(-10.0)
      expect(utterance.confidence).to eq(0.0)
    end
  end

  describe '#to_h' do
    it 'returns a hash with all expected keys' do
      h = utterance.to_h
      expect(h).to include(:id, :content, :speaker, :speech_act, :maxim_scores,
                           :violations, :implicatures, :confidence,
                           :overall_compliance, :violated_maxims, :created_at)
    end
  end
end
