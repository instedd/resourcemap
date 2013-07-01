# encoding: UTF-8

require 'spec_helper'

describe CSV do
  it "Open CSV encoded in utf-8" do
    CSV.open("utf8.csv", "wb", encoding: "utf-8") do |csv|
      csv << ["é", "ñ", "ç", "ø"]
    end

    CSV.read("utf8.csv").should eq([["é", "ñ", "ç", "ø"]])

    File.delete("utf8.csv")
  end

  it "Open CSV encoded in latin1" do
    CSV.open("latin1.csv", "wb", encoding: "ISO-8859-1") do |csv|
      csv << ["é", "ñ", "ç", "ø"]
    end

    CSV.read("latin1.csv").should eq([["é", "ñ", "ç", "ø"]])  
    File.delete("latin1.csv")
  end
end
