module Site::TemplateConcerns
  extend ActiveSupport::Concern

  def get_template_value_hash
    template_value = human_properties
    template_value["site name"] = self.name
    template_value
  end
end