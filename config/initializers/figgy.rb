# frozen_string_literal: true
module Figgy
  def config
    @config ||= config_yaml.with_indifferent_access
  end

  class Lando
    def database
      return default_database unless status
      db_status = status["figgy_#{Rails.env.downcase}_db"][0]
      {
        host: db_status["external_connection"]["host"],
        port: db_status["external_connection"]["port"],
        username: db_status["creds"]["user"],
        password: db_status["creds"]["password"]
      }
    end

    def solr
      return default_solr unless status
      solr_status = status["figgy_#{Rails.env.downcase}_solr"][0]
      {
        host: solr_status["external_connection"]["host"],
        port: solr_status["external_connection"]["port"]
      }
    end

    def default_database
      {
        host: nil,
        port: nil,
        username: nil,
        password: nil
      }
    end

    def default_solr
      {
        host: "localhost",
        port: "8983"
      }
    end

    def status
      @status ||=
        begin
          JSON.parse(`lando info --format json`).group_by { |x| x["service"] }
        rescue
          nil
        end
    end
  end

  def lando_config
    @lando_config ||= Lando.new
  end

  def messaging_client
    @messaging_client ||= MessagingClient.new(Figgy.config["events"]["server"])
  end

  def geoblacklight_messaging_client
    @geoblacklight_messaging_client ||= GeoblacklightMessagingClient.new(Figgy.config["events"]["server"])
  end

  def geoserver_messaging_client
    @geoserver_messaging_client ||= GeoserverMessagingClient.new(Figgy.config["events"]["server"])
  end

  def orangelight_messaging_client
    @orangelight_messaging_client ||= OrangelightMessagingClient.new(Figgy.config["events"]["server"])
  end

  def default_url_options
    @default_url_options ||= ActionMailer::Base.default_url_options
  end

  def campus_ip_ranges
    @campus_ip_ranges ||= config[:access_control][:campus_ip_ranges].map { |str| IPAddr.new(str) }
  end

  private

    def config_yaml
      YAML.safe_load(ERB.new(File.read(Rails.root.join("config", "config.yml"))).result, [], [], true)[Rails.env]
    end

    module_function :config, :config_yaml, :messaging_client, :geoblacklight_messaging_client, :geoserver_messaging_client, :orangelight_messaging_client, :default_url_options, :campus_ip_ranges, :lando_config
end
