# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module PragmaticInference
      module Helpers
        class Utterance
          attr_reader :id, :content, :speaker, :speech_act, :literal_meaning,
                      :domain, :maxim_scores, :violations, :implicatures,
                      :confidence, :created_at

          def initialize(content:, speaker:, speech_act:, literal_meaning: nil,
                         domain: nil, maxim_scores: {}, confidence: Constants::DEFAULT_CONFIDENCE)
            @id             = SecureRandom.uuid
            @content        = content
            @speaker        = speaker
            @speech_act     = speech_act
            @literal_meaning = literal_meaning
            @domain         = domain
            @maxim_scores   = build_maxim_scores(maxim_scores)
            @violations     = []
            @implicatures   = []
            @confidence     = confidence.clamp(Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING)
            @created_at     = Time.now.utc
          end

          def overall_compliance
            return 0.0 if @maxim_scores.empty?

            @maxim_scores.values.sum / @maxim_scores.size.to_f
          end

          def violated_maxims
            @maxim_scores.select { |_maxim, score| score < 0.5 }.keys
          end

          def add_implicature(meaning:)
            return if @implicatures.size >= Constants::MAX_IMPLICATURES

            @implicatures << { meaning: meaning, added_at: Time.now.utc }
          end

          def update_confidence(delta)
            @confidence = (@confidence + delta).clamp(Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING)
          end

          def to_h
            {
              id:                 @id,
              content:            @content,
              speaker:            @speaker,
              speech_act:         @speech_act,
              literal_meaning:    @literal_meaning,
              domain:             @domain,
              maxim_scores:       @maxim_scores,
              violations:         @violations,
              implicatures:       @implicatures,
              confidence:         @confidence,
              overall_compliance: overall_compliance,
              violated_maxims:    violated_maxims,
              created_at:         @created_at
            }
          end

          private

          def build_maxim_scores(scores)
            Constants::MAXIMS.to_h do |maxim|
              [maxim, (scores[maxim] || Constants::DEFAULT_CONFIDENCE).clamp(
                Constants::CONFIDENCE_FLOOR, Constants::CONFIDENCE_CEILING
              )]
            end
          end
        end
      end
    end
  end
end
