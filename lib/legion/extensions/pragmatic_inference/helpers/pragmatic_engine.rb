# frozen_string_literal: true

module Legion
  module Extensions
    module PragmaticInference
      module Helpers
        class PragmaticEngine
          attr_reader :utterances, :history

          def initialize
            @utterances = {}
            @history    = []
          end

          def analyze_utterance(content:, speaker:, speech_act:, literal_meaning: nil,
                                domain: nil, maxim_scores: {})
            trim_utterances if @utterances.size >= Constants::MAX_UTTERANCES

            utterance = Utterance.new(
              content:         content,
              speaker:         speaker,
              speech_act:      speech_act,
              literal_meaning: literal_meaning,
              domain:          domain,
              maxim_scores:    maxim_scores
            )

            @utterances[utterance.id] = utterance
            record_history(utterance.id, :analyzed)
            utterance
          end

          def detect_violations(utterance_id:)
            utterance = @utterances[utterance_id]
            return [] unless utterance

            violations = []
            utterance.maxim_scores.each do |maxim, score|
              next if score >= 0.5

              violation_type = classify_violation(score)
              violation = { maxim: maxim, violation_type: violation_type, score: score }
              violations << violation
              utterance.violations << violation
            end

            violations
          end

          def generate_implicature(utterance_id:, inferred_meaning:)
            utterance = @utterances[utterance_id]
            return nil unless utterance

            utterance.add_implicature(meaning: inferred_meaning)
            record_history(utterance_id, :implicature_added)
            inferred_meaning
          end

          def speaker_profile(speaker:)
            speaker_utterances = by_speaker(speaker: speaker)
            return { speaker: speaker, utterance_count: 0, compliance_by_maxim: {} } if speaker_utterances.empty?

            compliance_by_maxim = Constants::MAXIMS.to_h do |maxim|
              scores = speaker_utterances.map { |u| u.maxim_scores[maxim] }
              mean = scores.sum / scores.size.to_f
              [maxim, mean.round(3)]
            end

            {
              speaker:             speaker,
              utterance_count:     speaker_utterances.size,
              compliance_by_maxim: compliance_by_maxim,
              overall_compliance:  (compliance_by_maxim.values.sum / compliance_by_maxim.size.to_f).round(3)
            }
          end

          def by_speech_act(speech_act:)
            @utterances.values.select { |u| u.speech_act == speech_act }
          end

          def by_speaker(speaker:)
            @utterances.values.select { |u| u.speaker == speaker }
          end

          def most_violated_maxim
            return nil if @utterances.empty?

            violation_counts = Hash.new(0)
            @utterances.each_value do |utterance|
              utterance.violated_maxims.each { |maxim| violation_counts[maxim] += 1 }
            end

            return nil if violation_counts.empty?

            violation_counts.max_by { |_maxim, count| count }&.first
          end

          def overall_cooperation
            return 0.0 if @utterances.empty?

            total = @utterances.values.sum(&:overall_compliance)
            total / @utterances.size.to_f
          end

          def reinforce(utterance_id:)
            utterance = @utterances[utterance_id]
            return unless utterance

            utterance.update_confidence(Constants::REINFORCEMENT_RATE)
          end

          def decay_all
            @utterances.each_value do |utterance|
              utterance.update_confidence(-Constants::DECAY_RATE)
            end
          end

          def count
            @utterances.size
          end

          def to_h
            {
              utterance_count:     @utterances.size,
              overall_cooperation: overall_cooperation.round(3),
              most_violated_maxim: most_violated_maxim,
              history_size:        @history.size,
              speakers:            @utterances.values.map(&:speaker).uniq.size
            }
          end

          private

          def classify_violation(score)
            if score < 0.1
              :violating
            elsif score < 0.3
              :flouting
            elsif score < 0.5
              :opting_out
            else
              :none
            end
          end

          def record_history(utterance_id, event)
            @history << { utterance_id: utterance_id, event: event, at: Time.now.utc }
            @history.shift while @history.size > Constants::MAX_HISTORY
          end

          def trim_utterances
            overflow = @utterances.size - Constants::MAX_UTTERANCES + 1
            keys_to_remove = @utterances.keys.first(overflow)
            keys_to_remove.each { |k| @utterances.delete(k) }
          end
        end
      end
    end
  end
end
