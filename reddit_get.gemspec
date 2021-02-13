# frozen_string_literal: true

require_relative 'lib/reddit_get/version'

Gem::Specification.new do |spec|
  spec.name          = 'reddit_get'
  spec.version       = RedditGet::VERSION
  spec.authors       = ['Alessandro']
  spec.email         = ['4143332+AlessandroMinali@users.noreply.github.com']

  spec.summary       = 'Simply grab subreddit posts and their comments'
  spec.description   = 'A clean interface to handle reddit data without auth.'
  spec.homepage      = 'https://github.com/AlessandroMinali/reddit_get'
  spec.license       = 'MIT'
  spec.required_ruby_version = Gem::Requirement.new('>= 3.0.0')

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = 'https://github.com/AlessandroMinali/reddit_get'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'rubocop'
end
