class Xform
  FORMAT = {
    :model    => "<field-%1$d><field-id>%1$d</field-id><value /></field-%1$d>",
    :binding  => "<bind nodeset=\"/resource/existing-fields/field-%s/value\" />",
    :ui       => "<input ref=\"/resource/existing-fields/field-%1$d/value\"><label>%2$s</label></input>"
  }
  
  attr_reader :template
  
  def initialize(template = nil)
    @template = template
  end
  
  def render_form(collection)
    fields = collection.fields
    @template.gsub(
      "%(:title)", collection.name).gsub(
      "%(:collection_id)", collection.id.to_s).gsub(
      "%(:existing_fields)", render_model(fields)).gsub(
      "%(:existing_fields_binding)", render_binding(fields)).gsub(
      "%(:existing_fields_ui)", render_ui(fields)) unless @template.nil?
  end
  
  def render_model(fields)
    render(fields, :model) do |field, format|
       sprintf(format, field.id)
    end
  end
  
  def render_binding(fields)
    render(fields, :binding) do |field, format|
      sprintf(format, field.id)
    end 
  end
  
  def render_ui(fields)
    render(fields, :ui) do |field, format|
      sprintf(format, field.id, field.name)
    end
  end
  
  private
  def render(fields, format, &block)
    content = ""
    if block_given?
      fields.each do |field|
        content << yield(field, FORMAT[format])
      end
    end
    content
  end

end
