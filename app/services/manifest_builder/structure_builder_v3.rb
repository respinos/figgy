# frozen_string_literal: true
class ManifestBuilder
  class StructureBuilderV3 < IIIFManifest::V3::ManifestBuilder::StructureBuilder
    def range_builder(top_range)
      RangeBuilder.new(
        top_range,
        record, true,
        canvas_builder_factory: canvas_builder_factory,
        iiif_range_factory: iiif_range_factory
      )
    end

    class RangeBuilder < IIIFManifest::V3::ManifestBuilder::RangeBuilder
      def build_range
        super
        range["items"] =
          canvas_builders.collect do |cb|
            wrapped_range(cb) do
              {
                "type" => "Canvas",
                "id" => "#{cb.path}#t=0,#{duration(cb)}"
              }
            end
          end
      end

      def wrapped_range(cb)
        return yield if record.structure.is_a?(Structure)
        {
          "type" => "Range",
          "label": {
            "@none": [
              label(cb)
            ]
          },
          "id": "#{cb.path}/range",
          "items": [
            yield
          ]
        }
      end

      def duration(canvas_builder)
        proxy_id = canvas_builder.record.structure.proxy.first
        file_set_presenter = parent.file_set_presenters.find { |x| x.id == proxy_id.to_s }
        file_set_presenter&.display_content&.duration
      end

      def label(canvas_builder)
        proxy_id = canvas_builder.record.structure.proxy.first
        file_set_presenter = parent.file_set_presenters.find { |x| x.id == proxy_id.to_s }
        file_set_presenter&.display_content&.label
      end
    end
  end
end