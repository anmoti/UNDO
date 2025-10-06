sudo chown -R $USER:$USER vendor/bundle
bundle install
rails db:migrate
