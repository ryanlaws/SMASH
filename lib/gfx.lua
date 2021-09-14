local FN = include('SMASH/lib/function') 

local g = {
  leaks = {}
}
-- some methods stolen from 
-- northern-information/athenaeum/lib/graphics.lua

local strike_sharpness = nil
local strike_level = nil

local event_last_pos = 0

local add_ripple_q = FN.make_q()
g.ripples = {}

function g.text(x, y, s, l)
  g.safe_level(l)
  screen.move(x, y)
  screen.text_right(s)
  screen.stroke()
end

function g.circle(x, y, r, l, filled)
  screen.level(math.floor(l) or 15)
  screen.circle(x, y, r)
  if filled then 
    screen.fill()
  else
    screen.stroke()
  end
end

function g.up()
  screen.clear()
end

function g.down()
  screen.update()
end

function g.draw_strikes(side)
  if strike_sharpness == nil then 
    return 
  end

  g.draw_ears(strike_sharpness, strike_level, side)

  strike_level = math.floor(strike_level * ((1 - strike_sharpness) ^ 3))
  if strike_level < 1 then 
    strike_sharpness = nil
  end
end

function g.draw_ear(pos, size, level)
  g.circle(pos, 32, size, level)
end

function g.draw_ears(sharpness, level, side)
  sharpness = math.floor(sharpness * 10)
  radius = math.ceil((sharpness ^ 2) / 3.8) 

  l_open = side < 3
  r_open = side > 1

  if side < 3 then
    g.draw_ear(66 - (sharpness * 3), radius, level)
  end

  if side > 1 then
    g.draw_ear(62 + (sharpness * 3), radius, level)
  end
end

function g.draw_sharpness(sharpness, side)
  local level = (sharpness < 0.4) and (5 - (sharpness * 10)) or 1
  g.draw_ears(sharpness, level, side)
end

function g.safe_level(l)
  screen.level(type(l) == 'number' and 
    math.min(math.max(math.floor(l), 0), 15) or 
    15)
end

function g.line(x1, y1, x2, y2, l)
  g.safe_level(l)
  screen.move(x1, y1)
  screen.line(x2, y2)
  screen.stroke()
end

function g.draw_needle(tick_pos, tick_length)
  radians = (tick_pos / tick_length - 0.25) * 2 * math.pi
  g.circle(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32),
    1, 8, true)
end

function g.reset_seq()
  print('(gfx) seq reset')
  event_last_pos = 0
end

function g.add_event_ripple()
  add_ripple_q.nq(function (pos, len)
    print('adding ripple at '..pos..' of len '..len)
    pos = (pos + len - 1) % len / len
    print('calculated ripple at '..pos)
    g.ripples[#g.ripples+1] = { pos=pos, size=1, level=math.random(6, 10) }
  end)
end

function g.draw_event_ripple(ripple)
  radians = (ripple.pos - 0.25) * 2 * math.pi
  g.circle(
    math.floor(math.cos(radians) * 32 + 64),
    math.floor(math.sin(radians) * 32 + 32),
    ripple.size,
    ripple.level
  )
  ripple.size = ripple.size + math.random(1,3)
  ripple.level = ripple.level - math.random(1,2)
end

function g.draw_ngon(events, tick_length, last_index)
  if events == nil or #events < 2 then
    return -- that's a nah!
  end

  screen.level(last_index == 1 and 5 or 1)
  screen.move(64, 1)

  for i=2,#events do
    radians = (events[i][1] / tick_length - 0.25) * 2 * math.pi
    x = math.floor(math.cos(radians) * 32 + 64)
    y = math.floor(math.sin(radians) * 32 + 32)
    screen.line(x, y)
    screen.stroke()
    screen.move(x, y)
    screen.level(last_index == i and 5 or 1)
  end

  screen.line(64, 1)
  screen.stroke()
end

function g.draw_ripples()
  while #g.ripples > 10 do
    table.remove(g.ripples,1)
  end

  g.remove = {}
  for i = 1,#g.ripples do
    g.draw_event_ripple(g.ripples[i])
    if g.ripples[i].size > 10 then
      g.remove[#g.remove+1] = i
    end
  end

  for i = #g.remove, 1, -1 do
    table.remove(g.ripples, g.remove[i])
  end
end

function g.draw_pos(where, last_event_pos, tick_pos)
  -- bullshit
  screen.aa(0)
  screen.font_face(2)
  screen.font_size(8)

  if last_event_pos == nil then last_event_pos = '(nil)' end
  if event_last_pos == nil then event_last_pos = '(nil)' end
  if tick_pos == nil then tick_pos = '(nil)' end
  if where == 'l' then
    screen.move(4, 8)
    screen.text('t '..tick_pos..', elp '..event_last_pos..', lep '..last_event_pos)
  elseif where == 'r' then
    screen.move(124, 16)
    screen.text_right('t '..tick_pos..', elp '..event_last_pos..', lep '..last_event_pos)
  end

  -- reset
  screen.aa(0)
  screen.font_face(2)
  screen.font_size(16)
end

function g.draw_seq(events, event_pos, tick_pos, tick_length)
  g.draw_ngon(events, tick_length, event_last_pos)
  g.draw_needle(tick_pos - 1, tick_length)

  while event_pos ~= event_last_pos do
    event_last_pos = (event_last_pos ~= nil) and (event_last_pos % #events + 1) or 1
  end

  add_ripple_q.fire(tick_pos, tick_length)

  g.draw_ripples()
end

function g.init()
  screen.aa(0)
  screen.font_face(2)
  screen.font_size(16)
end

function g.draw_status(recording, armed, event_count)
  if not armed and not recording and event_count == 0 then
    -- nothing happened yet
  elseif armed then
    g.circle(9, 56, 4, 8, false)
  elseif recording then
    g.circle(9, 56, 4, 8, true)
  elseif event_count > 0 then
    screen.level(8)
    screen.move(5, 52)
    screen.line(14, 56)
    screen.line(5, 60)
    screen.fill()
  end
  screen.stroke()
end

function g.draw_speed(tempo)
  g.safe_level(8)
  screen.move(123, 59)
  screen.text_right(tempo)
  screen.stroke()
end

function g.add_new_leak()
  g.leaks[#g.leaks + 1] = {
    x = math.random(128),
    y = math.random(64),
    level = math.random(1, 8)
  }
end

-- collapse values from 0.001 - 1 to scaled random boolean 
function g.chance(x)
  x = x ^ (1/6)
  x = math.floor(x // 0.01)
  x = math.random(0, x)
  return x > 29.8 and x < 100
end

function g.draw_leak(leak)
  if g.chance(leak) then
    g.add_new_leak()
  end

  removes = {}

  for i = 1,#g.leaks do
    g.safe_level(g.leaks[i].level)
    screen.pixel(g.leaks[i].x, g.leaks[i].y)
    screen.fill()

    delta_y = math.floor((math.random() * 1.32) ^ 5)
    g.leaks[i].y = g.leaks[i].y + delta_y
    if delta_y > 0 or math.random() > 0.6 then
      g.leaks[i].level = g.leaks[i].level - 1
    end

    if g.leaks[i].level < 1 then
      removes[#removes + 1] = i
    end
  end

  for i = #removes,1,-1 do
    table.remove(g.leaks, removes[i])
  end
end

function g.draw_noise()
  noise = params:get("smash_noise")
  noise_str = ''
  max_noise = 1
  if noise >= 0.1 then max_noise = 2 end
  if noise >= 0.2 then max_noise = 3 end
  if noise >= 0.3 then max_noise = 5 end
  if noise >= 0.5 then max_noise = 9 end
  if noise >= 0.8 then max_noise = 15 end

  for i=1,256 do
    noise_str = noise_str .. string.char(g.chance(noise) and math.random(1, max_noise) or 0)
  end

  screen.poke(1, 32, 128, 2, noise_str)
end

function g.draw_gain()
  g.safe_level(params:get('smash_gain') * 5)
  screen.rect(1, 1, 127, 63)
  screen.stroke()

  g.safe_level(params:get('smash_gain'))
  screen.rect(2, 2, 125, 61)
  screen.stroke()
end

function g.strike(sharpness, from_seq)
  strike_sharpness = sharpness
  strike_level = 15

  if from_seq then
    --g.add_event_ripple((tick_pos + tick_length - 1) % tick_length / tick_length)
    g.add_event_ripple()
  end
end

return g
