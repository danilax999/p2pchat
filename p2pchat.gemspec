# frozen_string_literal: true

require_relative 'lib/p2pchat/version'

Gem::Specification.new do |spec|
  spec.name = 'p2pchat'
  spec.version = P2PChat::VERSION
  spec.authors = ['Daniil Kharitonov']
  spec.email = ['dan.haritonoff@gmail.com']

  spec.summary = 'P2P chat implementation using UDP hole punching method.'
  # spec.homepage = "TODO: Put your gem's website or public repo URL here."
  spec.license = 'MIT'
  spec.required_ruby_version = '>= 3.1.0'

  # spec.metadata['homepage_uri'] = spec.homepage
  # spec.metadata['source_code_uri'] = "TODO: Put your gem's public repo URL here."
  # spec.metadata['changelog_uri'] = "TODO: Put your gem's CHANGELOG.md URL here."

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end
  spec.bindir = 'bin'
  # spec.executables = spec.files.grep(%r{\Abin/}) { |f| File.basename(f) }
  spec.executables = %w[p2pchat p2pchat-server]
  spec.require_paths = ['lib']

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
