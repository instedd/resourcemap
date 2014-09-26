require 'spec_helper'

describe SearchParser, :type => :model do
  it "nil" do
    s = SearchParser.new(nil)
    assert_equal nil, s.search
  end

  it "simple 1" do
    s = SearchParser.new('search')
    expect(s.search).to eq('search')
  end

  it "simple 2" do
    s = SearchParser.new('hello world')
    expect(s.search).to eq('hello world')
  end

  it "key value" do
    s = SearchParser.new('key:value')
    expect(s.search).to be_nil
    expect(s['key']).to eq('value')
  end

  it "key value with words" do
    s = SearchParser.new('one key:value other:thing two')
    expect(s.search).to eq('one two')
    expect(s['key']).to eq('value')
    expect(s['other']).to eq('thing')
  end

  it "key value with quotes" do
    s = SearchParser.new('key:"more than one word"')
    expect(s.search).to be_nil
    expect(s['key']).to eq('more than one word')
  end

  it "key value with quotes twice" do
    s = SearchParser.new('key:"more than one word" key2:"something else"')
    expect(s.search).to be_nil
    expect(s['key']).to eq('more than one word')
    expect(s['key2']).to eq('something else')
  end

  it "key value with quotes and symbols" do
    s = SearchParser.new('key:"more than : one word"')
    expect(s.search).to be_nil
    expect(s['key']).to eq('more than : one word')
  end

  it "key value with colon" do
    s = SearchParser.new('key:something:else')
    expect(s.search).to be_nil
    expect(s['key']).to eq('something:else')
  end

  it "key value with protocol" do
    s = SearchParser.new('key:value://hola')
    expect(s.search).to be_nil
    expect(s['key']).to eq('value://hola')
  end

  it "quotes" do
    s = SearchParser.new('"more than one word"')
    expect(s.search).to eq('"more than one word"')
  end

  it "semicolon" do
    s = SearchParser.new(';')
    expect(s.search).to eq(';')
  end

  it "parses location coordinate without hyphen" do
    s = SearchParser.new('32.123')
    expect(s.search).to eq('32.123')
  end

  it "parses location coordinate with hyphen" do
    s = SearchParser.new('-32.123')
    expect(s.search).to eq('32.123')
  end

  it "parses word hyphen word" do
    s = SearchParser.new('my-site')
    expect(s.search).to eq('my - site')
  end

  it "parses word dot number" do
    s = SearchParser.new('MySite.32')
    expect(s.search).to eq('MySite . 32')
  end

  it "parses number dot word" do
    s = SearchParser.new('32.MySite')
    expect(s.search).to eq('32 . MySite')
  end

  it "parses decimal number space word" do
    s = SearchParser.new('32.3 foo')
    expect(s.search).to eq('32.3 foo')
  end
end
