# RedditGet

This gem allows you to grab posts and comments from Reddit without any auth.
It concurrently grabs multiple subbreddits at a time to utilize your machine as much as possible and increase throughput.

No setup and a clean interface makes this gem ideal when you just want to process public reddit data.
Zero dependencies.

The [Redd gem](https://github.com/avinashbot/redd) seems to be abandoned so I created this gem to meet my needs.

## Installation

```ruby
gem 'reddit_get'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install reddit_get

## Usage

### You want to grab many subreddits
```ruby
results = RedditGet::Subreddit.collect_all %w[gaming videos movies funny]
results # will hold RedditGet::Data which acts like a hash
results['gaming'].each do |post|
  puts post['title']
end
results.gaming
```

### You want to grab one subreddit
```ruby
result = RedditGet::Subreddit.collect('gaming')

results.gaming.each do |post|
  puts post.title # all gaming posts titles
end 
results['gaming'] # works too!
```

## You want to grab comments for each post
```ruby
results = RedditGet::Subreddit.collect_all %w[gaming videos movies funny], with_comments: true
results.gaming.each do |post|
  puts post.title
  post.comments.each do |comment|
    puts comment.body
  end
end

# also works with single subreddit
RedditGet::Subreddit.collect 'gaming', with_comments: true
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/AlessandroMinali/reddit_get.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
