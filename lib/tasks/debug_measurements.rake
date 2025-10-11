namespace :debug do
  desc "Create a measurement for debugging. Usage: rake debug:create_measurement user_id=2 store_id=1 bod=123"
  task create_measurement: :environment do
    user_id = ENV["user_id"] || ENV["USER_ID"]
    store_id = ENV["store_id"] || ENV["STORE_ID"]
    bod = ENV["bod"] || ENV["BOD"]

    unless user_id && bod
      puts "Usage: rake debug:create_measurement user_id=2 store_id=1 bod=123"
      exit 1
    end

    user = User.find_by(id: user_id)
    store = Store.find_by(id: store_id) if store_id

    unless user
      puts "User with id=#{user_id} not found"
      exit 1
    end

    measurement = Measurement.new(
      submitter: user,
      store: store,
      turbidity: 0,
      predicted_bod: bod.to_f,
      predicted_cod: 0,
      status: :predicted
    )

    if measurement.save
      puts "Created measurement id=#{measurement.id} predicted_bod=#{measurement.predicted_bod} for user=#{user.id} store=#{store&.id}"
    else
      puts "Failed to create measurement: #{measurement.errors.full_messages.join(', ')}"
      exit 1
    end
  end

  desc "Delete measurements for Okemal (company) under Futaba Udon store. Usage: rake debug:purge_measurements_for_futaba [COMPANY_ID=2|COMPANY_EMAIL=okemal@example.com] [STORE_ID=1|STORE_NAME=ふたばうどん] [FORCE_DESTROY=true]"
  task purge_measurements_for_futaba: :environment do
    company = if ENV["COMPANY_EMAIL"]
      User.find_by(email: ENV["COMPANY_EMAIL"])
    elsif ENV["COMPANY_ID"]
      User.find_by(id: ENV["COMPANY_ID"])
    else
      User.find_by(email: "okemal@example.com") || User.find_by(id: 2)
    end

    unless company
      puts "Company user not found (provide COMPANY_EMAIL or COMPANY_ID)"
      exit 1
    end

    store = if ENV["STORE_ID"]
      Store.find_by(id: ENV["STORE_ID"])
    elsif ENV["STORE_NAME"]
      Store.find_by(name: ENV["STORE_NAME"])
    else
      Store.find_by(id: 1) || Store.find_by(name: "ふたばうどん")
    end

    unless store
      puts "Store not found (provide STORE_ID or STORE_NAME)"
      exit 1
    end

    unless StoreOperator.exists?(user: company, store: store)
      puts "Abort: #{company.name}(id=#{company.id}) is not an operator of store #{store.id} (#{store.name})"
      exit 1
    end

    scope = Measurement.where(store: store)
    count = scope.count
    if count.zero?
      puts "No measurements found for store #{store.id} (#{store.name})"
      next
    end

    if ENV["FORCE_DESTROY"]&.to_s&.downcase == "true"
      scope.destroy_all
      puts "Destroyed #{count} measurements for store #{store.id} (#{store.name})"
    else
      scope.delete_all
      puts "Deleted #{count} measurements for store #{store.id} (#{store.name})"
    end
  end
end
