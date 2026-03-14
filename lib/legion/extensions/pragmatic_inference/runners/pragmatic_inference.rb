# frozen_string_literal: true

module Legion
  module Extensions
    module PragmaticInference
      module Runners
        module PragmaticInference
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def analyze_utterance(content:, speaker:, speech_act:, literal_meaning: nil,
                                domain: nil, maxim_scores: {}, **)
            return { success: false, error: :invalid_speech_act } unless Helpers::Constants.valid_speech_act?(speech_act)

            utterance = engine.analyze_utterance(
              content:         content,
              speaker:         speaker,
              speech_act:      speech_act,
              literal_meaning: literal_meaning,
              domain:          domain,
              maxim_scores:    maxim_scores
            )

            Legion::Logging.debug "[pragmatic_inference] analyzed utterance id=#{utterance.id[0..7]} " \
                                  "speaker=#{speaker} speech_act=#{speech_act} " \
                                  "compliance=#{utterance.overall_compliance.round(2)}"

            { success: true, utterance_id: utterance.id, overall_compliance: utterance.overall_compliance,
              violated_maxims: utterance.violated_maxims }
          end

          def detect_maxim_violations(utterance_id:, **)
            return { success: false, error: :invalid_utterance_id } if utterance_id.to_s.length < 3

            violations = engine.detect_violations(utterance_id: utterance_id)

            Legion::Logging.debug "[pragmatic_inference] violations detected id=#{utterance_id[0..7]} count=#{violations.size}"

            { success: true, utterance_id: utterance_id, violations: violations, violation_count: violations.size }
          end

          def generate_pragmatic_implicature(utterance_id:, inferred_meaning:, **)
            return { success: false, error: :invalid_utterance_id } if utterance_id.to_s.length < 3
            return { success: false, error: :invalid_inferred_meaning } if inferred_meaning.to_s.length < 3

            result = engine.generate_implicature(utterance_id: utterance_id, inferred_meaning: inferred_meaning)

            if result
              Legion::Logging.debug "[pragmatic_inference] implicature added id=#{utterance_id[0..7]}"
              { success: true, utterance_id: utterance_id, inferred_meaning: result }
            else
              Legion::Logging.debug "[pragmatic_inference] implicature failed: utterance not found id=#{utterance_id[0..7]}"
              { success: false, error: :utterance_not_found }
            end
          end

          def speaker_pragmatic_profile(speaker:, **)
            return { success: false, error: :invalid_speaker } if speaker.to_s.length < 3

            profile = engine.speaker_profile(speaker: speaker)

            Legion::Logging.debug "[pragmatic_inference] speaker profile speaker=#{speaker} " \
                                  "utterances=#{profile[:utterance_count]}"

            { success: true, **profile }
          end

          def utterances_by_speech_act(speech_act:, **)
            return { success: false, error: :invalid_speech_act } unless Helpers::Constants.valid_speech_act?(speech_act)

            utterances = engine.by_speech_act(speech_act: speech_act)

            Legion::Logging.debug "[pragmatic_inference] by_speech_act act=#{speech_act} count=#{utterances.size}"

            { success: true, speech_act: speech_act, utterances: utterances.map(&:to_h), count: utterances.size }
          end

          def utterances_by_speaker(speaker:, **)
            return { success: false, error: :invalid_speaker } if speaker.to_s.length < 3

            utterances = engine.by_speaker(speaker: speaker)

            Legion::Logging.debug "[pragmatic_inference] by_speaker speaker=#{speaker} count=#{utterances.size}"

            { success: true, speaker: speaker, utterances: utterances.map(&:to_h), count: utterances.size }
          end

          def most_violated_maxim(**)
            maxim = engine.most_violated_maxim

            Legion::Logging.debug "[pragmatic_inference] most violated maxim=#{maxim.inspect}"

            { success: true, maxim: maxim,
              description: maxim ? Helpers::Constants::MAXIM_DESCRIPTIONS[maxim] : nil }
          end

          def overall_cooperative_compliance(**)
            cooperation = engine.overall_cooperation
            total = engine.count

            Legion::Logging.debug "[pragmatic_inference] cooperation=#{cooperation.round(2)} total=#{total}"

            { success: true, cooperation: cooperation, utterance_count: total }
          end

          def update_pragmatic_inference(**)
            engine.decay_all

            Legion::Logging.debug "[pragmatic_inference] decay applied to #{engine.count} utterances"

            { success: true, decayed_count: engine.count, decay_rate: Helpers::Constants::DECAY_RATE }
          end

          def pragmatic_inference_stats(**)
            stats = engine.to_h

            Legion::Logging.debug "[pragmatic_inference] stats: utterances=#{stats[:utterance_count]} " \
                                  "cooperation=#{stats[:overall_cooperation]}"

            { success: true, **stats }
          end

          private

          def engine
            @engine ||= Helpers::PragmaticEngine.new
          end
        end
      end
    end
  end
end
