require "omnicontacts/middleware/oauth2"
require "rexml/document"

module OmniContacts
  module Importer
    class Gapps < Middleware::OAuth2

      attr_reader :auth_host, :authorize_path, :auth_token_path, :scope

      def initialize *args
        super *args
        @auth_host = "accounts.google.com"
        @authorize_path = "/o/oauth2/auth"
        @auth_token_path = "/o/oauth2/token"
        @scope = "https://www.google.com/m8/feeds https://www.googleapis.com/auth/userinfo.email"
        @contacts_host = "www.google.com"
        @contacts_path = "/m8/feeds/profiles/domain/{domain}/full"
        @max_results =  (args[3] && args[3][:max_results]) || 100
      end

      def fetch_contacts_using_access_token access_token, token_type
        domain = fetch_domain access_token, token_type
        fetch_profiles access_token, token_type, domain
      end

      def fetch_domain access_token, token_type
        owner_response = https_get("www.googleapis.com", "/oauth2/v2/userinfo", contacts_req_params, contacts_req_headers(access_token, token_type))
        user_infos = JSON.parse(owner_response)
        user_infos['hd']
      end

      def fetch_profiles access_token, token_type, domain
        contacts_response = https_get(@contacts_host, "/m8/feeds/profiles/domain/#{domain}/full", contacts_req_params, contacts_req_headers(access_token, token_type))
        parse_contacts contacts_response
      end

      private

      def contacts_req_params
        {"max-results" => @max_results.to_s}
      end

      def contacts_req_headers token, token_type
        {"GData-Version" => "3.0", "Authorization" => "#{token_type} #{token}"}
      end

      def parse_contacts contacts_as_xml
        xml = REXML::Document.new(contacts_as_xml)
        contacts = []
        xml.elements.each('//entry') do |entry|
          gd_email = entry.elements['gd:email']
          if gd_email
            contact = {:email => gd_email.attributes['address']}
            gd_name = entry.elements['gd:name']
            if gd_name
              gd_full_name = gd_name.elements['gd:fullName']
              contact[:name] = gd_full_name.text if gd_full_name
            end
            gd_avatar = entry.elements['link[@type="image/*"]']
            contact[:avatar_url] = gd_avatar ? gd_avatar.attribute('href').to_s : nil
            contacts << contact
          end
        end
        contacts
      end

    end
  end
end
