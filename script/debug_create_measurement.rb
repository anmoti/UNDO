# Usage:
# USER_ID=2 STORE_ID=1 MULT=1.5 bin/rails runner script/debug_create_measurement.rb

user_id = ENV['USER_ID'] || ENV['user_id'] || '2'
store_id = ENV['STORE_ID'] || ENV['store_id']
mult = (ENV['MULT'] || ENV['mult'] || '1.5').to_f

user = User.find_by(id: user_id)
unless user
  puts "User not found id=#{user_id}"
  exit 1
end

limit = user.bod_upper_limit || UserSetting::DEFAULT_SETTINGS[:bod_upper_limit]
if limit.nil?
  puts "No limit found for user=#{user.id} and no default available"
  exit 1
end

bod = (limit.to_f * mult).ceil
store = Store.find_by(id: store_id) if store_id

m = Measurement.new(
  submitter: user,
  store: store,
  turbidity: 0,
  predicted_bod: bod,
  predicted_cod: 0,
  status: :predicted
)

if m.save
  puts "Created measurement id=#{m.id} predicted_bod=#{m.predicted_bod} (limit=#{limit}) for user=#{user.id} store=#{store&.id}"
else
  puts "Failed to create measurement: #{m.errors.full_messages.join(', ')}"
  exit 1
end
