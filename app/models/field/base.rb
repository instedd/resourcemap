module Field::Base
  extend ActiveSupport::Concern

  BaseKinds = [
   { name: 'text', css_class: 'ltext', small_css_class: 'stext' },
   { name: 'numeric', css_class: 'lnumber', small_css_class: 'snumeric' },
   { name: 'yes_no', css_class: 'lyesno', small_css_class: 'syes_no' },
   { name: 'select_one', css_class: 'lsingleoption', small_css_class: 'sselect_one' },
   { name: 'select_many', css_class: 'lmultipleoptions', small_css_class: 'sselect_many' },
   { name: 'hierarchy', css_class: 'lhierarchy', small_css_class: 'shierarchy' },
   { name: 'date', css_class: 'ldate', small_css_class: 'sdate' },
   { name: 'site', css_class: 'lsite', small_css_class: 'ssite' },
   { name: 'user', css_class: 'luser', small_css_class: 'suser' }]

  BaseKinds.each do |base_kind|
    class_eval %Q(def #{base_kind[:name]}?; kind == '#{base_kind[:name]}'; end)
  end

  module ClassMethods
    def plugin_kinds
       Plugin.hooks(:field_type).index_by { |h| h[:name] }
    end

    def kinds
      (BaseKinds.map{|k| k[:name]} | plugin_kinds.keys).sort.freeze
    end
  end

  def select_kind?
    false
  end

  def plugin?
    self.class.plugin_kinds.has_key? kind
  end

  def stored_as_date?
    date?
  end

  def stored_as_number?
    numeric? || select_one? || select_many?
  end

  def strongly_type(value)
    if stored_as_number?
      value.is_a?(Array) ? value.map(&:to_i_or_f) : value.to_s.to_i_or_f
    else
      value
    end
  end

  def api_value(value)
    value
  end

  def human_value(value)
    value
  end

  def sample_value(user = nil)
    if plugin?
      kind_config = self.class.plugin_kinds()[kind]
      if kind_config.has_key? :sample_value
        return kind_config[:sample_value]
      else
        return ''
      end
    end

    if text?
      value = 'sample text value'
    elsif numeric?
      value = 39
    elsif date?
      value = Field::DateField.new.decode('4/23/1851')
    elsif user?
      return '' if user.nil?
      value = user.email
    elsif select_one?
      options = config['options']
      return '' if options.nil? or options.length == 0
      value = config['options'][0]['id']
    elsif select_many?
      options = config['options']
      return '' if options.nil? or options.length == 0
      if options.length == 1
        value = [options[0]['id']]
      else
        value = [options[0]['id'], options[1]['id']]
      end
    elsif hierarchy?
      options = config['hierarchy']
      return '' if options.nil? or options.length == 0
      value = options.first['id']
    else
      return ''
    end
    api_value value
  end
end
