# frozen_string_literal: true
class EphemeraTermDecorator < Valkyrie::ResourceDecorator
  display :label, :uri, :code, :tgm_label, :lcsh_label, :vocabulary

  # TODO: Rename to decorated_vocabulary
  def vocabulary
    wayfinder.decorated_vocabulary
  end

  def label
    Array.wrap(super).first
  end
  alias title label
  alias to_s label

  def external_uri_exists?
    value = Array.wrap(model.uri).first
    value.present?
  end

  def internal_url
    return Array.wrap(model.uri).first if vocabulary.blank?
    vocabulary_uri = vocabulary.uri.to_s.end_with?("/") ? vocabulary.uri.to_s : vocabulary.uri.to_s + "/"
    URI.join(vocabulary_uri, camelized_label)
  end

  def uri
    external_uri_exists? ? Array.wrap(super).first : internal_url
  end

  def manageable_files?
    false
  end

  def manageable_structure?
    false
  end

  private

    def camelized_label
      Array.wrap(label).first.gsub(/\s/, "_").camelize(:lower)
    end
end
