# if needed update chromedriver from here: https://chromedriver.chromium.org/downloads
# move chromedriver binary into /usr/local/bin or where you need it

require "selenium-webdriver"

driver = Selenium::WebDriver.for :chrome
driver.navigate.to "http://www.google.com"
element = driver.find_element(:name, 'q')
element.send_keys "Hello Selenium WebDriver!"
element.submit
puts driver.title
