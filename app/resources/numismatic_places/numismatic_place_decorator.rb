# frozen_string_literal: true
class NumismaticPlaceDecorator < Valkyrie::ResourceDecorator
  display :city,
          :geo_state,
          :region

  def manageable_files?
    false
  end

  def manageable_order?
    false
  end

  def manageable_structure?
    false
  end

  def title
    [city, geo_state, region].join(", ")
  end
end
