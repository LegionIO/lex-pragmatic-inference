# frozen_string_literal: true

require 'legion/extensions/pragmatic_inference/helpers/constants'
require 'legion/extensions/pragmatic_inference/helpers/utterance'
require 'legion/extensions/pragmatic_inference/helpers/pragmatic_engine'
require 'legion/extensions/pragmatic_inference/runners/pragmatic_inference'

module Legion
  module Extensions
    module PragmaticInference
      class Client
        include Runners::PragmaticInference

        def initialize(**)
          @engine = Helpers::PragmaticEngine.new
        end

        private

        attr_reader :engine
      end
    end
  end
end
