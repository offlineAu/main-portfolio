class ApplicationController < ActionController::Base
  before_action :resume_session
  before_action :load_profile
  helper_method :authenticated?

  private

  # Sessions end 14 days after sign-in, or after 12 hours without activity.
  def resume_session
    return unless cookies.signed[:session_id]

    Current.session = Session.active.find_by(id: cookies.signed[:session_id])
    Current.session ? Current.session.touch_activity : cookies.delete(:session_id)
  end

  def authenticated?
    Current.session.present?
  end

  def require_authentication
    redirect_to new_session_path, alert: "Please sign in to continue." unless authenticated?
  end

  def start_session_for(user)
    reset_session
    Session.sweep
    Current.session = user.sessions.create!(user_agent: request.user_agent.to_s.first(255), ip_address: request.remote_ip, last_seen_at: Time.current)
    # Strict: the admin cookie is never sent on requests that start on another site.
    cookies.signed[:session_id] = { value: Current.session.id, httponly: true, same_site: :strict, secure: Rails.env.production?, expires: Session::ABSOLUTE_LIFETIME.from_now }
    AuditEvent.record("session.signed_in", request: request, user: user, details: { new_device: new_device?(user) })
  end

  def new_device?(user)
    user.sessions.where.not(id: Current.session.id).where(ip_address: request.remote_ip, user_agent: Current.session.user_agent).none? &&
      AuditEvent.where(user: user, action: "session.signed_in", ip_address: request.remote_ip, user_agent: Current.session.user_agent).none?
  end

  def load_profile
    @profile = Profile.current
  end

  # Public pages are the same for every visitor, so the Vercel CDN may serve them briefly instead of
  # rendering each view in the container. Browsers still revalidate. The window stays short because a
  # cached page also repeats its CSP nonce. Requests with an owner cookie are never shared: cookies are
  # written after this runs, and a stale one is deleted (Set-Cookie) by resume_session.
  PUBLIC_PAGE_CDN_CACHE = "public, max-age=60, stale-while-revalidate=600"

  def cache_public_page
    return if cookies[:session_id].present? || !response.successful?

    response.headers["CDN-Cache-Control"] = PUBLIC_PAGE_CDN_CACHE
  end
end
