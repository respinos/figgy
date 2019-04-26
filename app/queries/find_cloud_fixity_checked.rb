# frozen_string_literal: true
class FindCloudFixityChecked
  def self.queries
    [:find_cloud_fixity_checked]
  end

  attr_reader :query_service
  delegate :resource_factory, :run_query, to: :query_service
  delegate :orm_class, to: :resource_factory
  def initialize(query_service:)
    @query_service = query_service
  end

  def query(order_by_property: "updated_at", order_by: "ASC")
    <<-SQL
      select * FROM orm_resources WHERE
      metadata @> ?
      ORDER BY #{order_by_property} #{order_by} LIMIT ?
    SQL
  end

  def find_cloud_fixity_checked(sort: "ASC", limit: 50, order_by_property: "updated_at")
    internal_array = { "status" => Array.wrap("SUCCESS") }
    run_query(query(order_by_property: order_by_property, order_by: sort), internal_array.to_json, limit)
  end
end
