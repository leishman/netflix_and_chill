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

  attr_accessor :chunk_data, :constant_bitrate, :email, :passwd

  def initialize
    @email = ''
    @passwd = ''
    @throughput = []
    @bitrate = []
    @constant_bitrate = 0
    @chunk_data = {}
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

    # save_and_open_page
    # Select user on account
    all('.avatar-wrapper').first.click

    sleep 2
    # open video jawbone
    all('.slider-item-0').first.click

    wait = 90
    monitor = Thread.new{ `python monitor.py --timeout #{wait + 10} --analyze --output data/pyAnalysis.txt`}
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

    log = page.evaluate_script("document.getElementsByClassName('player-log')[0].children[0].value")

    log_debug.puts(log)
    log_debug.close

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

    File.open(filename, "r") do |fh|
      fh.each_line do |line|
        if line.include? "Received chunk" and line.include? "Type: video"
          d = get_chunk_data(line)
          @chunk_data[d[:chunk_index]] = d.dup
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

      if i > 0
        request_diff_x << time
        request_diff_y << time - sorted_data[i-1][:time]
      end
    end

    # request_diff_final = Array.new(90)

    # request_diff.each do |rd|
    #   request_diff_final[rd[:time].floor] = rd[:diff]
    # end

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

    labels_py = {}

    (0..110).step(10) do |n|
      k = (n * (1/py_time_chunk_size)).to_i
      labels_py[k] = n.to_s
    end



    ## Throughput Graph (From Client)
    g = Gruff::Line.new
    title_1 = 'TCP throughput before and after buffer fills (estimated from client)'
    g.title = 'Throughput vs. Time (client)'
    g.data title_1, chunk_buckets
    g.theme = {
      :colors => %w(red grey),
      :marker_color => 'grey',
      :font_color => 'black',
      :background_colors => 'white'
    }
    g.reference_line_default_width = 1
    g.labels = labels

    ref_line_num = (buffer_full_time / time_chunk_size).floor
    g.reference_lines[:baseline]  = { :index => ref_line_num, :width => 5, color: 'blue' }
    g.x_axis_label = 'Time (s)'
    g.y_axis_label = 'kb/s'
    g.write('chart_throughput.png')

    ## Request Interval Graph
    g2 = Gruff::Line.new
    title_2 = 'Request interval before and after buffer fills'
    g2.title = 'Request Interval vs. Time'
    g2.theme = {
      :colors => %w(blue grey),
      :marker_color => 'grey',
      :font_color => 'black',
      :background_colors => 'white'
    }
    g2.dataxy title_2, request_diff_x, request_diff_y
    # g2.labels = request_diff_x
    g2.x_axis_label = 'Time (s)'
    g.y_axis_label = 'Request Interval (s)'
    g2.write('chart_interval.png')

    ## Throughput Graph (From tcpdump)
    g3 = Gruff::Line.new
    g3.title = 'Throughput vs. Time (tcpdump)'
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
