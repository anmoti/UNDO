namespace :debug do
  # --- Internal helpers (for reuse in tasks) ---
  def dbg_find_or_create_company!(email: nil, id: nil)
    company = if email
      User.find_by(email: email)
    elsif id
      User.find_by(id: id)
    else
      nil
    end
    raise "Company user not found. Provide COMPANY_EMAIL or COMPANY_ID" unless company
    raise "User #{company.id} is not a company" unless company.is_company

    company
  end

  def dbg_find_or_create_store!(id: nil, name: nil, default_attrs: {})
    store = if id
      Store.find_by(id: id)
    elsif name
      Store.find_by(name: name)
    else
      nil
    end
    if store.nil?
      raise "Store not found (provide STORE_ID or STORE_NAME)" if name.blank?

      attrs = {
        name: name,
        address: "香川県三豊市詫間町香田551",
        lat: 34.23428,
        lon: 133.6360,
        open_time: "10:30-14:30"
      }.merge(default_attrs || {})
      store = Store.create!(attrs)
    end
    store
  end

  def dbg_ensure_operator!(company:, store:)
    unless StoreOperator.exists?(user: company, store: store)
      StoreOperator.create!(user: company, store: store)
      puts "Linked company #{company.id} to store #{store.id} as operator"
    end
  end

  def dbg_create_high_bod_measurement!(company:, store:, desired_bod: nil)
    default_limit = UserSetting::DEFAULT_SETTINGS[:bod_upper_limit]
    limit = company.bod_upper_limit || default_limit
    bod = (desired_bod || (limit + 100)).to_f
    bod = limit + 1 if bod <= limit
    Measurement.create!(
      submitter: company,
      store: store,
      turbidity: 0.0,
      predicted_bod: bod,
      predicted_cod: 0.0,
      status: :predicted
    )
  end
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

    # 併せてエコマークを解除（is_eco=false）
    if store.respond_to?(:revoke_eco_mark!)
      store.revoke_eco_mark!
    else
      store.update!(is_eco: false)
    end
    puts "Revoked eco mark for store #{store.id} (#{store.name})"
  end

  desc "Create an over-threshold measurement for Okemal (company) under Futaba Udon store. Usage: rake debug:make_futaba_high_bod [COMPANY_ID=2|COMPANY_EMAIL=okemal@example.com] [STORE_ID=1|STORE_NAME=ふたばうどん] [BOD=6000]"
  task make_futaba_high_bod: :environment do
    begin
      fallback_company = User.find_by(email: "okemal@example.com") || User.find_by(id: 2)
      company = dbg_find_or_create_company!(email: ENV["COMPANY_EMAIL"] || fallback_company&.email, id: ENV["COMPANY_ID"] || fallback_company&.id)
      store = if ENV["STORE_ID"] || ENV["STORE_NAME"]
        dbg_find_or_create_store!(id: ENV["STORE_ID"], name: ENV["STORE_NAME"])
      else
        dbg_find_or_create_store!(id: 1, name: "ふたばうどん")
      end
      dbg_ensure_operator!(company: company, store: store)
      measurement = dbg_create_high_bod_measurement!(company: company, store: store, desired_bod: ENV["BOD"])
      limit = company.bod_upper_limit || UserSetting::DEFAULT_SETTINGS[:bod_upper_limit]
      puts "Created HIGH BOD measurement id=#{measurement.id} predicted_bod=#{measurement.predicted_bod} (limit=#{limit}) for company=#{company.id} store=#{store.id}"
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc "Create an over-threshold measurement for any company/store. Usage: rake debug:make_high_bod COMPANY_EMAIL=...|COMPANY_ID=... STORE_NAME=...|STORE_ID=... [BOD=6000]"
  task make_high_bod: :environment do
    begin
      company = dbg_find_or_create_company!(email: ENV["COMPANY_EMAIL"], id: ENV["COMPANY_ID"])
      store = dbg_find_or_create_store!(id: ENV["STORE_ID"], name: ENV["STORE_NAME"])
      dbg_ensure_operator!(company: company, store: store)
      measurement = dbg_create_high_bod_measurement!(company: company, store: store, desired_bod: ENV["BOD"])
      limit = company.bod_upper_limit || UserSetting::DEFAULT_SETTINGS[:bod_upper_limit]
      puts "Created HIGH BOD measurement id=#{measurement.id} predicted_bod=#{measurement.predicted_bod} (limit=#{limit}) for company=#{company.id} store=#{store.id}"
    rescue => e
      puts e.message
      exit 1
    end
  end

  desc "Purge measurements for any company/store. Usage: rake debug:purge_measurements COMPANY_EMAIL=...|COMPANY_ID=... STORE_NAME=...|STORE_ID=... [FORCE_DESTROY=true]"
  task purge_measurements: :environment do
    begin
      company = dbg_find_or_create_company!(email: ENV["COMPANY_EMAIL"], id: ENV["COMPANY_ID"])
      store = dbg_find_or_create_store!(id: ENV["STORE_ID"], name: ENV["STORE_NAME"])

      unless StoreOperator.exists?(user: company, store: store)
        puts "Abort: #{company.name}(id=#{company.id}) is not an operator of store #{store.id} (#{store.name})"
        exit 1
      end

      scope = Measurement.where(store: store)
      count = scope.count
      if count.zero?
        puts "No measurements found for store #{store.id} (#{store.name})"
      else
        if ENV["FORCE_DESTROY"]&.to_s&.downcase == "true"
          scope.destroy_all
          puts "Destroyed #{count} measurements for store #{store.id} (#{store.name})"
        else
          scope.delete_all
          puts "Deleted #{count} measurements for store #{store.id} (#{store.name})"
        end
      end

      # Always revoke eco mark regardless of measurement count
      if store.respond_to?(:revoke_eco_mark!)
        store.revoke_eco_mark!
      else
        store.update!(is_eco: false)
      end
      puts "Revoked eco mark for store #{store.id} (#{store.name})"
    rescue => e
      puts e.message
      exit 1
    end
  end
end
