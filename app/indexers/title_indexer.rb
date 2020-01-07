# frozen_string_literal: true
class TitleIndexer
  attr_reader :resource
  def initialize(resource:)
    @resource = resource
  end

  def to_solr
    return {} unless resource.decorate.respond_to?(:title) && resource.decorate.title.present?
    {
      figgy_title_tesim: title_strings,
      figgy_title_tesi: title_strings.first,
      figgy_title_ssim: title_strings,
      figgy_title_ssi: title_strings.first
    }
  end

  def title_strings
    @title_strings ||= Array.wrap(resource.decorate.title).map(&:to_s)
  end
end
