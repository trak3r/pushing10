module PixelArtHelper
  PIXEL = 4

  PALETTE = {
    "." => "transparent",
    "b" => "#e0e8f0",
    "g" => "#00c8a0",
    "y" => "#f5c842",
    "r" => "#e85555",
    "d" => "#0b1a2e",
    "s" => "#1a3a5a",
    "w" => "#ffffff",
    "o" => "#e8a040",
    "p" => "#d4a0e8",
    "c" => "#7ec8e3",
    "t" => "#4a9ebd",
    "h" => "#c87850",
    "k" => "#2a5a3a",
  }

  CLOTHING_COLORS = [
    "#e85555", "#f5c842", "#00c8a0", "#d4a0e8",
    "#e8a040", "#7ec8e3", "#4a9ebd", "#e0e8f0",
  ]

  SPRITES = {
    plane: [
      "....bbbb....",
      "...bbbbbb...",
      "..bbbbbbbb..",
      ".bbbbbbbbbb.",
      "bbbbbbbbbbbb",
      "bbbb..bb..bb",
      "bbbbbbbbbbbb",
      ".bbbbbbbbbb.",
      "..bbbbbbbb..",
      "...bbbbbb...",
      "....bbbb....",
    ],
    plane_small: [
      "..bbbb..",
      ".bbbbbb.",
      "bbbbbbbb",
      "..bbbb..",
      "..bb....",
    ],
    airport: [
      "..yy..",
      "..bw..",
      "..yy..",
      ".y..y.",
      ".y..y.",
      "yyyyyy",
    ],
    coin: [
      ".ggg.",
      "ggbgg",
      "ggbgg",
      ".ggg.",
    ],
    passenger: [
      "...y...",
      "..ywy..",
      "...y...",
      "..sss..",
      ".s...s.",
      "..ppp..",
      ".p...p.",
      "..ppp..",
      "...p...",
    ],
    face: [
      ".o.",
      ".w.",
      "w.w",
    ],
    cloud: [
      "..cc..",
      ".cccc.",
      "cccccc",
      "cccccc",
      ".cccc.",
      "..cc..",
    ],
    airline_logo: [
      "....gggg....",
      "...gggggg...",
      "..gggggggg..",
      ".gggggggggg.",
      "gggggggggggg",
      "..gggggg....",
    ],
    window: [
      "....",
      ".ss.",
      ".ss.",
      "....",
    ],
    compass: [
      "..g..",
      ".ggg.",
      "gy.yg",
      ".ggg.",
      "..g..",
    ],
  }

  def pixel_art(name, size: nil, colors: {})
    grid = SPRITES[name] or return ""
    pixel_size = size || PIXEL
    h = grid.length * pixel_size
    w = grid[0].length * pixel_size

    rects = grid.each_with_index.flat_map do |row, y|
      row.chars.each_with_index.map do |ch, x|
        color = colors[ch.to_sym] || PALETTE[ch] or next
        next if color == "transparent"
        %(<rect x="#{x * pixel_size}" y="#{y * pixel_size}" width="#{pixel_size}" height="#{pixel_size}" fill="#{color}"/>)
      end
    end.compact.join

    %(<svg viewBox="0 0 #{w} #{h}" width="#{w}" height="#{h}" style="display:inline-block;vertical-align:middle">#{rects}</svg>).html_safe
  end

  def passenger_colors(passenger)
    idx = passenger.id
    {
      s: CLOTHING_COLORS[idx % CLOTHING_COLORS.length],
      p: CLOTHING_COLORS[(idx / 3) % CLOTHING_COLORS.length],
    }
  end
end