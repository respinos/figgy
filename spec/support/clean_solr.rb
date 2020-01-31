# frozen_string_literal: true
SOLR_TEST_URL = "http://#{Figgy.lando_config.solr[:host]}:#{ENV['TEST_JETTY_PORT'] || Figgy.lando_config.solr[:port]}/solr/figgy-core-test"
RSpec.configure do |config|
  config.before(:each) do
    client = RSolr.connect(url: SOLR_TEST_URL)
    client.delete_by_query("*:*", params: { softCommit: true })
  end
end
