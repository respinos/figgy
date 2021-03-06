# frozen_string_literal: true
require_relative "boot"
require_relative "read_only_mode"
require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
Bundler.require(*Rails.groups)
module Figgy
  class Application < Rails::Application
    config.assets.quiet = true
    config.generators do |generate|
      generate.helper false
      generate.javascripts false
      generate.request_specs false
      generate.routing_specs false
      generate.stylesheets false
      generate.test_framework :rspec
      generate.view_specs false
    end
    config.action_controller.action_on_unpermitted_parameters = :raise
    config.active_job.queue_adapter = :sidekiq
    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "*"
        resource "/graphql", headers: :any, methods: [:post]
      end
    end
    config.autoload_paths += Dir[Rails.root.join("app", "resources", "*")]
    config.autoload_paths += Dir[Rails.root.join("app", "resources", "numismatics", "*")]
    config.active_record.schema_format = :sql
  end
end
