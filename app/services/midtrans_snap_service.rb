require "base64"
require "digest"
require "json"
require "net/http"

class MidtransSnapService
  class Error < StandardError; end

  class << self
    def create_transaction!(booking_code:, gross_amount:, customer:, item_details:)
      body = {
        transaction_details: {
          order_id: booking_code,
          gross_amount: gross_amount.to_i
        },
        customer_details: {
          first_name: customer[:first_name].presence || "Guest",
          email: customer[:email]
        },
        item_details: item_details
      }

      request_json("/snap/v1/transactions", method: :post, body: body)
    end

    def transaction_status(order_id:)
      request_json("/v2/#{order_id}/status", method: :get)
    end

    def verify_notification_signature?(payload)
      expected_signature = Digest::SHA2.hexdigest(
        [
          payload["order_id"],
          payload["status_code"],
          payload["gross_amount"],
          server_key
        ].join
      )

      ActiveSupport::SecurityUtils.secure_compare(expected_signature, payload["signature_key"].to_s)
    rescue ArgumentError, Error
      false
    end

    def server_key
      key = ENV["MIDTRANS_SERVER_KEY"].to_s
      raise Error, "MIDTRANS_SERVER_KEY belum diset" if key.blank?

      key
    end

    def client_key
      ENV["MIDTRANS_CLIENT_KEY"].to_s
    end

    def sandbox?
      value = ENV.fetch("MIDTRANS_IS_PRODUCTION", "false")
      ActiveModel::Type::Boolean.new.cast(value) == false
    end

    def snap_js_url
      sandbox? ? "https://app.sandbox.midtrans.com/snap/snap.js" : "https://app.midtrans.com/snap/snap.js"
    end

    private

    def request_json(path, method:, body: nil)
      uri = URI.join(base_url, path)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = build_request(uri, method, body)
      response = http.request(request)
      parsed = JSON.parse(response.body)

      return parsed if response.code.to_i.between?(200, 299)

      raise Error, parsed["error_messages"].presence || parsed["status_message"].presence || "Midtrans request failed"
    rescue JSON::ParserError
      raise Error, "Invalid Midtrans response"
    end

    def build_request(uri, method, body)
      request_class =
        case method
        when :post then Net::HTTP::Post
        when :get then Net::HTTP::Get
        else
          raise ArgumentError, "Unsupported method: #{method}"
        end

      request = request_class.new(uri)
      request["Authorization"] = "Basic #{Base64.strict_encode64("#{server_key}:")}"
      request["Content-Type"] = "application/json"
      request.body = body.to_json if body.present?
      request
    end

    def base_url
      sandbox? ? "https://app.sandbox.midtrans.com" : "https://app.midtrans.com"
    end
  end
end
