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

          login = username

          ENV['LDAP_ALLOWED_DOMAIN'].split(';').each do |domain|
            ldap_requested_user = ENV['LDAP_ATTRUBUTE'] + '=' + login + ',' + domain
            @ldap.auth ldap_requested_user, password

            if @ldap.bind
              ENV['LDAP_ALLOWED_GROUP'].split(';').each do |group|
                if is_in_group? login, group
                  if User.where(username: login).first.nil?
                    user = User.find_or_create_by(username: login)
                    filter_by_uid = '('+ENV['LDAP_ATTRUBUTE']+'='+login+')'
                    attributes = [ENV['LDAP_USER_EMAIL_ATTRIBUTE'].to_s.to_sym, ENV['LDAP_USER_FULLNAME_ATTRIBUTE'].to_s.to_sym]
                    @ldap.search( base: ENV['LDAP_ROOT'], filter: filter_by_uid , attributes: attributes) do |entry|
                        user.email = entry[:mail].first
                        user.name = entry[:displayName].first
                    end
                  else
                    user = User.find_or_create_by(username: login)
                  end

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

      def username
        params[:user][:username]
      end

      def password
        params[:user][:password]
      end

    end
  end
end

Warden::Strategies.add(:ldap_authenticatable, Devise::Strategies::LdapAuthenticatable)