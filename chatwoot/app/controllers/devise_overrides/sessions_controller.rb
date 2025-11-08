class DeviseOverrides::SessionsController < DeviseTokenAuth::SessionsController
  # Prevent session parameter from being passed
  # Unpermitted parameter: session
  wrap_parameters format: []
  before_action :process_sso_auth_token, only: [:create]

  def new
    redirect_to login_page_url(error: 'access-denied')
  end

  def create
    return handle_mfa_verification if mfa_verification_request?
    return handle_sso_authentication if sso_authentication_request?

    user = find_user_for_authentication
    return handle_mfa_required(user) if user&.mfa_enabled?

    # Only proceed with standard authentication if no MFA is required
    super
  end

  def render_create_success
    # CrWell SSO Integration: Auto-login to CrWell after successful Chatwoot login
    crwell_sso_login if should_sync_with_crwell?

    render partial: 'devise/auth', formats: [:json], locals: { resource: @resource }
  end

  private

  def should_sync_with_crwell?
    # Only sync if email and password were provided (not SSO or MFA)
    params[:email].present? && params[:password].present? && @resource.present?
  end

  def crwell_sso_login
    begin
      require 'net/http'
      require 'json'

      # Try to login to CrWell
      token = crwell_api_login(params[:email], params[:password])

      if token
        session[:crwell_token] = token
        Rails.logger.info "[CrWell SSO] Token stored in session for #{params[:email]}"
      else
        # User doesn't exist in CrWell, try to register
        token = crwell_api_register(params[:email], params[:password], @resource.name)
        if token
          session[:crwell_token] = token
          Rails.logger.info "[CrWell SSO] User registered and token stored for #{params[:email]}"
        else
          Rails.logger.warn "[CrWell SSO] Registration failed for #{params[:email]}"
        end
      end
    rescue => e
      # Silently fail - don't affect Chatwoot login
      Rails.logger.warn "[CrWell SSO] Error: #{e.message}"
    end
  end

  def crwell_api_login(email, password)
    uri = URI('https://api.crwell.pro/api/auth/login')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = { email: email, password: password }.to_json
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      return data.dig('data', 'token')
    end
    nil
  rescue => e
    Rails.logger.warn "[CrWell SSO] Login error: #{e.message}"
    nil
  end

  def crwell_api_register(email, password, name)
    uri = URI('https://api.crwell.pro/api/auth/register')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 5

    request = Net::HTTP::Post.new(uri.path, 'Content-Type' => 'application/json')
    request.body = {
      email: email,
      password: password,
      name: name || email.split('@').first,
      role: 'USER'
    }.to_json
    response = http.request(request)

    if response.is_a?(Net::HTTPSuccess)
      data = JSON.parse(response.body)
      return data.dig('data', 'token')
    end
    nil
  rescue => e
    Rails.logger.warn "[CrWell SSO] Register error: #{e.message}"
    nil
  end

  def find_user_for_authentication
    return nil unless params[:email].present? && params[:password].present?

    normalized_email = params[:email].strip.downcase
    user = User.from_email(normalized_email)
    return nil unless user&.valid_password?(params[:password])
    return nil unless user.active_for_authentication?

    user
  end

  def mfa_verification_request?
    params[:mfa_token].present?
  end

  def sso_authentication_request?
    params[:sso_auth_token].present? && @resource.present?
  end

  def handle_sso_authentication
    authenticate_resource_with_sso_token
    yield @resource if block_given?
    render_create_success
  end

  def login_page_url(error: nil)
    frontend_url = ENV.fetch('FRONTEND_URL', nil)

    "#{frontend_url}/app/login?error=#{error}"
  end

  def authenticate_resource_with_sso_token
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    # invalidate the token after the user is signed in
    @resource.invalidate_sso_auth_token(params[:sso_auth_token])
  end

  def process_sso_auth_token
    return if params[:email].blank?

    user = User.from_email(params[:email])
    @resource = user if user&.valid_sso_auth_token?(params[:sso_auth_token])
  end

  def handle_mfa_required(user)
    render json: {
      mfa_required: true,
      mfa_token: Mfa::TokenService.new(user: user).generate_token
    }, status: :partial_content
  end

  def handle_mfa_verification
    user = Mfa::TokenService.new(token: params[:mfa_token]).verify_token
    return render_mfa_error('errors.mfa.invalid_token', :unauthorized) unless user

    authenticated = Mfa::AuthenticationService.new(
      user: user,
      otp_code: params[:otp_code],
      backup_code: params[:backup_code]
    ).authenticate

    return render_mfa_error('errors.mfa.invalid_code') unless authenticated

    sign_in_mfa_user(user)
  end

  def sign_in_mfa_user(user)
    @resource = user
    @token = @resource.create_token
    @resource.save!

    sign_in(:user, @resource, store: false, bypass: false)
    render_create_success
  end

  def render_mfa_error(message_key, status = :bad_request)
    render json: { error: I18n.t(message_key) }, status: status
  end
end

DeviseOverrides::SessionsController.prepend_mod_with('DeviseOverrides::SessionsController')
