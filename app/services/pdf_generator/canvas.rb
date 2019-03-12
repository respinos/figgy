# frozen_string_literal: true
class PDFGenerator
  class Canvas
    # Letter width/height in points for a PDF.
    LETTER_WIDTH = PDF::Core::PageGeometry::SIZES["LETTER"].first
    LETTER_HEIGHT = PDF::Core::PageGeometry::SIZES["LETTER"].last
    BITONAL_SIZE = 2000

    # Error raised when IIIF Manifests have an invalid structure
    class InvalidIIIFManifestError < StandardError; end

    attr_reader :canvas

    # @param [Hash] canvas
    def initialize(canvas)
      @canvas = canvas
      validate!
    end

    # Ensure that the IIIF Manifest canvas has a valid structure
    # @raise [InvalidIIIFManifestError]
    def validate!
      raise(InvalidIIIFManifestError, "IIIF Manifest canvas does not reference a resource") unless canvas.key?("id")
      raise(InvalidIIIFManifestError, "IIIF Manifest canvas does not specify a width") unless canvas.key?("width")
      raise(InvalidIIIFManifestError, "IIIF Manifest canvas does not specify a height") unless canvas.key?("height")
      raise(InvalidIIIFManifestError, "IIIF Manifest canvas does not specify a service URL") unless canvas.key?("service") && !canvas["service"].empty? && canvas["service"].first.key?("id")
    end

    # Access the width for the canvas
    # @return [Integer]
    def width
      canvas["width"]
    end

    # Access the height for the canvas
    # @return [Integer]
    def height
      canvas["height"]
    end

    # Access the URL for the IIIF image server
    # @return [String]
    def url
      canvas["service"].first["id"]
    end
  end
end
