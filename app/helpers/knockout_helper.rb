module KnockoutHelper
  def ko_link_to(text, click, options = {})
    link_to text, 'javascript:void()', options.merge(ko click: click)
  end

  def ko_link_to_root(text, click, options = {})
    ko_link_to text, "$root.#{click}", options
  end

  def ko_text_field_tag(name, options = {})
    text_field_tag name, '', ko(options.reverse_merge(value: name, valueUpdate: :afterkeydown))
  end

  def ko_number_field_tag(name, options = {})
    number_field_tag name, '', ko(options.reverse_merge(value: name, valueUpdate: :afterkeydown))
  end

  def ko_html_field_tag(name, options = {})
    html_opts = options.delete(:html)
    text_field_tag name, '', ko(options.reverse_merge(value: name, valueUpdate: :afterkeydown)).merge(html_opts || {})
  end

  def ko_check_box_tag(name, options = {})
    check_box_tag name, '1', false, options.reverse_merge(ko checked: name)
  end

  def ko(hash = {})
    {'data-bind' => kov(hash)}
  end

  def kov(hash = {})
    hash.map do |k, v|
      if v.respond_to? :to_hash
        "#{k}:{#{kov(v)}}"
      elsif k.to_s == 'valueUpdate'
        "#{k}:'#{v}'"
      else
        "#{k}:#{v}"
      end
    end.join(',')
  end
end
