lineop = {}

function lineop.strokeToCurve(stroke)
  local newCurve = {}
  for _, curve in pairs(stroke) do
    for _, v in pairs(curve) do
      table.insert(newCurve, v)
    end
  end
  return newCurve
end

function lineop.curveLength(curve)
  local px, py = curve[1], curve[2]
  local length = 0
  for i = 3, #curve, 2 do
    local x, y = curve[i], curve[i+1]
    local mag = math.sqrt((x-px)^2+(y-py)^2)
    length = length + mag
    px, py = x, y
  end
  return length
end

function lineop.makeEquidistantCurve(curve, dist)
  local length = lineop.curveLength(curve)
  local count = math.ceil(length/dist) -- number of segments
  dist = length/count -- adjust the distance slightly to fit perfectly
  local px, py = curve[1], curve[2]
  local newCurve = {px, py}
  local currentDist = 0
  for i = 3, #curve, 2 do
    local x, y = curve[i], curve[i+1]
    local mag = math.sqrt((x-px)^2+(y-py)^2)
    currentDist = currentDist + mag
    if currentDist > dist then -- We want the curve to be equidistant, so stop here
      local newX = px + (x-px)/mag*(mag - currentDist + dist) -- split the curve at a point that is exactly the right distance
      local newY = py + (y-py)/mag*(mag - currentDist + dist)
      table.insert(newCurve, newX); table.insert(newCurve, newY) -- put this new point in our completed curve table
      px, py = newX, newY -- make this new point the previous point and step back the loop
      count = count - 1; currentDist = 0; i = i - 2
    else
      px, py = x, y
    end
  end
  if count == 1 then table.insert(newCurve, curve[#curve - 1]); table.insert(newCurve, curve[#curve]) end
  return newCurve
end

return lineop
