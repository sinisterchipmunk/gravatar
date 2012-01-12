# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_rails-2.3_session',
  :secret      => 'dee543c52ac4610cca3a577caa4dd5490c0745139d578dd28071aaf104f2375f0cf1fba135a463c5ee02c3f5ce07ea73d871a11553d85346ad977321cdd1965b'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
