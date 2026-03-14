# frozen_string_literal: true

module Legion
  module Extensions
    module PragmaticInference
      module Helpers
        module Constants
          MAX_UTTERANCES   = 500
          MAX_IMPLICATURES = 200
          MAX_HISTORY      = 300

          DEFAULT_CONFIDENCE  = 0.5
          CONFIDENCE_FLOOR    = 0.0
          CONFIDENCE_CEILING  = 1.0
          REINFORCEMENT_RATE  = 0.1
          DECAY_RATE          = 0.02

          MAXIMS = %i[quality quantity relevance manner].freeze

          VIOLATION_TYPES = %i[none flouting violating opting_out].freeze

          SPEECH_ACTS = %i[assert question request promise warn inform suggest].freeze

          MAXIM_DESCRIPTIONS = {
            quality:   'be truthful, have evidence',
            quantity:  'be informative, not more than needed',
            relevance: 'be relevant to the conversation',
            manner:    'be clear, brief, orderly, unambiguous'
          }.freeze

          module_function

          def valid_maxim?(maxim)
            MAXIMS.include?(maxim)
          end

          def valid_violation_type?(type)
            VIOLATION_TYPES.include?(type)
          end

          def valid_speech_act?(act)
            SPEECH_ACTS.include?(act)
          end
        end
      end
    end
  end
end
