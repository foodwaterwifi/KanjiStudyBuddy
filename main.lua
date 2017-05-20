parser = require("parser")
lineop = require("lineop")

gui = {
  screen = "none",
  practice = {
    kanjiArea = {x = 100, y = 100, size = 600},
    currentKanji = {},
    brush = {
      drawing = false,
      curve = {}
    }
  },
}

kanji = {}
bgtile = love.graphics.newImage("img/bgtile.png")

function love.load()
  file = love.filesystem.read("svg/0611b.svg")
  parser.loadSVG(file)
  gui.practice.currentKanji = parser.renderKanji(gui.practice.kanjiArea.x, gui.practice.kanjiArea.y, gui.practice.kanjiArea.size, gui.practice.kanjiArea.size, 5)
  gui.screen = "practice"
end

function inBox(x, y, bx, by, bxsize, bysize)
  return (x >= bx and y >= by and x <= bx + bxsize and y <= by + bysize)
end

function dist(x1, y1, x2, y2)
  return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

function love.mousepressed(x, y, button, isTouch)
  if gui.screen == "none" then return end
  if gui.screen == "practice" then
    local brush = gui.practice.brush
    if inBox(x, y, gui.practice.kanjiArea.x, gui.practice.kanjiArea.y, gui.practice.kanjiArea.size, gui.practice.kanjiArea.size) then
      brush.curve = {x, y} -- start the curve
      brush.drawing = true
    end
  end
end

function love.mousereleased(x, y, button, isTouch)
  if gui.screen == "none" then return end
  if gui.screen == "practice" then
    local brush = gui.practice.brush
    if brush.drawing then
      brush.drawing = false
      -- do stuff here
    end
  end
end

function love.mousemoved(x, y, dx, dy, isTouch)
  if gui.screen == "none" then return end
  if gui.screen == "practice" then
    local brush = gui.practice.brush
    if brush.drawing then
      if dist(x, y, brush.curve[#brush.curve-1], brush.curve[#brush.curve]) >= 5 then
        table.insert(brush.curve, x); table.insert(brush.curve, y)
      end
    end
  end
end

function love.update()

end

function drawRoundLine(points, width)
  width = width or 4
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(width)
  love.graphics.setLineJoin("bevel")
  love.graphics.line(points)
  love.graphics.circle("fill", points[1], points[2], width/2)
  love.graphics.circle("fill", points[#points-1], points[#points], width/2)
end

function drawKanji(kanji, stroke)
  stroke = stroke or #kanji
  local limit =  math.min(stroke, #kanji)
  love.graphics.setColor(0, 0, 0)
  for i = 1, limit do
    local stroke = kanji[i]
    for _, curve in pairs(stroke) do
      drawRoundLine(curve)
    end
  end
  --[[
  love.graphics.setColor(255,0,0)
  for i = 1, limit do
    local stroke = kanji[i]
    local curve = lineop.makeEquidistantCurve(lineop.strokeToCurve(stroke), 20)
    for i = 1, #curve, 2 do
      love.graphics.circle("fill", curve[i], curve[i+1], 4)
    end
  end]]
end

function love.draw()
  if gui.screen == "none" then return end
  if gui.screen == "practice" then
    love.graphics.setBackgroundColor(248, 205, 162)
    love.graphics.setColor(245, 245, 245)
    love.graphics.rectangle("fill", gui.practice.kanjiArea.x, gui.practice.kanjiArea.y, gui.practice.kanjiArea.size, gui.practice.kanjiArea.size)
    drawKanji(gui.practice.currentKanji)
    if #gui.practice.brush.curve >= 4 then
      love.graphics.setColor(0, 200, 200)
      drawRoundLine(gui.practice.brush.curve)
    end
  end
end
