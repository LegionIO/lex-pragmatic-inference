# frozen_string_literal: true

RSpec.describe Legion::Extensions::PragmaticInference::Helpers::Constants do
  describe 'MAXIMS' do
    it 'contains four Gricean maxims' do
      expect(described_class::MAXIMS).to eq(%i[quality quantity relevance manner])
    end
  end

  describe 'VIOLATION_TYPES' do
    it 'contains expected violation types' do
      expect(described_class::VIOLATION_TYPES).to include(:none, :flouting, :violating, :opting_out)
    end
  end

  describe 'SPEECH_ACTS' do
    it 'contains expected speech act types' do
      expect(described_class::SPEECH_ACTS).to include(:assert, :question, :request, :promise, :warn, :inform, :suggest)
    end
  end

  describe 'MAXIM_DESCRIPTIONS' do
    it 'has a description for each maxim' do
      described_class::MAXIMS.each do |maxim|
        expect(described_class::MAXIM_DESCRIPTIONS[maxim]).to be_a(String)
      end
    end
  end

  describe '.valid_maxim?' do
    it 'returns true for valid maxims' do
      expect(described_class.valid_maxim?(:quality)).to be true
      expect(described_class.valid_maxim?(:manner)).to be true
    end

    it 'returns false for invalid maxims' do
      expect(described_class.valid_maxim?(:sincerity)).to be false
    end
  end

  describe '.valid_violation_type?' do
    it 'returns true for valid types' do
      expect(described_class.valid_violation_type?(:flouting)).to be true
    end

    it 'returns false for invalid types' do
      expect(described_class.valid_violation_type?(:unknown)).to be false
    end
  end

  describe '.valid_speech_act?' do
    it 'returns true for valid speech acts' do
      expect(described_class.valid_speech_act?(:assert)).to be true
    end

    it 'returns false for invalid speech acts' do
      expect(described_class.valid_speech_act?(:perform)).to be false
    end
  end

  describe 'numeric constants' do
    it 'has correct confidence bounds' do
      expect(described_class::CONFIDENCE_FLOOR).to eq(0.0)
      expect(described_class::CONFIDENCE_CEILING).to eq(1.0)
      expect(described_class::DEFAULT_CONFIDENCE).to eq(0.5)
    end

    it 'has positive reinforcement and decay rates' do
      expect(described_class::REINFORCEMENT_RATE).to be > 0
      expect(described_class::DECAY_RATE).to be > 0
    end
  end
end
