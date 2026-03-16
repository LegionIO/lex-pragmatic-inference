# frozen_string_literal: true

require_relative 'lib/legion/extensions/pragmatic_inference/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-pragmatic-inference'
  spec.version       = Legion::Extensions::PragmaticInference::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Pragmatic Inference'
  spec.description   = 'Gricean cooperative maxims and conversational implicature engine for brain-modeled agentic AI'
  spec.homepage      = 'https://github.com/LegionIO/lex-pragmatic-inference'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']        = spec.homepage
  spec.metadata['source_code_uri']     = 'https://github.com/LegionIO/lex-pragmatic-inference'
  spec.metadata['documentation_uri']   = 'https://github.com/LegionIO/lex-pragmatic-inference'
  spec.metadata['changelog_uri']       = 'https://github.com/LegionIO/lex-pragmatic-inference'
  spec.metadata['bug_tracker_uri']     = 'https://github.com/LegionIO/lex-pragmatic-inference/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-pragmatic-inference.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
