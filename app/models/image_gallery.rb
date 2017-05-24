class ImageGallery < ActiveRecord::Base
  belongs_to :site
  belongs_to :field
  mount_uploaders :images, ImageGalleryUploader
end
