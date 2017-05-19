require "rubygems"
require "bundler/setup"
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'




Capybara.register_driver :headless_chromium do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    "chromeOptions" => {
      # 'binary' => "/Users/leishman/Downloads/chrome-mac/Chromium.app/Contents/MacOS/Chromium",
      'binary' => "/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary",
      'args' => %w{headless no-sandbox disable-gpu hide-scrollbars}
    }
  )
  driver = Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: caps
  )
end

Capybara.default_max_wait_time = 10

# Capybara.default_driver = :headless_chromium
Capybara.default_driver = :selenium

class NetflixRunner
  include Capybara::DSL

  def init
  end

  def run
    visit('https://www.netflix.com')
    # page.save_screenshot('screenshot.png')

    page.save_screenshot('first_page.png', fromSurface: true)
    save_and_open_screenshot
    click_link('Sign In')
    fill_in 'email', with: 'leishman3@gmail.com'
    fill_in 'password', with: 'cs244rocks'
    click_button 'Sign In'

    save_and_open_page

    # Select user on account
    all('.avatar-wrapper').first.click

    # open video jawbone
    all('.slider-item-0').first.click
    page.save_screenshot('screenshot_time')

    # click play button to redirect to video page
    find('.jawBone .play').click

  end
end

nr = NetflixRunner.new
nr.run



