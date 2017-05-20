parser = {}

svg = ""
width, height = 0, 0
currentRender = nil

function parser.loadSVG(text)
  svg = text
  local pattern = "<svg.-width=\"(%d-)\""
  width = tonumber(svg:match(pattern))
  pattern = "<svg.-height=\"(%d-)\""
  height = tonumber(svg:match(pattern))
  currentRender = nil
end

function getPaths()
  local pathTable = {}
  local pattern = "<path.- d=\"(.-)\""
  for path in svg:gmatch(pattern) do
    table.insert(pathTable, path)
  end
  return pathTable
end

function makeBezierStroke(path)
  -- First, pull out the numbers and make the path.
  local data = {}
  local pattern = "(%a?)(%-?%d+" .. "%.?" .. "%d*)"
  for command, number in path:gmatch(pattern) do
    if command ~= "" then table.insert(data, command) end
    table.insert(data, tonumber(number))
  end
  -- Now, construct the stroke
  local stroke = {}
  local currentX, currentY
  for i = 1, #data do
    if data[i] == "M" then
      currentX, currentY = data[i+1], data[i+2]
      i = i + 2
    elseif data[i] == "C" then -- absolute
      table.insert(stroke, love.math.newBezierCurve(
        currentX, currentY,
        data[i+1], data[i+2],
        data[i+3], data[i+4],
        data[i+5], data[i+6]
      ))
      currentX, currentY = data[i+5], data[i+6]
      i = i + 6
    elseif data[i] == "c" then -- relative to current
      table.insert(stroke, love.math.newBezierCurve(
        currentX, currentY,
        currentX + data[i+1], currentY + data[i+2],
        currentX + data[i+3], currentY + data[i+4],
        currentX + data[i+5], currentY + data[i+6]
      ))
      currentX, currentY = currentX + data[i+5], currentY + data[i+6]
    end
  end

  return stroke
end

function makeKanji()
  print("making kanji")
  kanji = {}
  paths = getPaths()
  for i, path in pairs(paths) do
    table.insert(kanji,
      makeBezierStroke(path)
    )
  end
  print("made kanji")
  return kanji
end

function parser.renderKanji(x, y, w, h, depth)
  depth = depth or 10
  local kanji = makeKanji()
  local renderedKanji = {}
  for _, stroke in pairs(kanji) do
    local renderedStroke = {}
    for _, curve in pairs(stroke) do
      local renderedCurve = curve:render(depth)
      for i = 1, #renderedCurve, 2 do
        renderedCurve[i] = renderedCurve[i]/width *w + x
        renderedCurve[i+1] = renderedCurve[i+1]/height *h + y
      end
      table.insert(renderedStroke, renderedCurve)
    end
    table.insert(renderedKanji, renderedStroke)
  end
  return renderedKanji
end

return parser
