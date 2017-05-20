parser = require("parser")
lineop = require("lineop")

screen = "none"
kanji_screen = {}
kanji = {}
bgtile = love.graphics.newImage("img/bgtile.png")

function love.load()
  file = love.filesystem.read("svg/0611b.svg")
  parser.loadSVG(file)
  kanji = parser.renderKanji(0, 0, 400, 400, 3)
  screen = "kanji"
end

function love.update()

end

function drawKanji(kanji, stroke)
  stroke = stroke or #kanji
  local limit =  math.min(stroke, #kanji)
  love.graphics.setColor(0, 0, 0)
  love.graphics.setLineStyle("smooth")
  love.graphics.setLineWidth(4)
  love.graphics.setLineJoin("bevel")
  for i = 1, limit do
    local stroke = kanji[i]
    for _, curve in pairs(stroke) do
      love.graphics.line(curve)
    end
  end
  love.graphics.setColor(255,0,0)
  for i = 1, limit do
    local stroke = kanji[i]
    local curve = lineop.makeEquidistantCurve(lineop.strokeToCurve(stroke), 20)
    for i = 1, #curve, 2 do
      love.graphics.circle("fill", curve[i], curve[i+1], 4)
    end
  end
end

function love.draw()
  if screen == "none" then return end
  if screen == "kanji" then
    love.graphics.setBackgroundColor(248, 205, 162)
    love.graphics.setColor(245, 245, 245)
    love.graphics.rectangle("fill", 0, 0, 400, 400)
    drawKanji(kanji)
  else
  end
end
