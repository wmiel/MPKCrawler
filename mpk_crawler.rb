require_relative 'crawler'

# URL = 'http://rozklady.mpk.krakow.pl/aktualne/przystan.htm'.freeze
# crawler = Crawler.new(URL)
#
# visited = Set.new
# visited.add(URL)
#
# stops = crawler.same_domain_links
# stops_lines = stops.first(5).map do |stop|
#   begin
#     puts "STOP: #{stop}"
#     url = stop.href.to_s
#     stop_crawler = Crawler.new(url)
#     {stop: stop, lines: stop_crawler.same_domain_links.select { |link| visited.add?(link.href.to_s) }}
#   rescue Exception => ex
#     puts ex
#     puts stop
#     puts links
#     puts stop_crawler
#   end
# end
#
# puts '------'
# puts stops_lines

URL = 'http://rozklady.mpk.krakow.pl/linie.aspx'.freeze
crawler = Crawler.new(URL)
visited = Set.new
visited.add(URL)
lines = crawler.same_domain_links
result = lines.map do |line|
  line_crawler = Crawler.new(line.href.to_s)
  frames = line_crawler.frames
  stops = frames.map do |frame|
    stops_crawler = Crawler.new(frame.to_s)
    stops_crawler.same_domain_links.select { |link| link.text != '*' && link.target != '_parent' }
  end
  {line: line, stops: stops.flatten}
end

def cleaned_up_stop_name(stop_name)
  stop_name.gsub('NŻ', '').gsub('"', '').strip
end

def format_csv(fields)
  fields.map { |f| "\"#{f}\"" }.join(',')
end

puts result

File.open('stops_lines.csv', 'w+') do |f|
  f.puts(format_csv(%w(line_number stop_name)))

  result.each do |result|
    line = result[:line]
    stops = result[:stops]

    stops.each do |stop|
      f.puts format_csv([line.text, cleaned_up_stop_name(stop.text)])
    end
  end
end

File.open('stops_graph.csv', 'w+') do |f|
  f.puts(format_csv(%w(source target)))
  result.each do |result|
    stops = result[:stops]
    prev_stop = nil

    stops.each do |stop|
      stop = cleaned_up_stop_name(stop.text)
      f.puts(format_csv([prev_stop, stop])) if prev_stop
      prev_stop = stop
    end
    f.puts ''
  end
end

current_id = 0
stop_ids = {}

File.open('stops_graph_ids.csv', 'w+') do |f|
  f.puts(format_csv(%w(source target)))

  result.each do |result|
    stops = result[:stops]
    prev_stop = nil

    stops.each do |stop|
      stop = cleaned_up_stop_name(stop.text)
      stop_id = stop_ids[stop] || (stop_ids[stop] = (current_id += 1))
      f.puts(format_csv([prev_stop, stop_id])) if prev_stop
      prev_stop = stop_id
    end
    f.puts ''
  end
end


File.open('stops_ids.csv', 'w+') do |f|
  f.puts(format_csv(%w(id label)))
  stop_ids.each do |stop, id|
    f.puts(format_csv([id, stop]))
  end
end
