ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end

# Integration test helpers
module ActionDispatch
  class IntegrationTest
    # ユーザーをサインインさせるヘルパーメソッド
    # @param user [User] サインインするユーザー（fixtureまたはUserオブジェクト）
    # @param password [String] ユーザーのパスワード
    def sign_in_as(user, password: "password")
      post signin_path, params: {
        email: user.email,
        password: password
      }
    end

    # サインアウトするヘルパーメソッド
    def sign_out
      delete signout_path
    end
  end
end
