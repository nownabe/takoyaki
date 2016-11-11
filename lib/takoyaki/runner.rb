# frozen_string_literal: true

require "yaml"
require "octokit"

require "pry"

require "takoyaki/commands"

module Takoyaki
  class Runner
    attr_reader :args

    def initialize(args = [])
      @args = args
    end

    def run
      case command
      when "activities"
        Commands::Activities.new.execute
      when "reviews"
        Commands::Reviews.new(*args[1..-1]).execute
      end
    end

    def command
      args.first
    end
  end
end
