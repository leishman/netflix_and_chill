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
      'args' => %w{no-sandbox disable-gpu hide-scrollbars} # add 'headless' in here to run headless, but there are still issues
    }
  )
  driver = Capybara::Selenium::Driver.new(
    app,
    browser: :chrome,
    desired_capabilities: caps
  )
end

Capybara.default_max_wait_time = 10

Capybara.default_driver = :headless_chromium
# Capybara.default_driver = :selenium

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

    sleep 2
    # open video jawbone
    all('.slider-item-0').first.click
    page.save_screenshot('screenshot_test.png')

    # click play button to redirect to video page
    find('.jawBone .play').click
    sleep 5

    find('body').send_keys([:control, :shift, :alt, 'd'])

    # sleep 60

    180.times do
      sleep 0.5
      res = page.evaluate_script("document.getElementsByClassName('player-info')[0].children[0].value")
      pos = res.match(/^Position: (\d+\.\d+)$/)[1]
      buf_size_bytes = res.match(/^Buffer size in Bytes \(a\/v\): \d+ \/ (\d+)$/)[1]
      buf_size_secs = res.match(/^Buffer size in Seconds \(a\/v\): \d+\.\d+ \/ (\d+\.\d+)$/)[1]
      throughput = res.match(/^Throughput: (\d+) kbps$/)[1]
      puts "Position: #{pos}"
      puts "Buffer Size (Bytes): #{buf_size_bytes}"
      puts "Buffer Size (secs): #{buf_size_secs}"
      puts "Throughput: #{throughput}"
      puts "\n\n---------------\n\n"
    end
  end
end

nr = NetflixRunner.new
nr.run



