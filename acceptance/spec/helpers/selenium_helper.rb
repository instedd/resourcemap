require 'nokogiri'

module SeleniumHelper
  def get(path)
    if path =~ %r(://)
      @driver.get path
    else
      @driver.get "http://resmap-stg.instedd.org/#{path}"
    end
  end

  def unique(name)
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    if name =~ /(.*)@(.*)/
      "#{$1}+#{timestamp}@#{$2}"
    else
      "#{name}#{timestamp}"
    end
  end

  def i_should_see(text)
    unless dom_text.include? text
      sleep 2
      unless dom_text.include? text
        ::RSpec::Expectations.fail_with("Expected to see '#{text}' but couldn't find it on the web page")
      end
    end
  end

  def i_should_not_see(text)
    if dom_text.include? text
      sleep 2
      if dom_text.include? text
        ::RSpec::Expectations.fail_with("Expected not to see '#{text}' but it was found on the web page")
      end
    end
  end

  def get_link(string)
    string =~ /href=(?:"|')(.*?)(?:"|')/ && $1 or raise ::RSpec::Expectations.fail_with("Link not found in #{string}")
  end

  def dom_text
    html = @driver.execute_script('return document.body.innerHTML;')
    doc = Nokogiri::HTML html
    doc.xpath('//script').each &:remove
    doc.inner_text
  end
end
