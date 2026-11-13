require "test_helper"

class PortfolioTest < ActionDispatch::IntegrationTest
  include OwnerSignIn
  test "public pages render real content and metadata" do
    [root_path, projects_path, about_path, experience_path, contact_path].each do |path|
      get path
      assert_response :success
      assert_select "aside#site-navigation"
      assert_select "header.topbar"
      assert_select "h1", count: 1
      assert_select "meta[property='og:image']"
      assert_select "meta[name='turbo-prefetch'][content='false']"
    end
    get root_path
    assert_select ".hero-portrait"
    assert_select ".project-featured h3", text: "Sentisphere"
  end

  test "filters are server rendered and handle empty results" do
    get projects_path, params: { technology: "Flutter" }
    assert_select ".project-card", count: 1
    assert_select ".project-card h3", text: "E-Lista"
    get projects_path, params: { technology: "missing" }
    assert_select ".empty-state", text: /No projects/
    get projects_path, params: { technology: "' OR 1=1 --" }
    assert_select ".project-card", count: 0
  end

  test "drafts are absent from all public entrypoints and sitemap" do
    project = Project.find_by!(slug: "sentisphere")
    project.update!(published: false)
    get root_path
    assert_select ".project-card h3", text: project.name, count: 0
    get projects_path
    assert_select ".project-card h3", text: project.name, count: 0
    get project_path(project)
    assert_response :not_found
    get "/sitemap.xml"
    assert_response :success
    assert_not_includes response.body, "/projects/sentisphere"
  end

  test "unknown project returns 404" do
    get "/projects/does-not-exist"
    assert_response :not_found
  end

  test "invalid image tokens return 404" do
    get portfolio_media_path("invalid-signature")
    assert_response :not_found
  end

  test "content remains escaped" do
    Project.first.update!(tagline: '<script>alert("xss")</script>')
    get projects_path
    assert_not_includes response.body, '<script>alert("xss")</script>'
    assert_includes response.body, "&lt;script&gt;"
  end

  test "metadata is reachable and the legacy experiment is gone" do
    get "/motion-lab.html"
    assert_response :not_found
    get "/legacy/motion-lab.html"
    assert_response :not_found
    get "/robots.txt"
    assert_response :success
    assert_includes response.body, "Disallow: /admin"
    get "/up"
    assert_response :success
  end

  test "crawler metadata does not require a profile" do
    # These endpoints must stay available without loading site presentation data.
    Profile.delete_all
    ["/robots.txt", "/.well-known/security.txt", "/sitemap.xml"].each do |path|
      get path
      assert_response :success
      assert_nil response.headers["Set-Cookie"]
    end
    assert_includes response.body, project_path(Project.published.first)
  end

  test "public pages can be served by the CDN without a session cookie" do
    [root_path, projects_path, about_path, experience_path, contact_path, project_path(Project.published.first)].each do |path|
      get path
      assert_response :success
      assert_equal ApplicationController::PUBLIC_PAGE_CDN_CACHE, response.headers["CDN-Cache-Control"], path
      assert_nil response.headers["Set-Cookie"], path
      assert_select "meta[name='csrf-token']", count: 0
    end
    get "/projects/does-not-exist"
    assert_nil response.headers["CDN-Cache-Control"]
  end

  test "published media is cacheable by the CDN and drafts are not" do
    project = Project.published.first
    project.gallery.attach(io: StringIO.new(Vips::Image.black(40, 40).write_to_buffer(".png")), filename: "a.png", content_type: "image/png")
    path = portfolio_media_path(MediaToken.sign(project.gallery.attachments.last))
    get path
    assert_response :success
    assert_equal %w[immutable max-age=31536000 public], response.headers["Cache-Control"].split(", ").sort
    assert_equal "public, max-age=31536000, immutable", response.headers["CDN-Cache-Control"]
    assert_equal "same-origin", response.headers["Cross-Origin-Resource-Policy"]

    @owner = create_owner
    sign_in
    project.update!(published: false)
    get path
    assert_response :success
    assert_equal "private, no-store", response.headers["Cache-Control"]
    assert_nil response.headers["CDN-Cache-Control"]
    get about_path
    assert_nil response.headers["CDN-Cache-Control"], "owner requests must never be shared"
  end
end
