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
    @required      = required
    @disabled      = disabled
    @user_class    = binding.local_variable_get(:class)
    @html_attrs    = html_attrs
    @wrapper       = UI::FormField.new(label: label, hint: hint, error: error,
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

  def dropzone_classes
    cn(
      "relative flex cursor-pointer flex-col items-center gap-2 rounded-lg border-2 border-dashed p-6 text-center transition-colors",
      "border-input hover:bg-accent/50",
      "data-[drag=true]:border-primary data-[drag=true]:bg-primary/5",
      { "border-destructive" => wrapper.error?,
        "pointer-events-none opacity-50" => @disabled },
      @user_class
    )
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
    opts[:"aria-describedby"] = wrapper.describedby if wrapper.describedby
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
    "group relative flex min-w-0 flex-col overflow-hidden rounded-lg border bg-card text-card-foreground " \
      "data-[state=error]:border-destructive"
  end

  # One file: its thumbnail or an icon, a button to take it out, a progress
  # bar for an upload, its name and size, and the signed id that keeps it. The
  # controller fills in a blank one for each file chosen.
  def tile(name: "", size: nil, url: nil, image: false, signed_id: nil, state: "kept")
    thumb = image && url.present?
    tag.li(class: tile_classes, data: { "ui--file-field-target": "item", state: state }) do
      safe_join([
        tag.div(class: "relative aspect-square bg-muted") do
          safe_join([
            tag.img(src: url, alt: "", class: "size-full object-cover", hidden: !thumb, data: { role: "thumb" }),
            tag.span(render(UI::Icon.new(name: "file", size: :lg)), hidden: thumb, data: { role: "icon" },
                                                                    class: "absolute inset-0 flex items-center justify-center text-muted-foreground"),
            tag.button(render(UI::Icon.new(name: "x", size: :xs)), type: "button",
                       aria: { label: labels[:remove].sub("%{name}", name.to_s) },
                       class: "absolute end-1.5 top-1.5 flex size-6 items-center justify-center rounded-full border bg-background/90 " \
                              "text-foreground shadow-sm hover:bg-background #{UI::Base::FOCUS_RING}",
                       data: { action: "ui--file-field#remove", role: "remove" }),
            tag.div(tag.div(class: "h-full w-0 bg-primary transition-[width] duration-200", data: { role: "bar" }),
                    hidden: true, role: "progressbar", aria: { valuemin: 0, valuemax: 100, label: name },
                    class: "absolute inset-x-0 bottom-0 h-1 bg-foreground/10", data: { role: "progress" })
          ])
        end,
        tag.div(class: "min-w-0 p-2") do
          safe_join([
            tag.p(name, title: name, class: "truncate text-xs font-medium", data: { role: "name" }),
            tag.p(size ? human_size(size) : "", class: "line-clamp-2 text-xs text-muted-foreground group-data-[state=error]:text-destructive",
                                                data: { role: "meta" }),
            tag.button(labels[:retry], type: "button", hidden: true, data: { action: "ui--file-field#retry", role: "retry" },
                                       class: "mt-1 rounded-sm text-xs font-medium text-primary underline-offset-4 hover:underline #{UI::Base::FOCUS_RING}")
          ])
        end,
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
