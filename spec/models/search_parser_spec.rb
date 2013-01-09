require 'spec_helper'

describe SearchParser do
  it "nil" do
    s = SearchParser.new(nil)
    assert_equal nil, s.search
  end

  it "simple 1" do
    s = SearchParser.new('search')
    s.search.should eq('search')
  end

  it "simple 2" do
    s = SearchParser.new('hello world')
    s.search.should eq('hello world')
  end

  it "key value" do
    s = SearchParser.new('key:value')
    s.search.should be_nil
    s['key'].should eq('value')
  end

  it "key value with words" do
    s = SearchParser.new('one key:value other:thing two')
    s.search.should eq('one two')
    s['key'].should eq('value')
    s['other'].should eq('thing')
  end

  it "key value with quotes" do
    s = SearchParser.new('key:"more than one word"')
    s.search.should be_nil
    s['key'].should eq('more than one word')
  end

  it "key value with quotes twice" do
    s = SearchParser.new('key:"more than one word" key2:"something else"')
    s.search.should be_nil
    s['key'].should eq('more than one word')
    s['key2'].should eq('something else')
  end

  it "key value with quotes and symbols" do
    s = SearchParser.new('key:"more than : one word"')
    s.search.should be_nil
    s['key'].should eq('more than : one word')
  end

  it "key value with colon" do
    s = SearchParser.new('key:something:else')
    s.search.should be_nil
    s['key'].should eq('something:else')
  end

  it "key value with protocol" do
    s = SearchParser.new('key:value://hola')
    s.search.should be_nil
    s['key'].should eq('value://hola')
  end

  it "quotes" do
    s = SearchParser.new('"more than one word"')
    s.search.should eq('"more than one word"')
  end

  it "semicolon" do
    s = SearchParser.new(';')
    s.search.should eq(';')
  end

  it "parses location coordinates" do
    s = SearchParser.new('-32.123')
    s.search.should eq('-32.123')
  end

  it "parses word hyphen word" do
    s = SearchParser.new('my-site')
    s.search.should eq('my - site')
  end

  it "parses word dot number" do
    s = SearchParser.new('MySite.32')
    s.search.should eq('MySite . 32')
  end

  it "parses number dot word" do
    s = SearchParser.new('32.MySite')
    s.search.should eq('32 . MySite')
  end

  it "parses decimal number space word" do
    s = SearchParser.new('32.3 foo')
    s.search.should eq('32.3 foo')
  end
end
