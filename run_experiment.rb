require "rubygems"
require "bundler/setup"
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'gruff'
require 'json'
require 'pry'

def isMac?
    (/darwin/ =~ RUBY_PLATFORM) != nil
end

def chromeLocation()
    if isMac?
        return "/Applications/Google\ Chrome\ Canary.app/Contents/MacOS/Google\ Chrome\ Canary"
    else
        return "/usr/bin/google-chrome"
    end
end

Capybara.register_driver :headless_chromium do |app|
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(
    "chromeOptions" => {
      # 'binary' => "/Users/leishman/Downloads/chrome-mac/Chromium.app/Contents/MacOS/Chromium",
      'binary' => chromeLocation(),
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

  attr_accessor :chunk_data, :constant_bitrate, :email, :passwd

  def initialize
    @email = ''
    @passwd = ''
    @throughput = []
    @bitrate = []
    @constant_bitrate = 0
    @chunk_data = []
    @py_data = []
  end

  def reapInfoFile(log)
    playing_bitrate = log.match(/^Playing bitrate \(a\/v\): \d+ \/ (\d+)/)[1]
    buffering_bitrate = log.match(/^Buffering bitrate \(a\/v\): \d+ \/ (\d+)$/)[1]
    throughput = log.match(/^Throughput: (\d+) kbps$/)[1]
    @throughput.push(throughput)
    @bitrate.push(buffering_bitrate.to_i)
    STDOUT.write"
    Playing bitrate:   #{playing_bitrate}\r
    Buffering bitrate: #{buffering_bitrate}\r
    Throughput:        #{throughput}\n\n"
  end

  def run
    puts "Setting up..."
    visit('https://www.netflix.com')
    click_link('Sign In')
    fill_in 'email', with: "#{@email}"
    fill_in 'password', with: "#{@passwd}"
    click_button 'Sign In'

    sleep_time = 2
    wait = 90
    if isMac?
        monitor = Thread.new{ `sudo python monitor.py --timeout #{sleep_time} --analyze --output data/pyAnalysis.txt`}
    end

    # save_and_open_page
    # Select user on account
    all('.avatar-wrapper').first.click

    sleep sleep_time
    # open video jawbone
    all('.slider-item-0').first.click

    # click play button to redirect to video page
    find('.jawBone .play').click
    puts "Playing..."

    find('.player-progress-loading')

    loader_displayed = "yes"

    while loader_displayed != "none"
      loader_displayed = evaluate_script("window.getComputedStyle(document.getElementById('player-playback-buffering')).display;")
    end

    # display info file
    find('body').send_keys([:control, :shift, :alt, 'l'])
    # display log file
    find('body').send_keys([:control, :shift, :alt, 'd'])

    # get appropriate log from dropdown
    find('.player-log select').find(:xpath, 'option[4]').select_option

    cur_time = Time.now.to_i

    log_debug_name = "data/log_debug_#{cur_time}.txt"
    log_debug = File.new(log_debug_name, "w")

    wait.times{|count|
        display_percentage(wait, count, 20)
        if count % 10 == 0
            begin
                info = page.evaluate_script("document.getElementsByClassName('player-info')[0].children[0].value")
                reapInfoFile(info)
            rescue Exception => e
                puts e
            end
        end
        sleep 1
    }
    puts "\nReading Netflix logs..."
    log = page.evaluate_script("document.getElementsByClassName('player-log')[0].children[0].value")

    log_debug.puts(log)
    log_debug.close

    bitrates = @bitrate.uniq
    if bitrates.length > 1
      freq = bitrates.inject(Hash.new(0)) { |h,v| h[v] += 1; h }
      @constant_bitrate = bitrates.max_by { |v| freq[v] }
      puts "More than one bitrate through trial. Ergh. Defaulting to most represented bitrate (#{@constant_bitrate})."
    else
      @constant_bitrate = bitrates[0]
    end
    if isMac?
        monitor.join
    end

    return log_debug_name
  end

  def analyze(filename, pyFile)
    puts "Analyzing data..."
    if isMac?
        @py_data = JSON.parse(IO.readlines(pyFile)[0])
    end

    File.open(filename, "r") do |fh|
      fh.each_line do |line|
        if line.include? "MediaBuffer| Received chunk, Type: video"
          d = get_chunk_data(line)
          @chunk_data << d.dup
        end
      end
    end

    create_graphs
    @chunk_data
  end

  def create_graphs
    ## create graph
    time_chunk_size = 0.1
    py_time_chunk_size = 1.0

    chunk_size_in_kbits = @constant_bitrate * 4


    chunk_buckets = Array.new(90 * (1.0 / time_chunk_size).ceil,0)

    # todo, ensure ordered by time
    request_diff_x = []
    request_diff_y = []
    t1 = chunk_buckets

    # this assumes chunk in order
    # puts chunk_data.values
    sorted_data = @chunk_data.sort { |a, b| a[:time] <=> b[:time] }

    prev_time = 0
    cur_time = time_chunk_size

    init_time = sorted_data.first[:time]
    sorted_data.each { |el| el[:time] -= init_time }

    buffer_thresh = 220
    buffer_full_time = -1

    request_diff_track = 0
    last_diff_time = 0

    sorted_data.each_with_index do |s, i|
      time = s[:time]

      if s[:vid_buffer_length] > buffer_thresh and buffer_full_time < 0
        buffer_full_time = time
      end

      # subsample by second
      round_time = time.round
      next if round_time == last_diff_time

      if i > 0
        request_diff_x << round_time
        last_diff_time = round_time
        request_diff_y << time - sorted_data[i-1][:time]
      end
    end

    chunk_buckets.each_with_index do |v, i|

      in_slice = sorted_data.select { |el| prev_time <= el[:time] and el[:time] < cur_time }
      chunk_buckets[i] = in_slice.length * chunk_size_in_kbits / time_chunk_size

      if in_slice.length > 0 and in_slice.first[:time] > (buffer_full_time + 15)
        chunk_buckets = chunk_buckets[0..i+1]
        break
      end

      prev_time = cur_time
      cur_time += time_chunk_size
    end

    if isMac?
        last_ts = (@py_data[-1]["ts"].to_f / 1000.0).ceil
        throughput_buckets = Array.new(last_ts * (1.0/py_time_chunk_size), 0)

        curr_packet = 0
        ts = @py_data[curr_packet]["ts"].to_f / 1000.0
        throughput_buckets.each_with_index do |b, i|
          curr_amount = 0
          while ts < (i + 1) * py_time_chunk_size and curr_packet < @py_data.length
              ts = @py_data[curr_packet]["ts"].to_f / 1000.0
              curr_amount += @py_data[curr_packet]["len"]/125.0
              curr_packet += 1
          end
          throughput_buckets[i] = curr_amount
        end

        labels_py = {}

        (0..110).step(10) do |n|
          k = (n * (1/py_time_chunk_size)).to_i
          labels_py[k] = n.to_s
        end
    end

    ref_line_num = (buffer_full_time / time_chunk_size).floor

    labels = {}

    (0..40).step(10) do |n|
      k = (n * (1/time_chunk_size)).to_i
      labels[k] = n.to_s
    end

    labels_py = {}

    (0..110).step(10) do |n|
      k = (n * (1/py_time_chunk_size)).to_i
      labels_py[k] = n.to_s
    end

    labels_interval = {}
    interval_ref_line_num = -1

    (0..110).step(5) do |n|
      sl = request_diff_x.select { |x| n <= x and x < n + 5 }
      if sl.first
        labels_interval[sl.first] = sl.first.to_s

        if sl.first > buffer_full_time
          interval_ref_line_num = (n / 5)
        end
      end
    end

    ## Throughput Graph (From Client)
    g = Gruff::Line.new
    title_1 = 'TCP throughput before and after buffer fills (estimated from client)'
    g.title = 'Throughput over time (client)'
    g.data title_1, chunk_buckets
    g.theme = {
      :colors => %w(red grey),
      :marker_color => 'grey',
      :font_color => 'black',
      :background_colors => 'white'
    }
    g.reference_line_default_width = 1
    g.labels = labels

    g.reference_lines[:baseline] = { :index => ref_line_num, :width => 5, color: 'green' }
    g.x_axis_label = 'Time (s)'
    g.y_axis_label = 'kb/s'
    g.write('graphs/chart_throughput.png')

    ## Request Interval Graph
    g2 = Gruff::Line.new
    title_2 = 'Request interval before and after buffer fills'
    g2.title = 'Request Interval over time'
    g2.theme = {
      :colors => %w(blue grey),
      :marker_color => 'grey',
      :font_color => 'black',
      :background_colors => 'white'
    }
    g2.dataxy title_2, request_diff_x, request_diff_y
    # g2.reference_lines[:baseline] = { :index => 5, :width => 5, color: 'green' }

    g2.labels = labels_interval
    g2.x_axis_label = 'Time (s)'
    g2.y_axis_label = 'Request Interval (s)'
    g2.write('graphs/chart_interval.png')

    if isMac?
        ## Throughput Graph (From tcpdump)
        g3 = Gruff::Line.new
        g3.title = 'Throughput over time (tcpdump)'
        title_3 = 'TCP throughput before and after buffer fills (estimated from network)'
        g3.theme = {
          :colors => %w(red grey),
          :marker_color => 'grey',
          :font_color => 'black',
          :background_colors => 'white'
        }
        g3.data title_3, throughput_buckets
        g3.labels = labels_py
        g3.x_axis_label = 'Time (s)'
        g.y_axis_label = 'kb/s'
        g3.write('graphs/chart_py.png')
    end
  end

  def get_chunk_data(str)
    arr = str.split('|')

    time = arr[0].to_f
    chunk_index = str.match(/Chunk index: (\d+),/)[1].to_i
    start_time = str.match(/StartTime: (\d+\.\d+),/)[1].to_f
    end_time = str.match(/EndTime: (\d+\.\d+),/)[1].to_f
    vid_buffer_length = str.match(/VideoBufferLength: (\d+\.\d+)/)[1].to_f

    #puts "#{time} | gcd"

    return {
      time: time,
      chunk_index: chunk_index,
      start_time: start_time,
      end_time: end_time,
      vid_buffer_length: vid_buffer_length
    }
  end

  def prep_py_file(inFile, outFile)
    prep = Thread.new{ `python monitor.py --input #{inFile} --analyze --output #{outFile}`}
    prep.join
  end
end

nr = NetflixRunner.new

# if no filename passed in as arg
filename = ''
pyFile = 'data/pyAnalysis.txt'
if ARGV[0] == "live"
  nr.email = ARGV[1]
  nr.passwd = ARGV[2]
  filename = nr.run
else
  nr.constant_bitrate = 2490
  filename = ARGV[0]
  nr.prep_py_file(ARGV[1], pyFile)
end

nr.analyze(filename, pyFile)
