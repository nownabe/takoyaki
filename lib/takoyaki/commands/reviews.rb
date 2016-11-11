# frozen_string_literal: true

module Takoyaki
  module Commands
    class Reviews
      attr_reader :target

      def initialize(target = nil)
        @target = target
      end

      def execute
        output
      end

      private

      def client
        @client ||= Octokit::Client.new(access_token: config["access_token"])
      end

      def config
        @config ||= YAML.load_file(File.expand_path("~/.takoyaki.yaml"))
      end

      def filtered_reviews
        @filtered_reviews ||=
          reviews.each_with_object({}) do |(repo, prs), obj|
            obj[repo] = prs.keep_if { |pr| pr[:reviewers].include?(user) }
          end
      end

      def generate_pull_request_hash(pr)
        reviewers = pr.assignees.map(&:login).delete_if { |u| u == pr.user.login }
        {
          number: pr.number,
          title: pr.title,
          author: pr.user.login,
          reviewers: reviewers,
          created_at: pr.created_at.getlocal.strftime("%Y-%m-%d"),
          url: pr.html_url
        }
      end
      alias pr_hash generate_pull_request_hash

      def only_me?
        target != "all"
      end

      def fetch_pull_requests(repository)
        client.pull_requests(repository, state: "open")
      end
      alias fetch_pr fetch_pull_requests

      def format_pull_request(pr)
        "- [##{pr[:number]} #{pr[:title]}](#{pr[:url]}) " \
          "from #{pr[:created_at]}, " \
          "reviewes: #{pr[:reviewers].join(', ')}"
      end
      alias format_pr format_pull_request

      def output
        output_reviews = only_me? ? filtered_reviews : reviews
        output_reviews.each do |repo, prs|
          next if prs.empty?
          puts "### #{repo}"
          prs.each { |pr| puts format_pr(pr) }
        end
      end

      def repositories
        config["repositories"].map do |org, repos|
          repos.map { |repo| "#{org}/#{repo}" }
        end.flatten
      end

      def reviews
        @reviews ||=
          repositories.each_with_object({}) do |repo, obj|
            obj[repo] = fetch_pr(repo).map { |pr| pr_hash(pr) }
          end
      end

      def user
        client.user.login
      end
    end
  end
end
