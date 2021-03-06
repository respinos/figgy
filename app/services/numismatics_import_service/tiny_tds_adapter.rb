# frozen_string_literal: true

class NumismaticsImportService::TinyTdsAdapter
  def initialize(dbhost:, dbport:, dbuser:, dbpass:)
    @client = TinyTds::Client.new username: dbuser, password: dbpass, host: dbhost, port: dbport, timeout: 60
  end

  # @param query [string]
  # @return array of hashes where the column names are the keys
  def execute(query:)
    @client.execute(query).to_a
  end
end
