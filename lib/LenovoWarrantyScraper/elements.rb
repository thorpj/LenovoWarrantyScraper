class Element
  attr_reader :value
  def initialize(value, key: :id, wait: 0)
    @value = value
    sleep(wait) if wait > 0
    if key == :id
      @element = DotBot.driver.find_element(id: value)
    elsif key == :xpath
      @element = DotBot.driver.find_element(xpath: value)
    else
      @element = DotBot.driver.find_element(name: value)
    end

    # DotBot.elements[value] = @element unless DotBot.elements.include? @element
  end

  def click
    @element.click
  end

  def send_keys(text)
    @element.send_keys(text)
  end
end

class Checkbox < Element
  def check
    @element.click if @element.attribute('checked').nil?
  end

  def uncheck
    @element.click if @element.attribute('checked').present?
  end
end

class Radiobox < Element
end

class Listbox < Element
  def select(term)
    options = @element.find_elements(tag_name: 'option')
    options.each do |option|
      option.click if option.text == term
    end
  end
end