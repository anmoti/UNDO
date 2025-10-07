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

    json.each do |entry|
      name = entry["name"]&.strip
      address = entry["address"]&.strip
      lat = entry["lat"]
      lon = entry["lon"]
      open_time = entry["openTime"]

      next if name.blank? || address.blank?

      store = Store.find_by(name: name, address: address)
      if store
        skipped += 1
        next
      end

      store = Store.new(name: name, address: address, lat: lat, lon: lon, open_time: open_time)
      if store.save
        created += 1
      else
        puts "Failed to save #{name}: #{store.errors.full_messages.join(', ')}"
      end
    end

    puts "Imported stores: #{created}, Skipped (existing): #{skipped}, Total processed: #{total}"
  end
end
