# Pin npm packages by running ./bin/importmap

pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"

if Rails.env.development?
  pin "@hotwired/turbo-rails", to: "turbo.min.js"
  pin "@hotwired/stimulus", to: "stimulus.min.js"
  pin "@googlemaps/js-api-loader", to: "@googlemaps/js-api-loader/dist/index.mjs"
else
  pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.16/+esm"
  pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/+esm"
  pin "@googlemaps/js-api-loader", to: "https://cdn.jsdelivr.net/npm/@googlemaps/js-api-loader@1.16.10/+esm"
end

pin "application"
pin_all_from "app/javascript/controllers", under: "controllers"
