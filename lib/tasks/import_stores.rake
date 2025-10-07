namespace :import do
  desc "Import stores from udon_list.json"
  task stores: :environment do
    require "json"

    FILENAME = "udon_list.json"
    FILE = Rails.root.join(FILENAME)
    unless File.exist?(FILE)
      puts "#{FILENAME} not found at #{FILE}"
      next
    end

    json = JSON.parse(File.read(FILE))
    total = json.size
    created = 0
    skipped = 0

    # Helper: parse openTime text into a structured JSON object.
    # This is a best-effort parser for strings like:
    # "月～金: 11:00～15:00 16:30～22:30 土、日: 11:00～22:30"
    def parse_open_time(text)
      return nil if text.nil?

      result = {}
      # Normalize full-width tildes and spaces
      s = text.tr("〜–—", "~").gsub(/[　]/, " ")

      # Split by Japanese separators that likely denote day groups
      parts = s.split(/(?<=\S)\s*(?=[月火水木金土日]|[A-Za-z])/u)
      parts.each do |part|
        # Extract day range and times
        if part =~ /(.*?)[:：]\s*(.*)/
          days_str = $1.strip
          times_str = $2.strip
        else
          # fallback: if no colon, try to split where a time starts
          if part =~ /(.*?)(\d{1,2}:\d{2}.*)/
            days_str = $1.strip
            times_str = $2.strip
          else
            next
          end
        end

        # Expand days (e.g., 月～金 -> 月,火,水,木,金 ; 月、金 -> 月,金)
        days = []
        days_str.split(/[,、\s]+/).each do |token|
          if token =~ /(\p{Han})\s*~\s*(\p{Han})/u || token =~ /(\p{Han})\s*～\s*(\p{Han})/u
            start_d = $1
            end_d = $2
            order = %w[月 火 水 木 金 土 日]
            si = order.index(start_d)
            ei = order.index(end_d)
            if si && ei
              if si <= ei
                days.concat(order[si..ei])
              else
                days.concat(order[si..-1] + order[0..ei])
              end
            end
          else
            days << token
          end
        end

        # Parse time ranges like "11:00～15:00 （料理L.O. 14:30 ドリンクL.O. 14:30）16:30～22:30"
        times = []
        times_str.scan(/(\d{1,2}:\d{2})\s*[~〜～\-\u2013\u2014]\s*(\d{1,2}:\d{2})/) do |from, to|
          times << { from: from, to: to }
        end

        days.each do |d|
          result[d] ||= []
          result[d].concat(times) unless times.empty?
        end
      end

      result.empty? ? nil : result
    end

    json.each do |entry|
      name = entry["name"]&.strip
      address = entry["address"]&.strip
      lat = entry["lat"]
      lon = entry["lon"]
      open_time = entry["openTime"]
      parsed_open_time = parse_open_time(open_time)

      next if name.blank? || address.blank?

      store = Store.find_by(name: name, address: address)
      if store
        skipped += 1
        next
      end

      store = Store.new(name: name, address: address, lat: lat, lon: lon, open_time: open_time)
      store.open_time = parsed_open_time.to_json if parsed_open_time
      if store.save
        created += 1
      else
        puts "Failed to save #{name}: #{store.errors.full_messages.join(', ')}"
      end
    end

    puts "Imported stores: #{created}, Skipped (existing): #{skipped}, Total processed: #{total}"
  end
end
