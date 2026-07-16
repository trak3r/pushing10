module IconHelper
  def icon(name, size: 20)
    data = ICONS[name] or return ""
    paths = data.map { |d| %(<path d="#{d}"/>) }.join
    %(<svg viewBox="0 0 24 24" width="#{size}" height="#{size}" stroke="currentColor" stroke-width="1.8" fill="none" stroke-linecap="round" stroke-linejoin="round" style="display:inline-block;vertical-align:middle;flex-shrink:0">#{paths}</svg>).html_safe
  end

  ICONS = {
    plane: [
      "M12 2C12 2 15 9 21 9C22 9 22 11 21 11L15 11L15 16L18 19L17 20L12 17L7 20L6 19L9 16L9 11L3 11C2 11 2 9 3 9C9 9 12 2 12 2Z",
    ],
    airport: [
      "M4 10L20 10L20 21L4 21Z",
      "M9 4L15 4L15 10L9 10Z",
      "M12 2L12 4",
    ],
    coin: [
      "M12 22C17.5 22 22 17.5 22 12C22 6.5 17.5 2 12 2C6.5 2 2 6.5 2 12C2 17.5 6.5 22 12 22Z",
    ],
    passenger: [
      "M12 12C14.2 12 16 10.2 16 8C16 5.8 14.2 4 12 4C9.8 4 8 5.8 8 8C8 10.2 9.8 12 12 12Z",
      "M4 21C4 16.6 7.6 13 12 13C16.4 13 20 16.6 20 21",
    ],
  }.freeze
end
