# frozen_string_literal: true
FactoryBot.define do
  factory :event do
    type "Test type"
    status "SUCCESS"
    message "Test message"
    to_create do |instance|
      Valkyrie.config.metadata_adapter.persister.save(resource: instance)
    end
  end
end
