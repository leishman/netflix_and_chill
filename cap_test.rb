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

def display_percentage(total, current, width)
    curr = (current/total.to_f * 100).round(1)
    decile = (curr/(100/width)).to_i
    STDOUT.write "\r"
    decile.times{STDOUT.write "#"}
    (width - decile).times{STDOUT.write " "}
    STDOUT.write "#{curr}% (#{current} of #{total})";
end

class NetflixRunner
  include Capybara::DSL

  def init
  end

  def run
    visit('https://www.netflix.com')
    # page.save_screenshot('screenshot.png')

    # page.save_screenshot('first_page.png', fromSurface: true)
    # save_and_open_screenshot
    click_link('Sign In')
    fill_in 'email', with: 'leishman3@gmail.com'
    fill_in 'password', with: 'cs244rocks'
    click_button 'Sign In'

    # save_and_open_page

    # Select user on account
    all('.avatar-wrapper').first.click

    sleep 2
    # open video jawbone
    all('.slider-item-0').first.click
    # page.save_screenshot('screenshot_test.png')

    # click play button to redirect to video page
    find('.jawBone .play').click

    find('.player-progress-loading')


    loader_displayed = "yes"

    while loader_displayed != "none"
      loader_displayed = evaluate_script("window.getComputedStyle(document.getElementById('player-playback-buffering')).display;")
    end

    find('body').send_keys([:control, :shift, :alt, 'l'])

    find('.player-log select').find(:xpath, 'option[4]').select_option

    # sleep 60
    cur_time = Time.now.to_i
    log_debug = File.new("log_debug_#{cur_time}.txt", "w")

    wait = 90
    wait.times{|count|
        display_percentage(wait, count, 20)
        sleep 1
    }

    res = page.evaluate_script("document.getElementsByClassName('player-log')[0].children[0].value")

    log_debug.puts(res)
    log_debug.close

    return res
  end
end

nr = NetflixRunner.new
results = nr.run

puts results

# log_parsed = File.new("log_parsed_#{cur_time}.txt", "w")

# result_array = []

# 90.times do
#   sleep 0.5
#   res = page.evaluate_script("document.getElementsByClassName('player-log')[0].children[0].value")
#   pos = res.match(/^Position: (\d+\.\d+)$/)[1]
#   buf_size_bytes = res.match(/^Buffer size in Bytes \(a\/v\): \d+ \/ (\d+)$/)[1]
#   buf_size_secs = res.match(/^Buffer size in Seconds \(a\/v\): \d+\.\d+ \/ (\d+\.\d+)$/)[1]
#   throughput = res.match(/^Throughput: (\d+) kbps$/)[1]

#   delim = "------------------"
#   log_full.puts(res)
#   log_full.puts(delim)

#   log_parsed.puts("Position: #{pos}")
#   log_parsed.puts("Buffer Size (Bytes): #{buf_size_bytes}")
#   log_parsed.puts("Buffer Size (secs): #{buf_size_secs}")
#   log_parsed.puts("Throughput: #{throughput}")
#   log_parsed.puts(delim)

#   puts pos

#   res_obj = {
#               position: pos,
#               buf_size_bytes: buf_size_bytes,
#               buf_size_secs: buf_size_secs,
#               throughput: throughput
#             }
#   result_array << res_obj
# end

# log_full.close
# log_parsed.close




