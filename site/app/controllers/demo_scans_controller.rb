# The till behind ScanInput's docs demo: a scanned code comes in as a form
# post and a cart line goes back as a Turbo Stream, as in an app. It answers
# a little slowly on purpose, so quick scans can be seen waiting their turn
# rather than being lost. Nothing is kept.
class DemoScansController < ApplicationController
  # It keeps and changes nothing, so there's nothing for a forged request to
  # do; and the docs pages it's posted from are cached without a session.
  skip_forgery_protection

  ITEMS = {
    "8901030865278" => [ "Basmati rice, 1 kg", 189 ],
    "8901058851298" => [ "Instant noodles, 4 pack", 56 ],
    "8901719110016" => [ "Toor dal, 500 g", 92 ],
    "8902080104581" => [ "Green tea, 25 bags", 145 ],
    "8901725181222" => [ "Sunflower oil, 1 L", 168 ]
  }.freeze

  DELAY = Rails.env.test? ? 0 : 0.4

  def create
    sleep DELAY
    code = params[:code].to_s.strip
    name, price = ITEMS[code]

    streams = if name
      [ turbo_stream.append("scan-demo-lines", partial: "demo_scans/line", locals: { code: code, name: name, price: price }),
        turbo_stream.update("scan-demo-status", "") ]
    else
      turbo_stream.update("scan-demo-status", "No item with the code #{code}")
    end
    render turbo_stream: streams
  end
end
