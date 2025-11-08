class DeviseOverrides::PasswordsController < Devise::PasswordsController
  include AuthHelper

  skip_before_action :require_no_authentication, raise: false
  skip_before_action :authenticate_user!, raise: false

  def create
    @user = User.from_email(params[:email])
    if @user
      @user.send_reset_password_instructions
      build_response(I18n.t('messages.reset_password_success'), 200)
    else
      build_response(I18n.t('messages.reset_password_failure'), 404)
    end
  end

  def update
    # params: reset_password_token, password, password_confirmation
    original_token = params[:reset_password_token]
    reset_password_token = Devise.token_generator.digest(self, :reset_password_token, original_token)
    @recoverable = User.find_by(reset_password_token: reset_password_token)
    if @recoverable && reset_password_and_confirmation(@recoverable)
      # Sync password with CrWell
      sync_password_with_crwell(@recoverable.email, params[:password])

      send_auth_headers(@recoverable)
      render partial: 'devise/auth', formats: [:json], locals: { resource: @recoverable }
    else
      render json: { message: 'Invalid token', redirect_url: '/' }, status: :unprocessable_entity
    end
  end

  private

  def reset_password_and_confirmation(recoverable)
    recoverable.confirm unless recoverable.confirmed? # confirm if user resets password without confirming anytime before
    recoverable.reset_password(params[:password], params[:password_confirmation])
    recoverable.reset_password_token = nil
    recoverable.confirmation_token = nil
    recoverable.reset_password_sent_at = nil
    recoverable.save!
  end

  def build_response(message, status)
    render json: {
      message: message
    }, status: status
  end

  def sync_password_with_crwell(email, new_password)
    begin
      require 'net/http'
      require 'json'

      uri = URI('https://api.crwell.pro/api/auth/sync-password')
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
      request.body = {
        email: email,
        password: new_password
      }.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        Rails.logger.info "[CrWell Sync] Password updated for #{email}"
      else
        Rails.logger.warn "[CrWell Sync] Password update failed for #{email}: HTTP #{response.code}"
      end
    rescue => e
      Rails.logger.warn "[CrWell Sync] Error updating password: #{e.message}"
    end
  end
end

DeviseOverrides::PasswordsController.prepend_mod_with('DeviseOverrides::PasswordsController')
