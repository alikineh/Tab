redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end

local clock = os.clock
function sleep(s)
  local delay = redis:get("botBOT-IDdelay") or 5
  local randomdelay = math.random (tonumber(delay)- (tonumber(delay)/2), tonumber(delay)+ (tonumber(delay)/2))
  local t0 = clock()
  while clock() - t0 <= tonumber(randomdelay) do end
end

function get_admin ()
  if redis:get('botBOT-IDadminset') then
    return true
  else
    print("sudo id :")
    admin=io.read()
    redis:del("botBOT-IDadmin")
    redis:sadd("botBOT-IDadmin", admin)
    redis:set('botBOT-IDadminset',true)
  end
  return print("Owner: ".. admin)
end
function get_bot (i, adigram)
  function bot_info (i, adigram)
    redis:set("botBOT-IDid",adigram.id_)
    if adigram.first_name_ then
      redis:set("botBOT-IDfname",adigram.first_name_)
    end
    if adigram.last_name_ then
      redis:set("botBOT-IDlanme",adigram.last_name_)
    end
    redis:set("botBOT-IDnum",adigram.phone_number_)
    return adigram.id_
  end
  tdcli_function ({ID = "GetMe",}, bot_info, nil)
  end
  function reload(chat_id,msg_id)
    loadfile("./bot-BOT-ID.lua")()
    send(chat_id, msg_id, "حله داداش")
  end
  function is_adigram(msg)
    local var = false
    local hash = 'botBOT-IDadmin'
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
      redis:setex("botBOT-IDmaxjoin", tonumber(Time), true)
    else
      redis:srem("botBOT-IDgoodlinks", i.link)
      redis:sadd("botBOT-IDsavedlinks", i.link)
    end
  end
  function process_link(i, adigram)
    if (adigram.is_group_ or adigram.is_supergroup_channel_) then
      redis:srem("botBOT-IDwaitelinks", i.link)
      redis:sadd("botBOT-IDgoodlinks", i.link)
    elseif adigram.code_ == 429 then
      local message = tostring(adigram.message_)
      local Time = message:match('%d+')
      redis:setex("botBOT-IDmaxlink", tonumber(Time), true)
    else
      redis:srem("botBOT-IDwaitelinks", i.link)
    end
  end
  function find_link(text)
    if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
      local text = text:gsub("t.me", "telegram.me")
      local text = text:gsub("telegram.dog", "telegram.me")
      for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
        if not redis:sismember("botBOT-IDalllinks", link) then
          redis:sadd("botBOT-IDwaitelinks", link)
          redis:sadd("botBOT-IDalllinks", link)
        end
      end
    end
  end
  function add(id)
    local Id = tostring(id)
    if not redis:sismember("botBOT-IDall", id) then
      if Id:match("^(%d+)$") then
        redis:sadd("botBOT-IDusers", id)
        redis:sadd("botBOT-IDall", id)
      elseif Id:match("^-100") then
        redis:sadd("botBOT-IDsupergroups", id)
        redis:sadd("botBOT-IDall", id)
      else
        redis:sadd("botBOT-IDgroups", id)
        redis:sadd("botBOT-IDall", id)
      end
    end
    return true
  end
  function rem(id)
    local Id = tostring(id)
    if redis:sismember("botBOT-IDall", id) then
      if Id:match("^(%d+)$") then
        redis:srem("botBOT-IDusers", id)
        redis:srem("botBOT-IDall", id)
      elseif Id:match("^-100") then
        redis:srem("botBOT-IDsupergroups", id)
        redis:srem("botBOT-IDall", id)
      else
        redis:srem("botBOT-IDgroups", id)
        redis:srem("botBOT-IDall", id)
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
        if not redis:get("botBOT-IDmaxlink") then
          if redis:scard("botBOT-IDwaitelinks") ~= 0 then
            local links = redis:smembers("botBOT-IDwaitelinks")
            for x,y in pairs(links) do
              if x == 11 then redis:setex("botBOT-IDmaxlink", 60, true) return end
              tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
              end
            end
          end
          if not redis:get("botBOT-IDmaxjoin") then
            if redis:scard("botBOT-IDgoodlinks") ~= 0 then 
              local links = redis:smembers("botBOT-IDgoodlinks")
              for x,y in pairs(links) do
                local sgps = redis:scard("botBOT-IDsupergroups")
                local maxsg = redis:get("botBOT-IDmaxsg") or 200
                if tonumber(sgps) < tonumber(maxsg) then
                  tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
                    if x == 4 then redis:setex("botBOT-IDmaxjoin", 60, true) return end
                  end
                end
              end
            end
            local msg = data.message_
            local bot_id = redis:get("botBOT-IDid") or get_bot()
            if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
              for k,v in pairs(redis:smembers('botBOT-IDadmin')) do
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
                if not redis:sismember("botBOT-IDall", msg.chat_id_) then
                  redis:sadd("botBOT-IDusers", msg.chat_id_)
                  redis:sadd("botBOT-IDall", msg.chat_id_)
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
                  if text:match("(t) (%d+)") or text:match ("(ز) (%d+)") then
                    local matches = text:match("%d+")
                    redis:set('botBOT-IDdelay', matches)
                    return send(msg.chat_id_, msg.id_, "zeman"..tostring(matches).." .dgzsg "..tostring(matches).."tahh")
                  elseif text:match("(mx) (%d+)") or text:match("(حد) (%d+)") then
                    local matches = text:match("%d+")
                    redis:set('botBOT-IDmaxsg', matches)
                    return send(msg.chat_id_, msg.id_, "حله  \n🔹 "..tostring(matches).." jjj  "..tostring(matches).."  done ")
                  elseif text:match("(set) (%d+)") or text:match("(اف م) (%d+)") then
                    local matches = text:match("%d+")
                    if redis:sismember('botBOT-IDadmin', matches) then
                      return send(msg.chat_id_, msg.id_, "مدیره ک")
                    elseif redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
                      return send(msg.chat_id_, msg.id_, "مدیر نیستی ک")
                    else
                      redis:sadd('botBOT-IDadmin', matches)
                      redis:sadd('botBOT-IDmod', matches)
                      return send(msg.chat_id_, msg.id_, "حله")
                    end
                  elseif text:match("(re) (%d+)") or text:match("(حذ م) (%d+)") then
                    local matches = text:match("%d+")
                    if redis:sismember('botBOT-IDmod', msg.sender_user_id_) then
                      if tonumber(matches) == msg.sender_user_id_ then
                        redis:srem('botBOT-IDadmin', msg.sender_user_id_)
                        redis:srem('botBOT-IDmod', msg.sender_user_id_)
                        return send(msg.chat_id_, msg.id_, "مدیر نبوده ک")
                      end
                      return send(msg.chat_id_, msg.id_, "...")
                    end
                    if redis:sismember('botBOT-IDadmin', matches) then
                      if  redis:sismember('botBOT-IDadmin'..msg.sender_user_id_ ,matches) then
                        return send(msg.chat_id_, msg.id_, "joonz")
                      end
                      redis:srem('botBOT-IDadmin', matches)
                      redis:srem('botBOT-IDmod', matches)
                      return send(msg.chat_id_, msg.id_, "حله")
                    end
                    return send(msg.chat_id_, msg.id_, "اصلا مدیر نبوده")
                  elseif text:match("[Rr]efresh") or text:match("بازرسی") then
                    local list = {redis:smembers("botBOT-IDsupergroups"),redis:smembers("botBOT-IDgroups")}
                    tdcli_function({
                          ID = "SearchContacts",
                          query_ = nil,
                          limit_ = 999999999
                          }, function (i, adigram)
                          redis:set("botBOT-IDcontacts", adigram.total_count_)
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
                            redis:set("botBOT-IDmarkread", true)
                            return send(msg.chat_id_, msg.id_, "حله")
                          elseif matches == "f" or matches == "خ" then
                            redis:del("botBOT-IDmarkread")
                            return send(msg.chat_id_, msg.id_, "خ")
                          end
                        elseif text:match("stats") or text:match("ت") then
                          local gps = redis:scard("botBOT-IDgroups")
                          local sgps = redis:scard("botBOT-IDsupergroups")
                          local usrs = redis:scard("botBOT-IDusers")
                          local links = redis:scard("botBOT-IDsavedlinks")
                          local glinks = redis:scard("botBOT-IDgoodlinks")
                          local wlinks = redis:scard("botBOT-IDwaitelinks")
                          local s = redis:get("botBOT-IDmaxjoin") and redis:ttl("botBOT-IDmaxjoin") or 0
                          local ss = redis:get("botBOT-IDmaxlink") and redis:ttl("botBOT-IDmaxlink") or 0
                          local delay = redis:get("botBOT-IDdelay") or 5
                          local maxsg = redis:get("botBOT-IDmaxsg") or 200

                          local text = [[
          
]] .. tostring(usrs) .. [[ ]] .. tostring(sgps) .. [[
 ]]

                          return send(msg.chat_id_, 0, text)
                        elseif (text:match("sa") or text:match("ب") and msg.reply_to_message_id_ ~= 0) then
                          local list = redis:smembers("botBOT-IDsupergroups") 
                          local id = msg.reply_to_message_id_

                          local delay = redis:get("botBOT-IDdelay") or 5
                          local sgps = redis:scard("botBOT-IDsupergroups")
                          local esttime = ((tonumber(delay) * tonumber(sgps)) / 60) + 1
                          send(msg.chat_id_, msg.id_, "<code>🏁تعداد سوپرگروه ها : " ..tostring(sgps).. "\n⏰فاصله بین ارسال هر گروه : " ..tostring(delay).. " ثانیه" .."\n⏱مدت زمان تا اتمام ارسال : " ..tostring(math.floor(esttime)).. " دقیقه" .. "\nدر حال ارسال به همه ی سوپرگروه ها✔️</code>")
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
                            local dir = redis:smembers("botBOT-IDsupergroups")
                            local delay = redis:get("botBOT-IDdelay") or 5
                            local sgps = redis:scard("botBOT-IDsupergroups")
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
                                    local list = {redis:smembers("botBOT-IDgroups"),redis:smembers("botBOT-IDsupergroups")}
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
                                      elseif text:match("(h)") then
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
"h"                "ه"'
]]
                                        return send(msg.chat_id_,msg.id_, txt)
                                      elseif text:match("(ه)") then
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
                                    if redis:sismember("botBOT-IDadmin",msg.sender_user_id_) then
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
                                    if redis:get("botBOT-IDmarkread") then
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

