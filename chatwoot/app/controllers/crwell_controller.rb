class CrwellController < ApplicationController
  before_action :authenticate_user!
  
  def index
    # Get CrWell token from session (stored during login)
    @crwell_token = session[:crwell_token]
    
    # If no token in session, try to login to CrWell
    if @crwell_token.blank? && current_user.present?
      @crwell_token = fetch_crwell_token
    end
    
    # Render view without layout
    render layout: false
  end
  
  private
  
  def fetch_crwell_token
    # This would require storing plain password, which is not secure
    # So we'll just return nil and let the user login manually
    # The token will be available on next Chatwoot login
    nil
  end
end
