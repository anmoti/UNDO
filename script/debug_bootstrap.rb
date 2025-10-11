# This script ensures two users exist and sets store operator for debugging.
# It is safe to run multiple times (idempotent).
# Invoked from bin/prod before starting the server.

require "active_record"

puts "[debug_bootstrap] Starting... (RAILS_ENV=#{Rails.env})"

# Helper to upsert user by email and attributes
# NOTE: We do not set exact created_at/updated_at provided in the request to avoid
# messing with Rails timestamps; if strictly needed, uncomment at the end.

def ensure_user(id:, name:, email:, is_company:, password: "PASSWORD")
  user = User.find_by(id: id) || User.find_by(email: email)

  if user
    # Update attributes if they differ
    user.update!(
      name: name,
      email: email,
      is_company: is_company,
    )
    # ensure password is set to known token for local login (has_secure_password)
    user.password = password
    user.password_confirmation = password
    user.save!
    puts "[debug_bootstrap] Updated user id=#{user.id} (#{email})"
  else
    user = User.new(
      id: id,
      name: name,
      email: email,
      is_company: is_company,
      password: password,
      password_confirmation: password
    )
    user.save!(validate: true)
    puts "[debug_bootstrap] Created user id=#{user.id} (#{email})"
  end

  user
end

ActiveRecord::Base.transaction do
  ensure_user(
    id: 1,
    name: "詫間太郎",
    email: "takuma@example.com",
    is_company: false,
  )

  u2 = ensure_user(
    id: 2,
    name: "桶丸水産",
    email: "okemal@example.com",
    is_company: true,
  )

  # Make user 2 an operator of Store 1 if exists
  store = Store.find_by(id: 1)
  if store
    unless StoreOperator.exists?(user_id: u2.id, store_id: store.id)
      StoreOperator.create!(user: u2, store: store)
      puts "[debug_bootstrap] Added StoreOperator user=#{u2.id} store=#{store.id}"
    else
      puts "[debug_bootstrap] StoreOperator already exists user=#{u2.id} store=#{store.id}"
    end
  else
    puts "[debug_bootstrap] WARN: Store id=1 not found; skipping operator setup"
  end
end

puts "[debug_bootstrap] Done."
