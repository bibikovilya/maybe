module SyncsHelper
  def sync_status_badge(sync, size: :xs)
    status_config = {
      pending: { color: "gray-500", text_color: "text-secondary", label: t(".pending"), animate: false },
      syncing: { color: "orange-500", text_color: "text-orange-500", label: t(".syncing"), animate: true },
      failed: { color: "red-500", text_color: "text-red-500", label: t(".failed"), animate: false },
      stale: { color: "yellow-500", text_color: "text-yellow-500", label: t(".stale"), animate: false },
      completed: { color: "green-500", text_color: "text-green-500", label: t(".completed"), animate: false }
    }

    status = sync.status.to_sym
    config = status_config[status]
    return nil unless config

    animate_class = config[:animate] ? "animate-pulse" : ""
    size_classes = size == :sm ? "px-2 py-1 text-sm" : "px-1 py text-xs"

    content_tag(:span,
      config[:label],
      class: "#{size_classes} rounded-full bg-#{config[:color]}/5 #{config[:text_color]} border border-alpha-black-50 #{animate_class}".strip
    )
  end
end
