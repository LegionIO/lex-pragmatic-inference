# frozen_string_literal: true

require 'legion/extensions/pragmatic_inference/client'

RSpec.describe Legion::Extensions::PragmaticInference::Client do
  it 'responds to all runner methods' do
    client = described_class.new
    expect(client).to respond_to(:analyze_utterance)
    expect(client).to respond_to(:detect_maxim_violations)
    expect(client).to respond_to(:generate_pragmatic_implicature)
    expect(client).to respond_to(:speaker_pragmatic_profile)
    expect(client).to respond_to(:utterances_by_speech_act)
    expect(client).to respond_to(:utterances_by_speaker)
    expect(client).to respond_to(:most_violated_maxim)
    expect(client).to respond_to(:overall_cooperative_compliance)
    expect(client).to respond_to(:update_pragmatic_inference)
    expect(client).to respond_to(:pragmatic_inference_stats)
  end
end
