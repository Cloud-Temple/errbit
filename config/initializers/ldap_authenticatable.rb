require 'net-ldap'
require 'devise/strategies/authenticatable'

module Devise
  module Strategies
    class LdapAuthenticatable < Authenticatable

      def authenticate!
        if params[:user]
          @ldap = Net::LDAP.new
          @ldap.host = ENV['LDAP_HOST']
          @ldap.port = ENV['LDAP_PORT']

          login = email[0, email.index('@')]

          ENV['LDAP_ALLOWED_DOMAIN'].split(';').each do |domain|
            ldap_requested_user = ENV['LDAP_ATTRUBUTE'] + '=' + login + ',' + domain
            @ldap.auth ldap_requested_user, password

            if @ldap.bind
              ENV['LDAP_ALLOWED_GROUP'].split(';').each do |group|
                if is_in_group? login, group
                  user = User.find_or_create_by(email: email)
                  user.name = namify(login)
                  return success!(user)
                end
              end
            end
          end
          return fail(:invalid_login)
        end
      end

      def is_in_group?(uid, group)
        filter = Net::LDAP::Filter.construct("(&(objectClass=posixGroup)(cn=#{group}))")
        treebase = ENV['LDAP_ROOT']

        @ldap.search( :base => treebase , :filter => filter ) do |entry|
          return true if entry[:memberuid].include? uid
        end
        return false
      end

      def namify(login)
        login.gsub(/\./, ' ').split(' ').each{ |e| e.capitalize! }.join(' ')
      end

      def email
        params[:user][:email]
      end

      def password
        params[:user][:password]
      end

    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)