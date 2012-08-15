require 'spec_helper'

describe HashParser do
  before(:each) do
    @xml = StringIO.new("<site><lat>12.1</lat><lng>11.1</lng></site>")
    @incorrect_xml = StringIO.new("<site><lat>12.1</lat><lng>11.1</lng>")
  end

  it "should raise exception 'missing xml file'" do
    expect { HashParser.from_xml_file(nil)}.to raise_error("missing xml file")
  end

  it "should raise exception 'invalid xml format'" do
    expect { HashParser.from_xml_file(@incorrect_xml)}.to raise_error("invalid xml format")
  end

  it "should convert xml to hash object" do
    result = HashParser.from_xml_file @xml
    result.should be_a_kind_of(Hash)
  end
end
