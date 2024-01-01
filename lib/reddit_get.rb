# frozen_string_literal: true

require 'net/http'
require 'json'

require_relative 'scheduler'
require_relative 'reddit_get/version'

module RedditGet
  class Error < StandardError; end

  # Allow to use method call chains instead of Hash keys navigation
  class Data
    def initialize(data)
      @data = data
    end

    def [](key)
      @data.fetch(key)
    end

    def method_missing(method, *_args)
      @data.send(method)
    rescue NoMethodError
      out = @data.fetch(method.to_s)
      case out
      when Hash
        Data.new(out)
      when Array
        out.map { |i| Data.new(i) }
      else
        out
      end
    end

    def respond_to_missing?(method, include_private = false)
      @data.key?(method.to_s) || super
    end
  end

  # Grab subreddit top page as json
  class Subreddit
    BASE_URL = 'https://old.reddit.com'

    def self.collect_all(subreddits, with_comments: false, limit: 25)
      raise TypeError, 'Must pass an array of subreddits' unless subreddits.is_a?(Array)

      results = subreddits.zip([]).to_h
      subreddits.uniq.each do |subreddit|
        grab_posts(results, subreddit, with_comments: with_comments, limit: limit)
      end
      scheduler_run
      Data.new(results)
    end

    def self.collect(subreddit, with_comments: false, limit: 25)
      collect_all([subreddit], with_comments: with_comments, limit: limit)
    end

    class << self
      private

      def scheduler_run
        scheduler = Scheduler.new
        Fiber.set_scheduler scheduler
        scheduler.run
      end

      def grab_posts(results, subreddit, with_comments:, limit:)
        Fiber.new do
          results[subreddit] = get_reddit_posts(subreddit, limit: limit).map! do |post|
            grab_comments(post) if with_comments
            post['data']
          end
        end.resume
      end

      def grab_comments(post)
        url = post['data']['permalink']
        Fiber.new do
          post['data']['comments'] = get_reddit_comments(url).map! do |comment|
            comment['data']
          end
        end.resume
      end

      def get_reddit_posts(subreddit, limit: 25)
        get_json(URI("#{BASE_URL}/r/#{subreddit}.json?limit=#{limit}")).dig('data', 'children')
      end

      def get_reddit_comments(url)
        get_json("#{BASE_URL}#{url}.json")[1].dig('data', 'children')
      end

      def get_json(uri)
        req = Net::HTTP::Get.new(
          uri,
          { 'User-Agent':
              'Mozilla/5.0 (Windows NT 6.1; Win64; x64; rv:47.0) Gecko/20100101 Firefox/47.0' }
        )
        body = Net::HTTP.start('old.reddit.com', 443, use_ssl: true) do |http|
          http.request(req)
        end.body

        JSON.parse(body)
      end
    end
  end
end
