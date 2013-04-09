module Site::UuidConcern
  extend ActiveSupport::Concern

  included do
  	validates :uuid, :presence => true, :unchangeable => true
  	validate :validate_uuid_format

 		before_validation :set_uuid, :on => :create
	end

 	def validate_uuid_format
 		begin
 			uuid = UUIDTools::UUID.parse self.uuid
 		rescue
 			errors.add(:uuid, "is not valid") 
 		end
 		errors.add(:uuid, "is not valid") if uuid && !uuid.valid?
 	end

 	def set_uuid
 		if !self.uuid
 			self.uuid = UUIDTools::UUID.random_create.to_s
 		end
 	end
end

class UnchangeableValidator < ActiveModel::EachValidator
  def validate_each(object, attribute, value)
    if !object.new_record? && value.present?
      original = object.class.send(:where, "id = #{object.id}").select("id, #{attribute.to_s}").first
      if original.send(attribute) != value
        object.errors[attribute] << (options[:message] || "cannot be changed once assigned")
      end
    end
  end
end
