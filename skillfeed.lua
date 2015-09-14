dofile("urlcode.lua")
dofile("table_show.lua")

local url_count = 0
local tries = 0
local item_type = os.getenv('item_type')
local item_value = os.getenv('item_value')

local downloaded = {}
local addedtolist = {}

downloaded["https://fast.wistia.com/btnfr'.indexOf(c)>-1)d+=l[c],r++;else if(c=="] = true
downloaded["https://fast.wistia.com/g,"] = true

read_file = function(file)
  if file then
    local f = assert(io.open(file))
    local data = f:read("*all")
    f:close()
    return data
  else
    return ""
  end
end

wget.callbacks.download_child_p = function(urlpos, parent, depth, start_url_parsed, iri, verdict, reason)
  local url = urlpos["url"]["url"]
  local html = urlpos["link_expect_html"]
  
  if downloaded[url] == true or addedtolist[url] == true then
    return false
  end
  
  if (downloaded[url] ~= true or addedtolist[url] ~= true) then
    if (downloaded[url] ~= true and addedtolist[url] ~= true) and ((string.match(url, "/courses/"..item_value) and not string.match(url, "/courses/"..item_value.."[0-9]")) or string.match(url, "^https?://fast%.wistia%.com/") or string.match(url, "^https?://distillery%.wistia%.com/") or string.match(url, "^https?://embed%-ssl%.wistia%.com/") or html == 0) then
      addedtolist[url] = true
      return true
    else
      return false
    end
  end
end


wget.callbacks.get_urls = function(file, url, is_css, iri)
  local urls = {}
  local html = nil
  
  local function check(url)
    if (downloaded[url] ~= true and addedtolist[url] ~= true) and ((string.match(url, "/courses/"..item_value) and not string.match(url, "/courses/"..item_value.."[0-9]")) or string.match(url, "^https?://fast%.wistia%.com/") or string.match(url, "^https?://distillery%.wistia%.com/") or string.match(url, "^https?://pipedream%.wistia%.com/") or string.match(url, "^https?://embed%-ssl%.wistia%.com/") or string.match(url, "cloudfront%.net") or string.match(url, "optimizely%.com") or string.match(url, "amazonaws%.com")) then
      if string.match(url, "&amp;") then
        table.insert(urls, { url=string.gsub(url, "&amp;", "&") })
        addedtolist[url] = true
        addedtolist[string.gsub(url, "&amp;", "&")] = true
      else
        table.insert(urls, { url=url })
        addedtolist[url] = true
      end
    end
  end

  local function checknewurl(newurl, url)
    if string.match(newurl, "^https?://") then
      check(newurl)
    elseif string.match(newurl, "^//") then
      check("http:"..newurl)
    elseif string.match(newurl, "^/") then
      check(string.match(url, "^(https?://[^/]+)")..newurl)
    end
  end
  
  if (string.match(url, "/courses/"..item_value) and not string.match(url, "/courses/"..item_value.."[0-9]")) or string.match(url, "^https?://fast%.wistia%.com/") then
    html = read_file(file)
    for newurl in string.gmatch(html, '"([^"]+)"') do
      checknewurl(newurl, url)
    end
    for newurl in string.gmatch(html, "'([^']+)'") do
      checknewurl(newurl, url)
    end
    if string.match(html, "Wistia%.embed%(") then
      check("https://fast.wistia.com/embed/medias/"..string.match(html, 'Wistia%.embed%("([^"]+)",')..".json?callback=wistiajson1")
      check("https://fast.wistia.com/embed/medias/"..string.match(html, 'Wistia%.embed%("([^"]+)",')..".json")
      check("https://fast.wistia.com/embed/iframe/"..string.match(html, 'Wistia%.embed%("([^"]+)",'))
    end
    for datapart in string.gmatch(html, "{([^{]-)}") do
      if string.match(datapart, '"ext":"([^"]+)"') == "mp4" and not (string.match(datapart, '"slug":"([^"]+)"') == "original" or string.match(datapart, '"type":"([^"]+)"') == "preview" or string.match(datapart, '"type":"([^"]+)"') == "original") then
        check(string.match(datapart, '"url":"(https?://.-)%.bin"').."/file.mp4")
      elseif string.match(datapart, '"ext":"([^"]+)"') == "jpg" then
        check(string.match(datapart, '"url":"(https?://.-)%.bin"')..".jpg")
        check(string.match(datapart, '"url":"(https?://.-)%.bin"')..".jpg?image_crop_resized=640x360")
        check(string.match(datapart, '"url":"(https?://.-)%.bin"')..".jpg?image_crop_resized=960x540")
        check(string.match(datapart, '"url":"(https?://.-)%.bin"')..".jpg?image_crop_resized=1280x720")
      end
    end
  end
  
  return urls
end
  

wget.callbacks.httploop_result = function(url, err, http_stat)
  -- NEW for 2014: Slightly more verbose messages because people keep
  -- complaining that it's not moving or not working
  status_code = http_stat["statcode"]
  
  url_count = url_count + 1
  io.stdout:write(url_count .. "=" .. status_code .. " " .. url["url"] .. ".  \n")
  io.stdout:flush()

  if (status_code >= 200 and status_code <= 399) then
    if string.match(url.url, "https://") then
      local newurl = string.gsub(url.url, "https://", "http://")
      downloaded[newurl] = true
    else
      downloaded[url.url] = true
    end
  end

  local function errorcode(sleep, numtries, action)
    io.stdout:write("\nServer returned "..http_stat.statcode..". Sleeping.\n")
    io.stdout:flush()
    os.execute("sleep "..tostring(sleep))
    tries = tries + 1
    if tries >= numtries then
      io.stdout:write("\nI give up...\n")
      io.stdout:flush()
      tries = 0
      if action == "abort" then
        return wget.actions.ABORT
      elseif action == "exit" then
        return wget.actions.EXIT
      end
    else
      return wget.actions.CONTINUE
    end
  end
  
  if status_code >= 500 or
    (status_code >= 400 and status_code ~= 404 and status_code ~= 403 and status_code ~= 400) then
    errorcode(1, 5, "abort")
  elseif status_code == 0 then
    errorcode(10, 5, "abort")
  end

  tries = 0

  local sleep_time = 0

  if sleep_time > 0.001 then
    os.execute("sleep " .. sleep_time)
  end

  return wget.actions.NOTHING
end
