# Direct uploads for the File Field demo on its docs page. Active Storage's
# browser code first asks for a blob (create), then PUTs the file where it's
# told (update). This answers both the same way, but keeps nothing: the docs
# site has no storage, and a public page shouldn't collect files.
class DemoUploadsController < ApplicationController
  MAX = 10.megabytes

  # Lookbook's preview pages carry no CSRF token, which Active Storage's
  # browser code would send; an app's own layout has one. Nothing here is kept.
  skip_forgery_protection

  def create
    blob = params.require(:blob).permit(:filename, :byte_size, :content_type)
    return head :content_too_large if blob[:byte_size].to_i > MAX

    key = SecureRandom.hex(8)
    render json: { signed_id: "demo-#{key}", key: key, filename: blob[:filename].to_s,
                   direct_upload: { url: demo_upload_url(key), headers: { "Content-Type" => blob[:content_type].to_s } } }
  end

  def update
    return head :content_too_large if request.content_length.to_i > MAX

    head :no_content
  end
end
