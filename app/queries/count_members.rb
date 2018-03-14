# frozen_string_literal: true
class CountMembers
  def self.queries
    [:count_members]
  end

  attr_reader :query_service
  delegate :orm_class, to: :resource_factory
  delegate :resource_factory, to: :query_service
  def initialize(query_service:)
    @query_service = query_service
  end

  def count_members(resource:, model: nil)
    if model
      orm_class.connection.execute(find_members_with_resource_query(resource, model)).first["count"]
    else
      orm_class.connection.execute(find_members_query(resource)).first["count"]
    end
  end

  def find_members_query(resource)
    <<-SQL
      SELECT COUNT(*) FROM orm_resources a,
      jsonb_array_elements(a.metadata->'member_ids') AS b(member)
      JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = '#{resource.id}'
    SQL
  end

  def find_members_with_resource_query(resource, model)
    <<-SQL
      SELECT COUNT(*) FROM orm_resources a,
      jsonb_array_elements(a.metadata->'member_ids') AS b(member)
      JOIN orm_resources member ON (b.member->>'id')::#{id_type} = member.id WHERE a.id = '#{resource.id}'
      AND member.internal_resource = '#{model}'
    SQL
  end

  def id_type
    @id_type ||= orm_class.columns_hash["id"].type
  end
end
