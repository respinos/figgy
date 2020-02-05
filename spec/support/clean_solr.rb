# frozen_string_literal: true
SOLR_TEST_URL = "http://#{ENV['lando_figgy_test_solr_conn_host'] || "127.0.0.1"}:#{ENV['TEST_JETTY_PORT'] || ENV['lando_figgy_test_solr_port'] || 8984}/solr/figgy-core-test"
RSpec.configure do |config|
  config.before(:each) do
    client = RSolr.connect(url: SOLR_TEST_URL)
    client.delete_by_query("*:*", params: { softCommit: true })
  end
end
