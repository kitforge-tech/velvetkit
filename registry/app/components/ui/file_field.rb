# frozen_string_literal: true

require "securerandom"

# UI::FileField — a drag-and-drop dropzone over a native file input, with
# previews of what's chosen and, optionally, uploads straight to storage.
#
#   <%= render(UI::FileField.new(form: f, field: :photos, multiple: true, accept: "image/*",
#                                max_size: 5.megabytes, direct_upload: true)) %>
#
# The input itself is sr-only, not hidden: it stays in the accessibility tree,
# and keyboard and the system file dialog come from the real
# <input type="file">. The dropzone is a <label> around it, so clicking
# anywhere in it opens the picker with no JavaScript.
#
# Each chosen file shows as a tile: a thumbnail for an image, an icon for
# anything else, its name and size, and a button to take it out again.
# `accept:` and `max_size:` (bytes) are checked as files are added, dropped
# ones included, and a file that fails says why instead of being sent.
# `preview: false` goes back to listing the names under the dropzone.
#
# `direct_upload: true` sends each file to storage the moment it's chosen,
# through Active Storage's direct uploads, with a progress bar on its tile; the
# form then submits only the uploaded files' signed ids, so a big photo never
# holds up the form. Sending the form while files are still uploading waits
# for them, then sends. It needs Active Storage's JavaScript and, for a bucket
# such as Cloudflare R2 or S3, CORS rules allowing PUT from your site.
#
# Bound to a form, the record's current attachments show as tiles too, kept by
# their signed ids, so removing a tile and saving removes that file.
class UI::FileField < UI::Base
  def initialize(multiple: false, accept: nil, preview: true, direct_upload: false, max_size: nil,
                  label: nil, label_size: :default, label_weight: :medium,
                  hint: nil, required: false, error: nil, disabled: false,
                  form: nil, field: nil, existing: nil,
                  class: nil, **html_attrs)
    @form          = form
    @field         = field
    @multiple      = multiple
    @accept        = accept
    @preview       = preview
    @direct_upload = direct_upload
    @max_size      = max_size
    @existing      = existing
    @hint          = hint
    @required      = required
    @disabled      = disabled
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    # The hint is shown inside the card, under the drop prompt, so the
    # wrapper keeps only the label and the error.
    @wrapper       = UI::FormField.new(label: label, error: error,
                                       required: required, disabled: disabled,
                                       label_size: label_size, label_weight: label_weight,
                                       form: form, field: field)
    @input_id      = @html_attrs[:id] || "ui-file-field-#{SecureRandom.hex(4)}"
    @html_attrs[:id] = @input_id
    @wrapper.for = @input_id
  end

  attr_reader :wrapper

  def form_field? = @form.present? && @field.present?
  def preview? = @preview
  def direct_upload? = @direct_upload

  # The field is a card, like UI::Card: the drop area at the top and the
  # chosen files under it.
  def card_classes
    cn("w-full rounded-xl border bg-card p-2 text-card-foreground shadow-sm",
       { "border-destructive" => wrapper.error?, "opacity-50" => @disabled }, @user_class)
  end

  def dropzone_classes
    cn("relative flex cursor-pointer flex-col items-center gap-3 rounded-lg border border-dashed border-input",
       "bg-muted/40 px-6 py-8 text-center transition-colors hover:bg-muted/70",
       "has-[input:focus-visible]:ring-2 has-[input:focus-visible]:ring-primary has-[input:focus-visible]:ring-offset-1 ring-offset-card",
       "data-[drag=true]:border-primary data-[drag=true]:bg-primary/5",
       { "pointer-events-none" => @disabled })
  end

  # What the field takes, under the drop prompt: the hint, or else one made
  # from `accept:` and `max_size:` ("Images, up to 5 MB each").
  def requirements
    return @hint if @hint.present?

    kinds = accepted_kinds
    size = (t(@multiple ? "ui.file_field.up_to_each" : "ui.file_field.up_to", size: human_size(@max_size),
              default: @multiple ? "up to %{size} each" : "up to %{size}") if @max_size)
    return nil unless kinds || size

    [ kinds, size ].compact.join(", ").upcase_first
  end

  def requirements_id = "#{@input_id}-requirements"

  def describedby
    [ (requirements_id if requirements), (wrapper.error_id if wrapper.error_message.present?) ].compact.join(" ").presence
  end

  def root_data
    { controller: "ui--file-field",
      "ui--file-field-preview-value": preview?,
      "ui--file-field-direct-upload-value": direct_upload?,
      "ui--file-field-url-value": (direct_upload_url if direct_upload?),
      "ui--file-field-name-value": signed_id_name,
      "ui--file-field-multiple-value": @multiple,
      "ui--file-field-accept-value": @accept,
      "ui--file-field-max-size-value": @max_size,
      "ui--file-field-required-value": @required,
      "ui--file-field-labels-value": labels.to_json,
      action: "dragover->ui--file-field#dragOver dragleave->ui--file-field#dragLeave drop->ui--file-field#drop" }.compact
  end

  def html_options
    opts = @html_attrs.dup
    opts[:type]            = "file"
    opts[:class]           = "sr-only"
    opts[:multiple]        = true if @multiple
    opts[:accept]          = @accept if @accept
    opts[:disabled]        = true if @disabled
    # A file already kept satisfies `required`; the controller keeps this in step.
    opts[:required]        = true if @required && existing_files.empty?
    opts[:"data-ui--file-field-target"] = "input"
    opts[:"data-action"]   = "change->ui--file-field#chosen"
    opts[:"aria-invalid"]  = "true" if wrapper.error?
    opts[:"aria-describedby"] = describedby if describedby
    opts
  end

  # The builder derives the name itself, so drop any explicit one.
  def form_field_options
    html_options.except(:name, :type)
  end

  # ── Kept and uploaded files ──────────────────────────────────────────────

  # Where a kept or uploaded file's signed id is posted: the field's own
  # name, so Active Storage takes it like an upload.
  def signed_id_name
    name = form_field? ? "#{@form.object_name}[#{@field}]" : @html_attrs[:name].to_s
    return name if name.empty?

    @multiple && !name.end_with?("[]") ? "#{name}[]" : name
  end

  # The record's current attachments, or `existing:`: anything with a
  # signed_id, filename, byte_size and content_type.
  def existing_files
    return [] unless preview?

    @existing_files ||= Array(@existing.nil? ? bound_attachments : @existing).map do |file|
      { signed_id: file.signed_id, name: file.filename.to_s, size: file.byte_size,
        image: file.content_type.to_s.start_with?("image/"), url: file_url(file) }
    end
  end

  def human_size(bytes) = ActiveSupport::NumberHelper.number_to_human_size(bytes)

  def labels
    { remove: t("ui.file_field.remove", default: "Remove %{name}"),
      uploading: t("ui.file_field.uploading", default: "Uploading…"),
      uploaded: t("ui.file_field.uploaded", default: "Uploaded"),
      failed: t("ui.file_field.failed", default: "Upload failed"),
      retry: t("ui.file_field.retry", default: "Try again"),
      too_big: t("ui.file_field.too_big", default: "Too big: %{max} at most"),
      max: (human_size(@max_size) if @max_size),
      wrong_type: t("ui.file_field.wrong_type", default: "Not a file this field takes"),
      waiting: t("ui.file_field.waiting", default: "Waiting for the uploads to finish…"),
      added: t("ui.file_field.added", default: "%{name} added"),
      removed: t("ui.file_field.removed", default: "%{name} removed"),
      units: storage_units }
  end

  def tile_classes
    "group flex min-w-0 items-center gap-3 rounded-lg border bg-background p-2 transition-colors " \
      "data-[state=error]:border-destructive/40 data-[state=error]:bg-destructive/5"
  end

  # One file, as a row: its thumbnail or an icon, its name, its size and
  # where it's got to, a progress bar while it uploads, and a button to take
  # it out. The controller fills in a blank one for each file chosen; the
  # tick and the warning show by the row's state, with no script.
  def tile(name: "", size: nil, url: nil, image: false, signed_id: nil, state: "kept")
    thumb = image && url.present?
    tag.li(class: tile_classes, data: { "ui--file-field-target": "item", state: state }) do
      safe_join([
        tag.div(class: "relative flex size-10 shrink-0 items-center justify-center overflow-hidden rounded-md bg-muted text-muted-foreground") do
          safe_join([
            tag.img(src: url, alt: "", class: "size-full object-cover", hidden: !thumb, data: { role: "thumb" }),
            tag.span(render(UI::Icon.new(name: "file", size: :sm)), hidden: thumb, data: { role: "icon" })
          ])
        end,
        tag.div(class: "min-w-0 flex-1") do
          safe_join([
            tag.p(name, title: name, class: "truncate text-sm font-medium", data: { role: "name" }),
            tag.div(class: "flex min-w-0 items-center gap-1.5 text-xs text-muted-foreground group-data-[state=error]:text-destructive") do
              safe_join([
                render(UI::Icon.new(name: "check", size: :xs, class: "hidden shrink-0 text-primary group-data-[state=uploaded]:block")),
                render(UI::Icon.new(name: "circle-alert", size: :xs, class: "hidden shrink-0 group-data-[state=error]:block")),
                tag.span(size ? human_size(size) : "", class: "truncate", data: { role: "meta" }),
                tag.button(labels[:retry], type: "button", hidden: true, data: { action: "ui--file-field#retry", role: "retry" },
                                           class: "shrink-0 rounded-sm font-medium text-primary underline-offset-4 hover:underline #{UI::Base::FOCUS_RING}")
              ])
            end,
            tag.div(tag.div(class: "h-full w-0 rounded-full bg-primary transition-[width] duration-200", data: { role: "bar" }),
                    hidden: true, role: "progressbar", aria: { valuemin: 0, valuemax: 100, label: name },
                    class: "mt-1.5 h-1 overflow-hidden rounded-full bg-muted", data: { role: "progress" })
          ])
        end,
        tag.button(render(UI::Icon.new(name: "x", size: :sm)), type: "button",
                   aria: { label: labels[:remove].sub("%{name}", name.to_s) },
                   class: "flex size-8 shrink-0 items-center justify-center rounded-md text-muted-foreground " \
                          "hover:bg-accent hover:text-foreground #{UI::Base::FOCUS_RING}",
                   data: { action: "ui--file-field#remove", role: "remove" }),
        (tag.input(type: "hidden", name: signed_id_name, value: signed_id, data: { role: "signed" }) if signed_id)
      ])
    end
  end

  private

  # The units Rails' number_to_human_size uses, so a size written in the
  # browser matches the ones written here.
  def storage_units
    units = I18n.t("number.human.storage_units.units", default: {})
    { byte: (units[:byte].is_a?(Hash) ? units[:byte][:other] : units[:byte]) || "Bytes",
      kb: units[:kb] || "KB", mb: units[:mb] || "MB", gb: units[:gb] || "GB" }
  end

  # "Images", or "PDF, DOCX" for extensions, from `accept:`.
  def accepted_kinds
    return nil if @accept.blank?

    rules = @accept.split(",").map(&:strip)
    return t("ui.file_field.images", default: "Images") if rules == [ "image/*" ]

    rules.map { |rule| rule.start_with?(".") ? rule.delete_prefix(".").upcase : rule.split("/").last.upcase }.join(", ")
  end

  def bound_attachments
    return [] unless form_field? && @form.object.respond_to?(@field)

    value = @form.object.public_send(@field)
    if value.respond_to?(:attachments) then value.attachments
    elsif value.respond_to?(:attached?) && value.attached? then [ value.attachment ]
    else []
    end
  end

  # An Active Storage file is shown through the app's blob route; anything
  # else passed as `existing:` brings its own url.
  def file_url(file)
    if defined?(ActiveStorage::Attachment) && file.is_a?(ActiveStorage::Attachment)
      helpers.main_app.rails_blob_path(file)
    else
      file.try(:url)
    end
  end

  def direct_upload_url
    routes = helpers.respond_to?(:main_app) ? helpers.main_app : helpers
    routes.respond_to?(:rails_direct_uploads_url) ? routes.rails_direct_uploads_url : "/rails/active_storage/direct_uploads"
  end
end
