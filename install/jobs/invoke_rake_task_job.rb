# frozen_string_literal: true

require "rake"
Rails.application.load_tasks

class InvokeRakeTaskJob < ApplicationJob
  def perform(args)
    Rake::Task[args["task"]].reenable
    Rake::Task[args["task"]].invoke(args["args"])
  end
end
