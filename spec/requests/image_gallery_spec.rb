require 'spec_helper'

describe "Image Gallery" do
  it "uploads multiple logos" do
    file = File.open('spec/fixtures/tracking_food.jpg')
    file2 = File.open('spec/fixtures/tracking_food.jpg')
    instance = ImageGallery.new
    instance.images = [file, file2]
    instance.save!
    instance.images.count.should eq(2)
    instance.images.each do |image|
      get image.url
      response.should be_success
    end
  end

end
