lineop = {}

local function magnitude(x1, y1, x2, y2)
  return math.sqrt((x1-x2)^2 + (y1-y2)^2)
end

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
    local mag = magnitude(x, y, px, py)
    length = length + mag
    px, py = x, y
  end
  return length
end

function lineop.makeEquidistantCurve(curve, dist)
  local length = lineop.curveLength(curve)
  local pieces = math.ceil(length/dist) -- number of segments
  return lineop.partitionCurve(curve, pieces, length)
end

function lineop.partitionCurve(curve, pieces, length)
  if #curve < 4 then return curve end
  local length = length or lineop.curveLength(curve)
  local dist = length/pieces -- adjust the distance slightly to fit perfectly
  local targetDist = dist
  --print(dist)
  local curX, curY = curve[1], curve[2]
  local destX, destY = curve[3], curve[4]
  local point = 1
  local newCurve = {curX, curY}
  --print("make new Curve")
  while true do
    local mag = magnitude(curX, curY, destX, destY)
    --print("current: ("..curX..", "..curY..")")
    --print("target: ("..destX..", "..destY..")")
    --print("mag is "..mag.." and will move "..targetDist)
    if (mag < targetDist) then -- will overshoot
      --print("will overshoot, point went from "..point.." to "..point+1)
      point = point + 1 -- move to next point
      if point == #curve/2 then break end
      curX, curY = destX, destY -- relocate base point to point that you overshot
      destX, destY = curve[2*point + 1], curve[2*point + 2] -- relocate target point to next point
      targetDist = targetDist - mag -- decrease target distance
    else -- record NEW POINT
      --print("move to new point, record point.")
      curX = curX + (destX - curX)/mag * targetDist; curY = curY + (destY - curY)/mag * targetDist
      table.insert(newCurve, curX); table.insert(newCurve, curY)
      targetDist = dist -- set target distance to the original distance
      --print("newCurve now has size "..#newCurve/2)
    end
  end
  if #newCurve/2 == pieces then
    --print("adding end point")
    table.insert(newCurve, curve[#curve - 1]); table.insert(newCurve, curve[#curve])
  end
  return newCurve
end

local function getBoundingBox(curve) -- returns x, y, sizex, sizey
  local minX, maxX, minY, maxY = math.huge, 0, math.huge, 0
  for i = 1, #curve, 2 do
    local x, y = curve[i], curve[i+1]
    if x < minX then minX = x end
    if x > maxX then maxX = x end
    if y < minY then minY = y end
    if y > maxY then maxY = y end
  end
  return minX, minY, maxX - minX, maxY - minY
end

local function getWeightedCenter(curve)
  local totalX, totalY = 0, 0
  for i = 1, #curve, 2 do
    totalX = totalX + curve[i]
    totalY = totalY + curve[i+1]
  end
  local points = #curve/2
  return totalX/points, totalY/points
end

local function reverseCurve(curve)
  newCurve = {}
  for i = 1, #curve, 2 do
    newCurve[i] = curve[#curve-i]
    newCurve[i+1] = curve[#curve-i+1]
  end
  return newCurve
end

function lineop.similarityTest(baseCurve, matchCurve, size)
  if #baseCurve < 4 or #matchCurve < 4 then  -- make sure curves have enough points
    return false, "bad input"
  end
  local params = {
    maxTrans = size/8, -- max translational distance allowed
    --maxProp = math.pi/6, -- max angle between proportions allowed
    --maxMag =  size/16, -- max magnitude between two curves allowed
    avgMag =  size/20, -- max average magnitude between two curves allowed
    maxLength = 0.25, -- max percent error of length
    maxScale = size/4, -- the maximum diagonal distance to scale over
  }
  print("---------------------------\nTESTING CURVE AGAINST STROKE\n---------------------------")
  local stdBaseCurve = lineop.makeEquidistantCurve(baseCurve, 5)
  local stdMatchCurve = lineop.makeEquidistantCurve(matchCurve, 5)
  local stdBX, stdBY, stdBSX, stdBSY = getBoundingBox(stdBaseCurve) -- standard base x, standard base size x
  local stdMX, stdMY, stdMSX, stdMSY = getBoundingBox(stdMatchCurve)
  local stdBCX, stdBCY, stdMCX, stdMCY = stdBX + stdBSX/2, stdBY + stdBSY/2, stdMX + stdMSX/2, stdMY + stdMSY/2 -- standard base center x

  -- TRANSLATION TEST
  local dist = magnitude(stdBCX, stdBCY, stdMCX, stdMCY)
  print("The distance is "..dist.." of acceptable "..params.maxTrans)
  if dist > params.maxTrans then
    print("FAILED TRANSLATION")
    return false, "translation"
  else
    print ("PASSED TRANSLATION")
  end

  --[[ PROPORTION TEST
  stdBAngle = math.atan2(stdBSY, stdBSX)
  stdMAngle = math.atan2(stdMSY, stdMSX)
  local angleDiff = math.abs(stdBAngle - stdMAngle)
  print("The angle btwn proportions is "..angleDiff.." of acceptable "..params.maxProp)
  if angleDiff > params.maxProp then
    print ("FAILED PROPORTION")
    return false, "proportion"
  else
    print("PASSED PROPORTION")
  end]]

  -- DIRECTION TEST
  local dotProduct = (stdBaseCurve[#stdBaseCurve-1] - stdBaseCurve[1])*(stdMatchCurve[#stdMatchCurve-1] - stdMatchCurve[1])
  + (stdBaseCurve[#stdBaseCurve] - stdBaseCurve[2])*(stdMatchCurve[#stdMatchCurve] - stdMatchCurve[2])
  print("dot product is "..dotProduct)
  if dotProduct < 0 then
    print("FAILED DOTPRODUCT")
    return false, "direction"
  else
    print("PASSED DOT PRODUCT")
  end
  -- SCALE TEST
  local scaleDist = magnitude(stdBSX, stdBSY, stdMSX, stdMSY)
  if scaleDist > params.maxScale then
    print("FAILED SCALE")
    return false, "scale"
  else
    print("PASSED SCALE")
  end

  -- SCALE AND TRANSLATE THE CURVE (NO TEST)
  local xscale, yscale
  if stdMSX == 0 then xscale = 1 else xscale = stdBSX/stdMSX end
  if stdMSY == 0 then yscale = 1 else yscale = stdBSY/stdMSY end
  for i = 1, #stdMatchCurve, 2 do
    stdMatchCurve[i] = (stdMatchCurve[i]-(stdMX + stdMSX/2)) * xscale + (stdBX + stdBSX/2)
    stdMatchCurve[i+1] = (stdMatchCurve[i+1]-(stdMY + stdMSY/2)) * yscale + (stdBY + stdBSY/2)
  end
  stdMatchCurve = lineop.makeEquidistantCurve(stdMatchCurve, 5)

  -- MAGNITUDE TEST
  local totalMag = 0
  local totalReverseMag = 0
  local numPoints =  math.min(#stdBaseCurve, #stdMatchCurve)
  for i = 1, numPoints, 2 do
    local mag = magnitude(stdBaseCurve[i], stdBaseCurve[i+1], stdMatchCurve[i], stdMatchCurve[i+1])
    local reverseMag = magnitude(stdBaseCurve[i], stdBaseCurve[i+1], stdMatchCurve[#stdMatchCurve-i], stdMatchCurve[#stdMatchCurve-i+1])
    totalMag = totalMag + mag
    totalReverseMag = totalReverseMag + reverseMag
  end
  local avgMag = totalMag/numPoints
  local avgReverseMag = totalReverseMag/numPoints
  print("The average magnitude is "..avgMag.." of acceptable "..params.avgMag.." (reverse magnitude is "..avgReverseMag..")")
  if avgReverseMag < avgMag then
    print("BACKWARDS STROKE")
    return false, "backwards"
  end
  if avgMag > params.avgMag then
    print("FAILED MAGNITUDE")
    return false, "magnitude"
  else
    print("PASSED MAGNITUDE")
  end

  --LENGTH TEST
  local lengthBase = lineop.curveLength(stdBaseCurve)
  local lengthMatch = lineop.curveLength(stdMatchCurve)
  local percentError = math.abs(lengthBase - lengthMatch)/lengthBase
  print("The pE of length is "..percentError.." of acceptable "..params.maxLength)
  if percentError > params.maxLength then
    print("FAILED LENGTH")
    return false, "length"
  else
    print ("PASSED LENGTH")
  end

  print("PASSED ALL")
  return true
end

return lineop
