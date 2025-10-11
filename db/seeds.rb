require "json"

puts "===== Importing stores... ====="

seeds_dir = Rails.root.join("db", "seeds", "stores")
pattern = File.join(seeds_dir, "**", "*.json")
files = Dir.glob(pattern)

if files.empty?
  puts "No seed files found to import (pattern=#{pattern})."
  return
end

total = 0
created = 0
skipped = 0
warnings = []
seen_coords = Hash.new { |h, k| h[k] = [] }

files.each do |file|
  puts "  -> Reading: #{file}..."
  begin
    json = JSON.parse(File.read(file))
  rescue JSON::ParserError => e
    warnings << "JSON の解析に失敗しました: #{file} - #{e.message}"
    next
  end

  unless json.is_a?(Array)
    warnings << "JSON 配列ではありません: #{file}"
    next
  end

  json.each do |entry|
    total += 1

    name = entry["name"]&.strip
    address = entry["address"]&.strip
    lat = (entry["lat"])&.to_s
    lon = (entry["lon"] || entry["lng"])&.to_s
    open_time = entry["openTime"]
    tel = nil
    if entry.key?("tel") && entry["tel"].is_a?(Array)
      tel = entry["tel"].first
    elsif entry.key?("tel") && entry["tel"].is_a?(String)
      tel = entry["tel"]
    end

    if name.blank? || address.blank?
      warnings << "無効なエントリ: #{file} - #{entry.inspect}"
      skipped += 1
      next
    end

    if lat.present? && lon.present?
      coord_key = "#{lat}/#{lon}"
      seen_coords[coord_key] << { file: file, name: name }
    else
      warnings << "座標情報なし: #{file} - #{name}"
      skipped += 1
      next
    end

    store = nil
    store = Store.find_by(lat: lat.to_f, lon: lon.to_f)
    unless store
      store = Store.find_by(name: name, address: address)
    end

    if store
      skipped += 1
      next
    end

    attrs = {
      name: name,
      address: address,
      lat: lat.to_f,
      lon: lon.to_f
    }
    attrs[:open_time] = JSON.generate(open_time) if open_time.present?
    attrs[:tel] = tel if tel.present?

    store = Store.new(attrs)
    if store.save
      created += 1
    else
      warnings << "保存に失敗しました: #{file}) - #{name} #{store.errors.full_messages.join(', ')}"
    end
  end
end

seen_coords.each do |coord, occurrences|
  next if occurrences.size <= 1
  grouped = occurrences.group_by { |o| o[:file] }
  parts = grouped.map do |file, items|
    names = items.map { |i| i[:name] || "(無名)" }.uniq
    "#{file}: [#{names.join(', ')}]"
  end
  warnings << "重複座標検出 (#{coord}): #{parts.join(' ; ')}"
end

puts "----------------------------------------------------------------"
puts "インポート済み: #{created} 件, 既存スキップ: #{skipped} 件, 処理合計: #{total} 件"
if warnings.any?
  puts "警告:\n"
  warnings.each { |w| puts " - #{w}" }
end
puts "============================="
