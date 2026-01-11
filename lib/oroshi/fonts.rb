# frozen_string_literal: true

module Oroshi
  # Helper module for managing Japanese font paths in the engine
  # Used by Prawn PDF generation classes
  module Fonts
    class << self
      # Returns the absolute path to a font file in the engine's assets
      # @param font_name [String] The font filename (e.g., "MPLUS1p-Regular.ttf")
      # @return [String] Absolute path to the font file
      def font_path(font_name)
        Oroshi::Engine.root.join("app/assets/fonts/#{font_name}").to_s
      end

      # Configures Prawn document with Japanese fonts
      # @param pdf [Prawn::Document] The Prawn document instance
      def configure_prawn_fonts(pdf)
        pdf.font_families.update(
          "MPLUS1p" => {
            normal: font_path("MPLUS1p-Regular.ttf"),
            bold: font_path("MPLUS1p-Bold.ttf"),
            light: font_path("MPLUS1p-Light.ttf")
          },
          "SawarabiMincho" => {
            normal: font_path("SawarabiMincho-Regular.ttf")
          },
          "TakaoPMincho" => {
            normal: font_path("TakaoPMincho.ttf")
          }
        )
      end

      # Returns all available font families
      # @return [Array<String>] List of font family names
      def available_fonts
        %w[MPLUS1p SawarabiMincho TakaoPMincho]
      end
    end
  end
end
