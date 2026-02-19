# frozen_string_literal: true

module Oroshi
  module DocumentationHelper
    # Generate a link to a documentation page with bilingual support
    def doc_link_to(section, page = nil, options = {})
      label = if page
                t("oroshi.documentation.pages.#{section}.#{page}")
              else
                t("oroshi.documentation.sections.#{section}")
              end

      path = if page
               documentation_page_path(section: section, page: page, locale: I18n.locale)
             else
               documentation_section_path(section: section, locale: I18n.locale)
             end

      css_class = options[:class] || "doc-link"
      link_to label, path, class: css_class
    end

    # Generate a "See Also" cross-reference list
    def doc_see_also(*references)
      content_tag :div, class: "doc-see-also mt-4 p-3 bg-light rounded" do
        concat content_tag(:h6, t("oroshi.documentation.chrome.see_also"), class: "text-muted mb-2")
        concat content_tag(:ul, class: "list-unstyled mb-0") {
          references.each do |ref|
            section, page = ref.to_s.split("/")
            concat content_tag(:li, class: "mb-1") {
              concat icon("arrow-right-short", class: "text-primary me-1")
              concat doc_link_to(section, page)
            }
          end
        }
      end
    end

    # Contextual help icon that links from main app to documentation
    def documentation_help_link(section, page = nil)
      path = if page
               documentation_page_path(section: section, page: page, locale: I18n.locale)
             else
               documentation_section_path(section: section, locale: I18n.locale)
             end

      link_to path, class: "doc-help-link text-muted", target: "_blank",
              data: { tippy_content: t("oroshi.documentation.chrome.help_tooltip") } do
        icon("question-circle")
      end
    end

    # Generate breadcrumb items for the current documentation page
    def doc_breadcrumbs
      crumbs = [
        { label: t("oroshi.documentation.chrome.home"), path: documentation_index_path(locale: I18n.locale) }
      ]

      if @current_section.present?
        crumbs << {
          label: t("oroshi.documentation.sections.#{@current_section}"),
          path: documentation_section_path(section: @current_section, locale: I18n.locale)
        }
      end

      if @current_page.present?
        crumbs << {
          label: t("oroshi.documentation.pages.#{@current_section}.#{@current_page}"),
          path: nil
        }
      end

      crumbs
    end

    # Render a screenshot image with proper alt text and caption
    def doc_screenshot(name, caption_key = nil)
      alt = caption_key ? t(caption_key) : name.humanize
      image_path = "docs/#{name}.png"

      content_tag :figure, class: "doc-screenshot my-3" do
        concat image_tag(image_path, alt: alt, class: "img-fluid rounded shadow-sm border", loading: "lazy")
        if caption_key
          concat content_tag(:figcaption, t(caption_key), class: "text-muted small mt-1 text-center")
        end
      end
    end

    # Render a Mermaid workflow diagram
    def doc_diagram(diagram_content)
      content_tag :div, class: "doc-diagram my-3", data: {
        controller: "documentation-diagram",
        documentation_diagram_definition_value: diagram_content
      } do
        content_tag :div, "", class: "mermaid"
      end
    end

    # Render a step-by-step workflow guide
    def doc_steps(&block)
      content_tag :div, class: "doc-steps", &block
    end

    def doc_step(number, title_key, &block)
      content_tag :div, class: "doc-step d-flex mb-3" do
        concat content_tag(:div, number, class: "doc-step-number bg-primary text-white rounded-circle d-flex align-items-center justify-content-center flex-shrink-0 me-3")
        concat content_tag(:div, class: "doc-step-content") {
          concat content_tag(:h6, t(title_key), class: "mb-1")
          concat capture(&block) if block
        }
      end
    end

    # Render a key concept callout box
    def doc_callout(type = :info, &block)
      icons = { info: "info-circle-fill", tip: "lightbulb-fill", warning: "exclamation-triangle-fill", important: "exclamation-circle-fill" }
      colors = { info: "primary", tip: "success", warning: "warning", important: "danger" }

      content_tag :div, class: "doc-callout alert alert-#{colors[type]} d-flex align-items-start my-3" do
        concat content_tag(:div, icon(icons[type], size: 18), class: "me-2 flex-shrink-0 mt-1")
        concat content_tag(:div, class: "flex-grow-1", &block)
      end
    end

    # Bootstrap icon name for each documentation section
    def section_icon(section_key)
      {
        getting_started: "rocket-takeoff",
        orders: "cart-check",
        supply_chain: "box-seam",
        production: "gear-wide-connected",
        shipping: "truck",
        financials: "graph-up-arrow",
        admin: "sliders"
      }[section_key.to_sym] || "file-text"
    end

    # Language toggle preserving current page
    def doc_locale_toggle
      current_path = request.path
      other_locale = I18n.locale == :ja ? :en : :ja
      label = I18n.locale == :ja ? "English" : "日本語"
      flag = I18n.locale == :ja ? "🇬🇧" : "🇯🇵"

      link_to "#{flag} #{label}", url_for(locale: other_locale), class: "btn btn-sm btn-outline-secondary"
    end
  end
end
