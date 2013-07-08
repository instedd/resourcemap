# encoding: UTF-8

require 'spec_helper'

describe CSV do
  it "Open CSV encoded in utf-8" do
    with_tmp_file('utf8.csv') do |tmp_file|
      CSV.open(tmp_file, "wb", encoding: "utf-8") do |csv|
        csv << ["é", "ñ", "ç", "ø"]
      end

      CSV.read(tmp_file).should eq([["é", "ñ", "ç", "ø"]])
    end
  end

  it "Open CSV encoded in latin1" do
    with_tmp_file('latin1.csv') do |tmp_file|
      CSV.open(tmp_file, "wb", encoding: "ISO-8859-1") do |csv|
        csv << ["é", "ñ", "ç", "ø"]
      end

      CSV.read(tmp_file).should eq([["é", "ñ", "ç", "ø"]])
    end
  end
end
