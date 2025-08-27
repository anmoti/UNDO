sudo chown -R $USER:$USER vendor/bundle
bundler install
rails db:migrate
