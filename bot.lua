redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end

local clock = os.clock
function sleep(s)
  local delay = redis:get("bot6delay") or 5
  local randomdelay = math.random (tonumber(delay)- (tonumber(delay)/2), tonumber(delay)+ (tonumber(delay)/2))
  local t0 = clock()
  while clock() - t0 <= tonumber(randomdelay) do end
end

function get_admin ()
  if redis:get('bot6adminset') then
    return true
  else
   print("sudo id :")
    admin=io.read()
    redis:del("bot6admin")
    redis:sadd("bot6admin", admin)
    redis:set('bot6adminset',true)
  end
  return print("Owner: ".. admin)
end
function get_bot (i, adigram)
  function bot_info (i, adigram)
    redis:set("bot6id",adigram.id_)
    if adigram.first_name_ then
      redis:set("bot6fname",adigram.first_name_)
    end
    if adigram.last_name_ then
      redis:set("bot6lanme",adigram.last_name_)
    end
    redis:set("bot6num",adigram.phone_number_)
    return adigram.id_
  end
  tdcli_function ({ID = "GetMe",}, bot_info, nil)
  end
  function reload(chat_id,msg_id)
    loadfile("./bot-6.lua")()
    send(chat_id, msg_id, "حله داداش")
  end
  function is_adigram(msg)
    local var = false
    local hash = 'bot6admin'
    local user = msg.sender_user_id_
    local Adigram = redis:sismember(hash, user)
    if Adigram then
      var = true
    end
    return var
  end
  function writefile(filename, input)
    local file = io.open(filename, "w")
    file:write(input)
    file:flush()
    file:close()
    return true
  end
  function process_join(i, adigram)
    if adigram.code_ == 429 then
      local message = tostring(adigram.message_)
      local Time = message:match('%d+')
      redis:setex("bot6maxjoin", tonumber(Time), true)
    else
      redis:srem("bot6goodlinks", i.link)
      redis:sadd("bot6savedlinks", i.link)
    end
  end
  function process_link(i, adigram)
    if (adigram.is_group_ or adigram.is_supergroup_channel_) then
      redis:srem("bot6waitelinks", i.link)
      redis:sadd("bot6goodlinks", i.link)
    elseif adigram.code_ == 429 then
      local message = tostring(adigram.message_)
      local Time = message:match('%d+')
      redis:setex("bot6maxlink", tonumber(Time), true)
    else
      redis:srem("bot6waitelinks", i.link)
    end
  end
  function find_link(text)
    if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
      local text = text:gsub("t.me", "telegram.me")
      local text = text:gsub("telegram.dog", "telegram.me")
      for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
        if not redis:sismember("bot6alllinks", link) then
          redis:sadd("bot6waitelinks", link)
          redis:sadd("bot6alllinks", link)
        end
      end
    end
  end
  function add(id)
    local Id = tostring(id)
    if not redis:sismember("bot6all", id) then
      if Id:match("^(%d+)$") then
        redis:sadd("bot6users", id)
        redis:sadd("bot6all", id)
      elseif Id:match("^-100") then
        redis:sadd("bot6supergroups", id)
        redis:sadd("bot6all", id)
      else
        redis:sadd("bot6groups", id)
        redis:sadd("bot6all", id)
      end
    end
    return true
  end
  function rem(id)
    local Id = tostring(id)
    if redis:sismember("bot6all", id) then
      if Id:match("^(%d+)$") then
        redis:srem("bot6users", id)
        redis:srem("bot6all", id)
      elseif Id:match("^-100") then
        redis:srem("bot6supergroups", id)
        redis:srem("bot6all", id)
      else
        redis:srem("bot6groups", id)
        redis:srem("bot6all", id)
      end
    end
    return true
  end
  function send(chat_id, msg_id, text)
    tdcli_function ({
          ID = "SendMessage",
          chat_id_ = chat_id,
          reply_to_message_id_ = msg_id,
          disable_notification_ = 1,
          from_background_ = 1,
          reply_markup_ = nil,
          input_message_content_ = {
            ID = "InputMessageText",
            text_ = text,
            disable_web_page_preview_ = 1,
            clear_draft_ = 0,
            entities_ = {},
            parse_mode_ = {ID = "TextParseModeHTML"},
          },
          }, dl_cb, nil)
    end
    get_admin()
    function tdcli_update_callback(data)
      if data.ID == "UpdateNewMessage" then
        if not redis:get("bot6maxlink") then
          if redis:scard("bot6waitelinks") ~= 0 then
            local links = redis:smembers("bot6waitelinks")
            for x,y in pairs(links) do
              if x == 11 then redis:setex("bot6maxlink", 60, true) return end
              tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
              end
            end
          end
          if not redis:get("bot6maxjoin") then
            if redis:scard("bot6goodlinks") ~= 0 then 
              local links = redis:smembers("bot6goodlinks")
              for x,y in pairs(links) do
                local sgps = redis:scard("bot6supergroups")
                local maxsg = redis:get("bot6maxsg") or 200
                if tonumber(sgps) < tonumber(maxsg) then
                  tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
                    if x == 4 then redis:setex("bot6maxjoin", 170, true) return end
                  end
                end
              end
            end
            local msg = data.message_
            local bot_id = redis:get("bot6id") or get_bot()
            if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
              for k,v in pairs(redis:smembers('bot6admin')) do
                tdcli_function({
                      ID = "ForwardMessages",
                      chat_id_ = v,
                      from_chat_id_ = msg.chat_id_,
                      message_ids_ = {[0] = msg.id_},
                      disable_notification_ = 0,
                      from_background_ = 1
                      }, dl_cb, nil)
                end
              end
              if tostring(msg.chat_id_):match("^(%d+)") then
                if not redis:sismember("bot6all", msg.chat_id_) then
                  redis:sadd("bot6users", msg.chat_id_)
                  redis:sadd("bot6all", msg.chat_id_)
                end
              end 
              add(msg.chat_id_)
              if msg.date_ < os.time() - 150 then
                return false
              end 
              if msg.content_.ID == "MessageText" then
                local text = msg.content_.text_
                local matches
                find_link(text)
                if is_adigram(msg) then 
                  if text:match("(ta) (%d+)") or text:match ("(زم) (%d+)") then
                    local matches = text:match("%d+")
                    redis:set('bot6delay', matches)
                    return send(msg.chat_id_, msg.id_, "zeman"..tostring(matches).." .dgzsg "..tostring(matches).."tahh")
                  elseif text:match("(mx) (%d+)") or text:match("(حد) (%d+)") then
                    local matches = text:match("%d+")
                    redis:set('bot6maxsg', matches)
                    return send(msg.chat_id_, msg.id_, "حله  \n🔹 "..tostring(matches).." jjj  "..tostring(matches).."  done ")
                  elseif text:match("(set) (%d+)") or text:match("(اف م) (%d+)") then
                    local matches = text:match("%d+")
                    if redis:sismember('bot6admin', matches) then
                      return send(msg.chat_id_, msg.id_, "مدیره ک")
                    elseif redis:sismember('bot6mod', msg.sender_user_id_) then
                      return send(msg.chat_id_, msg.id_, "مدیر نیستی ک")
                    else
                      redis:sadd('bot6admin', matches)
                      redis:sadd('bot6mod', matches)
                      return send(msg.chat_id_, msg.id_, "حله")
                    end
                  elseif text:match("(re) (%d+)") or text:match("(حذ م) (%d+)") then
                    local matches = text:match("%d+")
                    if redis:sismember('bot6mod', msg.sender_user_id_) then
                      if tonumber(matches) == msg.sender_user_id_ then
                        redis:srem('bot6admin', msg.sender_user_id_)
                        redis:srem('bot6mod', msg.sender_user_id_)
                        return send(msg.chat_id_, msg.id_, "مدیر نبوده ک")
                      end
                      return send(msg.chat_id_, msg.id_, "...")
                    end
                    if redis:sismember('bot6admin', matches) then
                      if  redis:sismember('bot6admin'..msg.sender_user_id_ ,matches) then
                        return send(msg.chat_id_, msg.id_, "joonz")
                      end
                      redis:srem('bot6admin', matches)
                      redis:srem('bot6mod', matches)
                      return send(msg.chat_id_, msg.id_, "حله")
                    end
                    return send(msg.chat_id_, msg.id_, "اصلا مدیر نبوده")
                  elseif text:match("[Rr]efresh") or text:match("بازرسی") then
                    local list = {redis:smembers("bot6supergroups"),redis:smembers("bot6groups")}
                    tdcli_function({
                          ID = "SearchContacts",
                          query_ = nil,
                          limit_ = 999999999
                          }, function (i, adigram)
                          redis:set("bot6contacts", adigram.total_count_)
                        end, nil)
                      for i, v in pairs(list) do
                        for a, b in pairs(v) do 
                          tdcli_function ({
                                ID = "GetChatMember",
                                chat_id_ = b,
                                user_id_ = bot_id
                                }, function (i,adigram)
                                if  adigram.ID == "Error" then rem(i.id) 
                                end
                              end, {id=b})
                          end
                        end
                        return send(msg.chat_id_, msg.id_, "عشقمی دیگ")
                      elseif text:match("callspam") then
                        tdcli_function ({
                              ID = "SendBotStartMessage",
                              bot_user_id_ = 178220800,
                              chat_id_ = 178220800,
                              parameter_ = 'start'
                              }, dl_cb, nil) 
                        elseif text:match("reload") or text:match("ریست") then
                          return reload(msg.chat_id_,msg.id_)
                        elseif text:match("(ma) (.*)") or text:match("(ب) (.*)") then
                          local matches = text:match("ma (.*)") or text:match("ب (.*)")
                          if matches == "n" or matches == "ر" then
                            redis:set("bot6markread", true)
                            return send(msg.chat_id_, msg.id_, "حله")
                          elseif matches == "f" or matches == "خ" then
                            redis:del("bot6markread")
                            return send(msg.chat_id_, msg.id_, "خ")
                          end
                        elseif text:match("PA") or text:match("😐") then
                          local gps = redis:scard("bot6groups")
                          local sgps = redis:scard("bot6supergroups")
                          local usrs = redis:scard("bot6users")
                          local links = redis:scard("bot6savedlinks")
                          local glinks = redis:scard("bot6goodlinks")
                          local wlinks = redis:scard("bot6waitelinks")
                          local s = redis:get("bot6maxjoin") and redis:ttl("bot6maxjoin") or 0
                          local ss = redis:get("bot6maxlink") and redis:ttl("bot6maxlink") or 0
                          local delay = redis:get("bot6delay") or 5
                          local maxsg = redis:get("bot6maxsg") or 200

                          local text =   [[
          🎀 P
          
<i>Pv</i>   ]] .. tostring(usrs) .. [[   
<i>S</i>    ]] .. tostring(sgps) .. [[         
<i>G</i>    ]] .. tostring(gps) .. [[      
<i>L</i>    ]] .. tostring(links)..[[        

          ]]

                          return send(msg.chat_id_, 0, text)
                        elseif (text:match("sa") or text:match("بر") and msg.reply_to_message_id_ ~= 0) then
                          local list = redis:smembers("bot6supergroups") 
                          local id = msg.reply_to_message_id_

                          local delay = redis:get("bot6delay") or 5
                          local sgps = redis:scard("bot6supergroups")
                          local esttime = ((tonumber(delay) * tonumber(sgps)) / 60) + 1
                          send(msg.chat_id_, msg.id_, "للا : " ..tostring(sgps).. "ذه : " ..tostring(delay).. " ثانیه" .."\n⏱مدتل : " ..tostring(math.floor(esttime)).. " دقیقه" .. "\nدر سوپرگ")
                          for i, v in pairs(list) do
                            sleep(0)
                            tdcli_function({
                                  ID = "ForwardMessages",
                                  chat_id_ = v,
                                  from_chat_id_ = msg.chat_id_,
                                  message_ids_ = {[0] = id},
                                  disable_notification_ = 1,
                                  from_background_ = 1
                                  }, dl_cb, nil)
                            end
                            send(msg.chat_id_, msg.id_, "دان" ..tostring(sgps).. "درسته")
                          elseif text:match("sa (.*)") or text:match("ب (.*)") then
                            local matches = text:match("send (.*)") or text:match("ب (.*)")
                            local dir = redis:smembers("bot6supergroups")
                            local delay = redis:get("bot6delay") or 5
                            local sgps = redis:scard("bot6supergroups")
                            local esttime = ((tonumber(delay) * tonumber(sgps)) / 60) + 1
                          send(msg.chat_id_, msg.id_, "تعدادهش : " ..tostring(sgps).. "فاصلحش : " ..tostring(delay).. " ثانیه" .."..." ..tostring(math.floor(esttime)).. " دقیقه" .. "...")
                            for i, v in pairs(dir) do
                              sleep(0)
                              tdcli_function ({
                                    ID = "SendMessage",
                                    chat_id_ = v,
                                    reply_to_message_id_ = 0,
                                    disable_notification_ = 0,
                                    from_background_ = 1,
                                    reply_markup_ = nil,
                                    input_message_content_ = {
                                      ID = "InputMessageText",
                                      text_ = matches,
                                      disable_web_page_preview_ = 1,
                                      clear_draft_ = 0,
                                      entities_ = {},
                                      parse_mode_ = nil
                                    },
                                    }, dl_cb, nil)
                              end
                            send(msg.chat_id_, msg.id_, " 😁 " ..tostring(sgps).. "😁")
                            elseif text:match('(name) (.*) (.*)') or text:match('(تن ن) (.*) (.*)') then
                              local fname, lname = text:match('name "(.*)" (.*)') or text:match('تن ن "(.*)" (.*)')
                              tdcli_function ({
                                    ID = "ChangeName",
                                    first_name_ = fname,
                                    last_name_ = lname
                                    }, dl_cb, nil)
                                return send (msg.chat_id_, msg.id_, "حله")
                              elseif text:match("(user) (.*)") or text:match("(تن ی) (.*)") then
                                local matches = text:match("user (.*)") or text:match("تن ی (.*)")
                                tdcli_function ({
                                      ID = "ChangeUsername",
                                      username_ = tostring(matches)
                                      }, dl_cb, nil)
                                  return send (msg.chat_id_, msg.id_, "👌")
                                elseif text:match("(duser)") or text:match("(حذ ی)") then
                                  tdcli_function ({
                                        ID = "ChangeUsername",
                                        username_ = ""
                                        }, dl_cb, nil)
                                    return send (msg.chat_id_, msg.id_, "😐👍")
                                  elseif text:match("(sy) (.*)") or text:match("(بنال) (.*)") then
                                    local matches = text:match("sy (.*)") or text:match("بنال (.*)")
                                    return send(msg.chat_id_, 0, matches)
                                  elseif text:match("(add) (%d+)") or text:match("(ادد) (%d+)") then
                                    local matches = text:match("%d+")
                                    local list = {redis:smembers("bot6groups"),redis:smembers("bot6supergroups")}
                                    for a, b in pairs(list) do
                                      for i, v in pairs(b) do 
                                        tdcli_function ({
                                              ID = "AddChatMember",
                                              chat_id_ = v,
                                              user_id_ = matches,
                                              forward_limit_ =  50
                                              }, dl_cb, nil)
                                        end	
                                      end
                                      return send (msg.chat_id_, msg.id_, "💋💋💋💋")
                                    elseif (text:match("(love)") and not msg.forward_info_) or (text:match("(عشقم)") and not msg.forward_info_) then
                                      return tdcli_function({
                                            ID = "ForwardMessages",
                                            chat_id_ = msg.chat_id_,
                                            from_chat_id_ = msg.chat_id_,
                                            message_ids_ = {[0] = msg.id_},
                                            disable_notification_ = 0,
                                            from_background_ = 1
                                            }, dl_cb, nil)
                                      elseif text:match("(Ha)") then
                                        local txt = [[
راهنما

➖➖➖➖➖➖➖➖➖
زمان                          t   —---  ز   
➖➖➖➖➖➖➖➖➖
حداکثر گروه
                 "mx"                   " حد" 
➖➖➖➖➖➖➖➖➖
افزودن مدیر                                                                               
set    ——  اف م    
➖➖➖➖➖➖➖➖➖
حذف مدیر            
   re  —---—  حذ م      
➖➖➖➖➖➖➖➖➖
بازدیدپست ها         
ب ر      —---- ma o
                                 ب خ     —------ ma f
➖➖➖➖➖➖➖➖➖
امار                          
   P —--- ت
➖➖➖➖➖➖➖➖➖
فرستادن             
  sa —--ب-                _     
➖➖➖➖➖➖➖➖➖
بگو       
   sy —--- بنال
➖➖➖➖➖➖➖➖➖
ادد ال         
 add   —— ادد
➖➖➖➖➖➖➖➖➖
تنظیم نام
تن ن                              name
➖➖➖➖➖➖➖➖➖
تنظیم یوزر
تن ی           user
➖➖➖➖➖➖➖➖➖
حذف یوزر
حذ ی              duser

➖➖➖➖➖➖➖➖➖
راهنما
"h"                "ه"'
]]
                                        return send(msg.chat_id_,msg.id_, txt)
                                      elseif text:match("(هل)") then
                                        local txt = [[
'راهنما
➖➖➖➖➖➖➖➖➖
زمان                          t   —---  ز   
➖➖➖➖➖➖➖➖➖
حداکثر گروه
                 "mx"                   " حد" 
➖➖➖➖➖➖➖➖➖
افزودن مدیر                                                                               
set    ——  اف م    
➖➖➖➖➖➖➖➖➖
حذف مدیر            
   re  —---—  حذ م      
➖➖➖➖➖➖➖➖➖
بازدیدپست ها         
ب ر      —---- ma o
                                 ب خ     —------ ma f
➖➖➖➖➖➖➖➖➖
امار                          
   s —--- ت
➖➖➖➖➖➖➖➖➖
فرستادن             
  sa —--ب-                _     
➖➖➖➖➖➖➖➖➖
بگو       
   sy —--- بنال
➖➖➖➖➖➖➖➖➖
ادد ال         
 add   —— ادد
➖➖➖➖➖➖➖➖➖
تنظیم نام
تن ن                              name
➖➖➖➖➖➖➖➖➖
تنظیم یوزر
تن ی           user
➖➖➖➖➖➖➖➖➖
حذف یوزر
حذ ی              duser

➖➖➖➖➖➖➖➖➖
راهنما
"h"                "ه"
]]
                                        return send(msg.chat_id_,msg.id_, txt)
                                      end
                                    end		
                                  elseif msg.content_.ID == "MessageContact" then
                                    if redis:sismember("bot6admin",msg.sender_user_id_) then
                                      local first = msg.content_.contact_.first_name_ or "-"
                                      local last = msg.content_.contact_.last_name_ or "-"
                                      local phone = msg.content_.contact_.phone_number_
                                      local id = msg.content_.contact_.user_id_
                                      tdcli_function ({
                                            ID = "ImportContacts",
                                            contacts_ = {[0] = {
                                                phone_number_ = tostring(phone),
                                                first_name_ = tostring(first),
                                                last_name_ = tostring(last),
                                                user_id_ = id
                                              },
                                            },
                                            }, dl_cb, nil)
                                        return send (msg.chat_id_, msg.id_, "😋😋")
                                      end
                                    elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
                                      return rem(msg.chat_id_)
                                    elseif msg.content_.ID == "MessageChatJoinByLink" and msg.sender_user_id_ == bot_id then
                                      return add(msg.chat_id_)
                                    elseif msg.content_.ID == "MessageChatAddMembers" then
                                      for i = 0, #msg.content_.members_ do
                                        if msg.content_.members_[i].id_ == bot_id then
                                          add(msg.chat_id_)
                                        end
                                      end
                                    elseif msg.content_.caption_ then
                                      return find_link(msg.content_.caption_)
                                    end
                                    if redis:get("bot6markread") then
                                      tdcli_function ({
                                            ID = "ViewMessages",
                                            chat_id_ = msg.chat_id_,
                                            message_ids_ = {[0] = msg.id_} 
                                            }, dl_cb, nil)
                                      end
                                    elseif data.ID == "UpdateOption" and data.name_ == "my_id" then
                                      tdcli_function ({
                                            ID = "GetChats",
                                            offset_order_ = 9223372036854775807,
                                            offset_chat_id_ = 0,
                                            limit_ = 20
                                            }, dl_cb, nil)
                                      end
                                    end

