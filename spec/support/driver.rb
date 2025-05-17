browser_options = Selenium::WebDriver::Chrome::Options.new
browser_options.add_argument('--window-size=1920,1080')

webdriver_options = {
  browser: :chrome,
  options: browser_options
}

unless ENV['SHOW_TEST_BROWSER'].present?
  browser_options.add_argument('--headless')
end

if ENV['TEST_SERVER_PORT'].present?
  Capybara.server_host = '0.0.0.0'
  Capybara.server_port = ENV['TEST_SERVER_PORT']
  webdriver_options[:url] = "http://#{ENV['HOST_MACHINE_IP']}:9515"
end

Capybara.register_driver :selenium_chrome_headless do |app|
  Capybara::Selenium::Driver.new(app, **webdriver_options)
end

Capybara.javascript_driver = :selenium_chrome_headless

RSpec.configure do |config|
  config.before(:each, type: :system) do
    driven_by ENV['SHOW_BROWSER'] ? :selenium_chrome : :selenium_chrome_headless
  end
end
