# frozen_string_literal: true

module OroshiHelper
  def required_field_label(field, object)
    @current_validators ||= object.class.validators
    @current_required_fields ||= required_fields(@current_validators)
    return unless @current_required_fields.include?(field)

    content_tag(:span, '&nbsp;*'.html_safe,
                class: 'required cursor-default',
                data: { controller: 'tippy', tippy_content: "\u5FC5\u8981" })
  end

  def required_fields(validators)
    validators.select do |v|
      v.is_a?(ActiveModel::Validations::PresenceValidator)
    end.flat_map(&:attributes).map(&:to_sym)
  end

  def label_with_validation_warning(form, field, object, small = true)
    label_html = form.label(field, class: "form-label text-nowrap #{'small' if small}")
    required_html = required_field_label(field, object)

    content_tag(:div, class: 'd-flex') do
      label_html.concat(required_html)
    end
  end
end
