# frozen_string_literal: true

require_relative 'lib/reddit_get'

# RedditGet#collect
expect = RedditGet::Subreddit.collect('gaming')
raise 'Not a hash' unless expect.is_a? RedditGet::Data
raise 'No results returned' unless expect.values.any?

begin
  RedditGet::Subreddit.collect(['gaming'])
rescue URI::InvalidURIError
  raise_error = true
ensure
  raise 'Should fail' unless raise_error
end

# RedditGet#collect_all
expect = RedditGet::Subreddit.collect_all(%w[gaming videos])
raise 'Not a hash' unless expect.is_a? RedditGet::Data
raise 'No results returned' unless expect.values.any?

expect = RedditGet::Subreddit.collect_all(%w[gaming videos gaming])
raise 'Must remove dups' unless expect.keys.count == 2

begin
  RedditGet::Subreddit.collect_all('gaming')
rescue TypeError
  raise_error = true
ensure
  raise 'Should fail' unless raise_error
end

expect = RedditGet::Subreddit.collect_all(%w[gaming videos], with_comments: true)
raise 'Must have comments' unless expect.gaming.all? { |i| i.comments.any? }
