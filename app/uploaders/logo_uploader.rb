# encoding: utf-8
class LogoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  # storage :fog

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "uploads/#{model.class.to_s.underscore}/#{mounted_as}/#{model.id}"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   # For Rails 3.1+ asset pipeline compatibility:
  #   # ActionController::Base.helpers.asset_path("fallback/" + [version_name, "default.png"].compact.join('_'))
  #
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # Process files as they are uploaded:
  # process :scale => [200, 300]
  #
  # def scale(width, height)
  #   # do something
  # end

  # Create different versions of your uploaded files:
  version :grayscale do
    process :crop_from_frame => [400, 400]
    process :grayscale => [90,90]
  end

  version :croppable do
    process :resize_to_frame => [400, 400]
  end

  version :preview do
    process :grayscale => [450, 400]
  end

  # TODO: These processes might be replaced by resize_and_pad, resize_to_limit or resize_to_fill
  # See carrierwave doc http://carrierwave.rubyforge.org/rdoc/classes/CarrierWave/MiniMagick.html

  # Resizes the image to width x height and crops it based on model attributes
  def crop_from_frame(frame_width, frame_height)
    return unless model.crop_x.present?
    x = model.crop_x.to_i
    y = model.crop_y.to_i
    w = model.crop_w.to_i
    h = model.crop_h.to_i

    manipulate! do |img|
      img.combine_options do |cmd|
        resize_and_extent_west(cmd, frame_width, frame_height)
      end
      img
    end

    manipulate! do |img|
      img.crop "#{w}x#{h}+#{x}+#{y}"
      img
    end
  end

  # Resizes the image padding it west, then adds a margin of the specified color
  def resize_to_frame(width, height, total_width=nil, total_height=nil, color='#FFFFFF')
    manipulate! do |img|
      img.combine_options do |cmd|
        resize_and_extent_west(cmd, width, height, color)
        if total_width.present?
          cmd.gravity 'Center'
          cmd.extent "#{total_width || width}x#{total_height || height}"
        end
      end
      img
    end
  end

  # Resizes the image padding it west, then converts to grayscale
  def grayscale(width, height)
    manipulate! do |img|
      img.combine_options do |cmd|
        cmd.colorspace 'RGB'
        resize_and_extent_west(cmd, width, height, "#FFFFFF")
        cmd.colorspace 'gray'
      end
      img
    end
  end

  private

  def resize_and_extent_west(cmd, width, height, background="#FFFFFF")
    cmd.resize "#{width}x#{height}"
    cmd.background background
    cmd.gravity 'West'
    cmd.extent "#{width}x#{height}"
  end

end
