require "rubygems"
require "bundler/setup"
require 'capybara'
require 'capybara/dsl'
require 'selenium-webdriver'
require 'gruff'
require 'json'
require 'pry'

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

<<<<<<< HEAD
<<<<<<< HEAD
<<<<<<< HEAD
  attr_accessor :chunk_data
=======
  attr_accessor :chunk_data, :constant_bitrate
>>>>>>> f287ab0... add time slice bucketing logic

  def initialize
    @chunk_data = {}
  end

  def parseDFile

  end

  def get_chunk_data(str)
    arr = str.split('|')

    time = arr[0].to_f
    chunk_index = str.match(/Chunk index: (\d+),/)[1].to_i
    start_time = str.match(/StartTime: (\d+\.\d+),/)[1].to_f
    end_time = str.match(/EndTime: (\d+\.\d+),/)[1].to_f
    vid_buffer_length = str.match(/VideoBufferLength: (\d+\.\d+)/)[1].to_f

    return {
      time: time,
      chunk_index: chunk_index,
      start_time: start_time,
      end_time: end_time,
      vid_buffer_length: vid_buffer_length
    }
=======
  def initialize
=======
  attr_accessor :chunk_data, :constant_bitrate, :email, :passwd

  def initialize
    @email = ''
    @passwd = ''
>>>>>>> 45a1150... pushing anew
    @throughput = []
    @bitrate = []
<<<<<<< HEAD
=======
    @constant_bitrate = 0
    @chunk_data = {}
    @py_data = []
>>>>>>> 8a5e67e... throughput measure
  end

  def reapInfoFile(log)
    playing_bitrate = log.match(/^Playing bitrate \(a\/v\): \d+ \/ (\d+)/)[1]
    buffering_bitrate = log.match(/^Buffering bitrate \(a\/v\): \d+ \/ (\d+)$/)[1]
    throughput = log.match(/^Throughput: (\d+) kbps$/)[1]
    @throughput.push(throughput)
    @bitrate.push(buffering_bitrate)
    STDOUT.write"
    Playing bitrate:   #{playing_bitrate}\r
    Buffering bitrate: #{buffering_bitrate}\r
<<<<<<< HEAD
    Throughput:        #{throughput}\r"
>>>>>>> 9fd30ea... adding bugs. rename as pngs to see. may have display issues
=======
    Throughput:        #{throughput}\n\n"
>>>>>>> 003e303... new account
  end

  def run
    puts "Setting up..."
    visit('https://www.netflix.com')
    click_link('Sign In')
    fill_in 'email', with: "#{@email}"
    fill_in 'password', with: "#{@passwd}"
    click_button 'Sign In'
<<<<<<< HEAD
<<<<<<< HEAD
=======
    puts "Playing..."
>>>>>>> 9fd30ea... adding bugs. rename as pngs to see. may have display issues
=======

>>>>>>> 45a1150... pushing anew
    # save_and_open_page
    # Select user on account
    all('.avatar-wrapper').first.click

    sleep 2
    # open video jawbone
    all('.slider-item-0').first.click

<<<<<<< HEAD
    wait = 10
    # monitor = Thread.new{ `python monitor.py --timeout #{wait + 10} --analyze`}
=======
    wait = 90
<<<<<<< HEAD
    # monitor = Thread.new{ `python monitor.py --timeout #{wait + 10} --analyze --output pyAnalysis.txt`}
>>>>>>> 8a5e67e... throughput measure
    # click play button to redirect to video page
    find('.jawBone .play').click
    sleep 2
=======
    monitor = Thread.new{ `python monitor.py --timeout #{wait + 10} --analyze --output data/pyAnalysis.txt`}
    # click play button to redirect to video page
    find('.jawBone .play').click
    puts "Playing..."
>>>>>>> 45a1150... pushing anew

    find('.player-progress-loading')

    loader_displayed = "yes"

    while loader_displayed != "none"
      loader_displayed = evaluate_script("window.getComputedStyle(document.getElementById('player-playback-buffering')).display;")
    end

    # display info file
    find('body').send_keys([:control, :shift, :alt, 'l'])
<<<<<<< HEAD

=======
    # display log file
    find('body').send_keys([:control, :shift, :alt, 'd'])
>>>>>>> 9fd30ea... adding bugs. rename as pngs to see. may have display issues
    # get appropriate log from dropdown
    find('.player-log select').find(:xpath, 'option[4]').select_option

    cur_time = Time.now.to_i
<<<<<<< HEAD

    log_debug_name = "data/log_debug_#{cur_time}.txt"
    log_debug = File.new(log_debug_name, "w")
=======
    log_debug = File.new("info_debug_#{cur_time}.txt", "w")
>>>>>>> 9fd30ea... adding bugs. rename as pngs to see. may have display issues

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


    log = page.evaluate_script("document.getElementsByClassName('player-log')[0].children[0].value")

    log_debug.puts(log)
    log_debug.close

<<<<<<< HEAD
    @chunk_data = {}
=======
    bitrates = @bitrate.uniq
    if bitrates.length > 1
      puts "More than one bitrate through trial. Ergh."
      return
    else
      @constant_bitrate = bitrates[0]
    end
    monitor.join

    return log_debug_name
  end

  def analyze(filename, pyFile)
    @py_data = JSON.parse(IO.readlines(pyFile)[0])
>>>>>>> 8a5e67e... throughput measure

    File.open(log_debug_name, "r") do |fh|
      fh.each_line do |line|
        if line.include? "Received chunk" and line.include? "Type: video"
          d = get_chunk_data(line)
          @chunk_data[d[:chunk_index]] = d.dup
        end
      end
    end
<<<<<<< HEAD
<<<<<<< HEAD
    # monitor.join

<<<<<<< HEAD
=======
    bitrates = @bitrate.uniq
    if bitrates.length > 1
        puts "More than one bitrate through trial. Ergh."
    else
        constant_bitrate = bitrates[0]
    end

>>>>>>> 9fd30ea... adding bugs. rename as pngs to see. may have display issues
    return log
=======
=======

>>>>>>> 8a5e67e... throughput measure
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
    request_diff = [0]
    t1 = chunk_buckets

    # this assumes chunk in order
    # puts chunk_data.values
    sorted_data = @chunk_data.values.sort { |a, b| a[:time] <=> b[:time] }

    prev_time = 0
    cur_time = time_chunk_size

    chunk_buckets.each_with_index do |v, i|
      in_slice = sorted_data.select { |el| prev_time <= el[:time] and el[:time] < cur_time }
      # puts in_slice
      chunk_buckets[i] = in_slice.length * chunk_size_in_kbits / time_chunk_size

      prev_time = cur_time
      cur_time += time_chunk_size
    end

    buffer_thresh = 220
    buffer_full_time = -1

    sorted_data.each_with_index do |s, i|
      time = s[:time]
      if s[:vid_buffer_length] > buffer_thresh and buffer_full_time < 0
        buffer_full_time = time
      end
      # chunk_buckets[time.floor] += 1
      if i > 0
        request_diff << time - sorted_data[i-1][:time]
      end
    end

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

    labels = {}

    (0..110).step(10) do |n|
      k = (n * (1/time_chunk_size)).to_i
      labels[k] = n.to_s
    end

    g = Gruff::Line.new
    g.title = 'Packet Count 1s buckets'
    g.data :series, chunk_buckets
    g.theme = {
      :colors => %w(red grey),
      :marker_color => 'grey',
      :font_color => 'black',
      :background_colors => 'white'
    }
    g.reference_line_default_width = 1
    g.labels = labels
    # g.show_vertical_markers = true
    puts buffer_full_time
    ref_line_num = (buffer_full_time / time_chunk_size).floor
    puts ref_line_num

    g.reference_lines[:baseline]  = { :index => ref_line_num, :width => 5, color: 'blue' }


    # g.draw_vertical_reference_line({index: 40})
    g.write('chart_throughput.png')

    g2 = Gruff::Line.new
    g2.title = 'Request Interval'
    g2.data :series, request_diff
    g2.write('chart_interval.png')

    g3 = Gruff::Line.new
    g3.title = 'Throughput'
    g3.data :series, throughput_buckets
    g3.write('chart_py.png')
  end

  def get_chunk_data(str)
    arr = str.split('|')

    time = arr[0].to_f
    chunk_index = str.match(/Chunk index: (\d+),/)[1].to_i
    start_time = str.match(/StartTime: (\d+\.\d+),/)[1].to_f
    end_time = str.match(/EndTime: (\d+\.\d+),/)[1].to_f
    vid_buffer_length = str.match(/VideoBufferLength: (\d+\.\d+)/)[1].to_f

    return {
      time: time,
      chunk_index: chunk_index,
      start_time: start_time,
      end_time: end_time,
      vid_buffer_length: vid_buffer_length
    }
>>>>>>> e066f46... create request interval chart too
  end

  def prep_py_file(inFile, outFile)
    prep = Thread.new{ `python monitor.py --input #{inFile} --analyze --output #{outFile}`}
    prep.join
  end
end

nr = NetflixRunner.new
results = nr.run

chunk_buckets = Array.new(20, 0)

<<<<<<< HEAD
nr.chunk_data.each do |k, v|
  chunk_buckets[v[:time].floor] += 1
=======
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
<<<<<<< HEAD
>>>>>>> e066f46... create request interval chart too
end


g = Gruff::Line.new
g.title = 'Packet Count 1s buckets'
g.data :series, chunk_buckets
g.write('chart.png')

=======
  nr.prep_py_file(ARGV[1], pyFile)
end

nr.analyze(filename, pyFile)
>>>>>>> 8a5e67e... throughput measure
