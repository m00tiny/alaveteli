# == Schema Information
# Schema version: 32
#
# Table name: users
#
#  id              :integer         not null, primary key
#  email           :string(255)     not null
#  name            :string(255)     not null
#  hashed_password :string(255)     not null
#  salt            :string(255)     not null
#  created_at      :datetime        not null
#  updated_at      :datetime        not null
#  email_confirmed :boolean         default(false), not null
#

# models/user.rb:
# Model of people who use the site to file requests, make comments etc.
#
# Copyright (c) 2007 UK Citizens Online Democracy. All rights reserved.
# Email: francis@mysociety.org; WWW: http://www.mysociety.org/
#
# $Id: user.rb,v 1.25 2008-02-14 15:31:22 francis Exp $

require 'digest/sha1'

class User < ActiveRecord::Base
    validates_presence_of :email, :message => "^Please enter your email address"
    validates_uniqueness_of :email, :case_sensitive => false, :message => "^There is already an account with that email address. You can sign in to it on the left."

    validates_presence_of :name, :message => "^Please enter your name"
    validates_presence_of :hashed_password, :message => "^Please enter a password"

    has_many :info_requests

    attr_accessor :password_confirmation
    validates_confirmation_of :password, :message =>"^Please enter the same password twice"

    def validate
        errors.add(:email, "doesn't look like a valid address") unless MySociety::Validate.is_valid_email(self.email)
    end

    # Return user given login email, password and other form parameters (e.g. name)
    #  
    # The specific_user_login parameter says that login as a particular user is
    # expected, so no parallel registration form is being displayed.
    def self.authenticate_from_form(params, specific_user_login = false)
        if specific_user_login
            auth_fail_message = "Either the email or password was not recognised, please try again."
        else
            auth_fail_message = "Either the email or password was not recognised, please try again. Or create a new account using the form on the right."
        end

        user = self.find(:first, :conditions => [ 'email ilike ?', params[:email] ] ) # using ilike for case insensitive
        if user
            # There is user with email, check password
            expected_password = encrypted_password(params[:password], user.salt)
            if user.hashed_password != expected_password
                user.errors.add_to_base(auth_fail_message)
            end
        else
            # No user of same email, make one (that we don't save in the database)
            # for the forms code to use.
            user = User.new(params)
            # deliberately same message as above so as not to leak whether 
            user.errors.add_to_base(auth_fail_message)
        end
        user
    end

    # Virtual password attribute, which stores the hashed password, rather than plain text.
    def password
        @password
    end
    def password=(pwd)
        @password = pwd
        return if pwd.blank?
        create_new_salt
        self.hashed_password = User.encrypted_password(self.password, self.salt)
    end

    # For use in to/from in email messages
    def name_and_email
        return self.name + " <" + self.email + ">"
    end

    private

    def self.encrypted_password(password, salt)
        string_to_hash = password + salt # XXX need to add a secret here too?
        Digest::SHA1.hexdigest(string_to_hash)
    end
    
    def create_new_salt
        self.salt = self.object_id.to_s + rand.to_s
    end
end

