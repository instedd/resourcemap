class String
  # Does this string represent an integer?
  def integer?
    Integer(self) rescue nil
  end

  def real?
    Float(self) rescue nil
  end

  def render_template_string(option_hash)
    self.gsub(/\[[\w\s]+\]/) do |template|
      option_hash.each do |key, value|
        if template == '['+ key+ ']'
          if key == "Site Name" 
            template = value
          else
            template = key
          end
          break
        end
      end
      template
    end
  end

end
