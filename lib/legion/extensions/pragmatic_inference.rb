# frozen_string_literal: true

require 'legion/extensions/pragmatic_inference/version'
require 'legion/extensions/pragmatic_inference/helpers/constants'
require 'legion/extensions/pragmatic_inference/helpers/utterance'
require 'legion/extensions/pragmatic_inference/helpers/pragmatic_engine'
require 'legion/extensions/pragmatic_inference/runners/pragmatic_inference'

module Legion
  module Extensions
    module PragmaticInference
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
