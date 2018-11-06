# frozen_string_literal: true
class PlaylistDecorator < Valkyrie::ResourceDecorator
  display :label,
          :visibility

  display_in_manifest [:label]

  delegate :members, to: :wayfinder

  def manageable_files?
    true
  end

  def manageable_structure?
    false
  end

  def title
    label
  end
end
