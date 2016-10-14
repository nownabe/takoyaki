# frozen_string_literal: true

require "yaml"
require "octokit"

require "pry"

module Takoyaki
  class Runner
    attr_reader :to, :from
    def initialize(args = [])
      @args = args

      # [to, from)
      now = Time.now
      to = now + 24 * 60 * 60
      @to = Time.new(to.year, to.month, to.day)
      from = to - 7 * 24 * 60 * 60
      @from = Time.new(from.year, from.month, from.day)
    end

    def run
      events = []
      page = 0
      res = client.user_events(user, per_page: 100, page: page)
      loop do
        res.each do |event|
          if from <= event.created_at && event.created_at < to
            events << event
          end
        end
        break if res.last.created_at < from
        page += 1
        res = client.user_events(user, per_page: 100, page: page)
      end
      repo_events = Hash.new { |h, k| h[k] = {} }
      events.each do |event|
        next unless repositories.include?(event.repo&.name)
        case event.type
        when "IssueCommentEvent", "IssuesEvent"
          repo_events[event.repo.name][event.payload.issue.number] = event
        when "PullRequestReviewCommentEvent", "PullRequestEvent"
          repo_events[event.repo.name][event.payload.pull_request.number] = event
        when "CreateEvent", "DeleteEvent", "PushEvent"
        else
          binding.pry
        end
      end
      repo_events.each do |repo, events|
        puts "### #{repo}"
        events.sort { |a, b| a[0] <=> b[0] }.each do |number, event|
          case event.type
          when /^Issue/
            puts "- [##{number} #{event.payload.issue.title}](#{event.payload.issue.html_url})"
          when /^PullRequest/
            puts "- [##{number} #{event.payload.pull_request.title}](#{event.payload.pull_request.html_url})"
          end
        end
        puts
      end
    end

    def client
      @client ||= Octokit::Client.new(access_token: config["access_token"])
    end

    def config
      @config ||= YAML.load_file(File.expand_path("~/.takoyaki.yaml"))
    end

    def event_types
      @event_types ||=
        %w(
          IssueCommentEvent
          PullRequestReviewCommentEvent
          IssuesEvent
          PullRequestEvent
        )
    end

    def repositories
      @repositories ||=
        config["repositories"].map do |org, repos|
          repos.map { |repo| "#{org}/#{repo}" }
        end.flatten
    end

    def user
      client.user.login
    end
  end
end
