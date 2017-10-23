redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('bot1adminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("bot1admin")
    	redis:sadd("bot1admin", admin)
		redis:set('bot1adminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("bot1id",naji.id_)
		if naji.first_name_ then
			redis:set("bot1fname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("bot1lanme",naji.last_name_)
		end
		redis:set("bot1num",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-1.lua")()
	send(chat_id, msg_id, "حله")
end
function is_naji(msg)
    local var = false
	local hash = 'bot1admin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
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
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot1maxjoin", tonumber(Time), true)
	else
		redis:srem("bot1goodlinks", i.link)
		redis:sadd("bot1savedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		redis:srem("bot1waitelinks", i.link)
		redis:sadd("bot1goodlinks", i.link)
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot1maxlink", tonumber(Time), true)
	else
		redis:srem("bot1waitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("bot1alllinks", link) then
				redis:sadd("bot1waitelinks", link)
				redis:sadd("bot1alllinks", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("bot1users", id)
			redis:sadd("bot1all", id)
		elseif Id:match("^-100") then
			redis:sadd("bot1supergroups", id)
			redis:sadd("bot1all", id)
		else
			redis:sadd("bot1groups", id)
			redis:sadd("bot1all", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("bot1all", id) then
		if Id:match("^(%d+)$") then
			redis:srem("bot1users", id)
			redis:srem("bot1all", id)
		elseif Id:match("^-100") then
			redis:srem("bot1supergroups", id)
			redis:srem("bot1all", id)
		else
			redis:srem("bot1groups", id)
			redis:srem("bot1all", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
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
redis:set("bot1start", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if not redis:get("bot1maxlink") then
			if redis:scard("bot1waitelinks") ~= 0 then
				local links = redis:smembers("bot1waitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("bot1maxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if not redis:get("bot1maxjoin") then
			if redis:scard("bot1goodlinks") ~= 0 then
				local links = redis:smembers("bot1goodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("bot1maxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("bot1id") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "3⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال شده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('bot1admin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("bot1all", msg.chat_id_) then
				redis:sadd("bot1users", msg.chat_id_)
				redis:sadd("bot1all", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("bot1link") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذ ل) (.*)$") then
					local matches = text:match("^حذ ل (.*)$")
					if matches == "عضو" then
						redis:del("bot1goodlinks")
						return send(msg.chat_id_, msg.id_, "پاک شد.")
					elseif matches == "تا" then
						redis:del("bot1waitelinks")
						return send(msg.chat_id_, msg.id_, "اوک.")
					elseif matches == "ذخی " then
						redis:del("bot1savedlinks")
						return send(msg.chat_id_, msg.id_, "لینک های ذخیره")
					end
				elseif text:match("^(حذ کل ل) (.*)$") then
					local matches = text:match("^حذ کل ل (.*)$")
					if matches == "عضو" then
						local list = redis:smembers("bot1goodlinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "کلی ")
						redis:del("bot1goodlinks")
					elseif matches == "تا" then
						local list = redis:smembers("bot1waitelinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "در انتظار حل")
						redis:del("bot1waitelinks")
					elseif matches == "ذخی" then
						local list = redis:smembers("bot1savedlinks")
						for i, v in ipairs(list) do
							redis:srem("bot1alllinks", v)
						end
						send(msg.chat_id_, msg.id_, "اونم ک")
						redis:del("bot1savedlinks")
					end
				elseif text:match("^(تو) (.*)$") then
					local matches = text:match("^تو (.*)$")
					if matches == "عضو" then	
						redis:set("bot1maxjoin", true)
						redis:set("bot1offjoin", true)
						return send(msg.chat_id_, msg.id_, "متوق ف ش")
					elseif matches == "تا ل" then	
						redis:set("bot1maxlink", true)
						redis:set("bot1offlink", true)
						return send(msg.chat_id_, msg.id_, "متوفق ش")
					elseif matches == "شنا س ل " then	
						redis:del("bot1link")
						return send(msg.chat_id_, msg.id_, "جوون")
					elseif matches == "افز مخ" then	
						redis:del("bot1savecontacts")
						return send(msg.chat_id_, msg.id_, "متوقف")
					end
				elseif text:match("^(شر) (.*)$") then
					local matches = text:match("^شر (.*)$")
					if matches == "عضو" then	
						redis:del("bot1maxjoin")
						redis:del("bot1offjoin")
						return send(msg.chat_id_, msg.id_, "فعالللل")
					elseif matches == "تا ل" then	
						redis:del("bot1maxlink")
						redis:del("bot1offlink")
						return send(msg.chat_id_, msg.id_, "فعاللللل")
					elseif matches == "شنا س ل" then	
						redis:set("bot1link", true)
						return send(msg.chat_id_, msg.id_, "جوون")
					elseif matches == "افز مخ" then	
						redis:set("bot1savecontacts", true)
						return send(msg.chat_id_, msg.id_, "اونم خ")
					end
				elseif text:match("^(اف م) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1admin', matches) then
						return send(msg.chat_id_, msg.id_, "مدیره ک")
					elseif redis:sismember('bot1mod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "مدیر نیستی ک")
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "حله")
					end
				elseif text:match("^(اف مد) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "مدیر نیستی ککک")
					end
					if redis:sismember('bot1mod', matches) then
						redis:srem("bot1mod",matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "حله.")
					elseif redis:sismember('bot1admin',matches) then
						return send(msg.chat_id_, msg.id_, 'بوده کد.')
					else
						redis:sadd('bot1admin', matches)
						redis:sadd('bot1admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "اوکشد.")
					end
				elseif text:match("^(حذ مد) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot1mod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('bot1admin', msg.sender_user_id_)
								redis:srem('bot1mod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شتید.")
						end
						return send(msg.chat_id_, msg.id_, "ارید.")
					end
					if redis:sismember('bot1admin', matches) then
						if  redis:sismember('bot1admin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "ش.")
						end
						redis:srem('bot1admin', matches)
						redis:srem('bot1mod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مدیریت خلع شد.")
					end
					return send(msg.chat_id_, msg.id_, "کشد.")
				elseif text:match("^(رفرش)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "+++")
				elseif text:match("ریبوتتتت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^برو$") then
					io.popen("git fetch --all && git reset --hard origin/persian && git pull origin persian && chmod +x bot"):read("*all")
					local text,ok = io.open("bot.lua",'r'):read('*a'):gsub("BOT%-ID",1)
					io.open("bot-1.lua",'w'):write(text):close()
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^همگام $") then
					local botid = 1 - 1
					redis:sunionstore("bot1all","tabchi:"..tostring(botid)..":all")
					redis:sunionstore("bot1users","tabchi:"..tostring(botid)..":pvis")
					redis:sunionstore("bot1groups","tabchi:"..tostring(botid)..":groups")
					redis:sunionstore("bot1supergroups","tabchi:"..tostring(botid)..":channels")
					redis:sunionstore("bot1savedlinks","tabchi:"..tostring(botid)..":savedlinks")
					return send(msg.chat_id_, msg.id_, "ی شماره "..tostring(botid).." انجاشد.")
				elseif text:match("^(لی) (.*)$") then
					local matches = text:match("^لی (.*)$")
					local naji
					if matches == "مخا" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخا : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("bot1_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "bot1_contacts.txt"},
								caption_ = "بات 1"}
							}, dl_cb, nil)
							return io.popen("rm -rf bot1_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پا خو" then
						local text = "لیتشون"
						local answers = redis:smembers("bot1answerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("bot1answers", v)) .. "\n"
						end
						if redis:scard('bot1answerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "بلاک" then
						naji = "bot1blockedusers"
					elseif matches == "پیوییی" then
						naji = "bot1users"
					elseif matches == "گپ" then
						naji = "bot1groups"
					elseif matches == "سوپرگپ" then
						naji = "bot1supergroups"
					elseif matches == "لی" then
						naji = "bot1savedlinks"
					elseif matches == "مد" then
						naji = "bot1admin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لی "..tostring(matches).." ت"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وض ) (.*)$") then
					local matches = text:match("^وض (.*)$")
					if matches == "رو" then
						redis:set("bot1markread", true)
						return send(msg.chat_id_, msg.id_, "شده ✔️✔️\n</i>(تیک دوم فعال)")
					elseif matches == "خا" then
						redis:del("bot1markread")
						return send(msg.chat_id_, msg.id_, "oیبلیلی")
					end 
				elseif text:match("^(اف پ) (.*)$") then
					local matches = text:match("^اف پ (.*)$")
					if matches == "رو" then
						redis:set("bot1addmsg", true)
						return send(msg.chat_id_, msg.id_, "فع")
					elseif matches == "خا" then
						redis:del("bot1addmsg")
						return send(msg.chat_id_, msg.id_, "غیر ف")
					end
				elseif text:match("^(اف ش) (.*)$") then
					local matches = text:match("اف ش (.*)$")
					if matches == "رو" then
						redis:set("bot1addcontact", true)
						return send(msg.chat_id_, msg.id_, "ارسالاللایسل")
					elseif matches == "خا" then
						redis:del("bot1addcontact")
						return send(msg.chat_id_, msg.id_, "حلخ")
					end
				elseif text:match("^(تن پمخا) (.*)") then
					local matches = text:match("^تن پمخا (.*)")
					redis:set("bot1addmsgtext", matches)
					return send(msg.chat_id_, msg.id_, " ثبت  شد :\n🔹 "..matches.." 🔹")
				elseif text:match('^(تن ج) "(.*)" (.*)') then
					local txt, answer = text:match('^تن ج "(.*)" (.*)')
					redis:hset("bot1answers", txt, answer)
					redis:sadd("bot1answerslist", txt)
					return send(msg.chat_id_, msg.id_, "ای |" .. tostring(txt) .. " | تنظیمبه :\n" .. tostring(answer))
				elseif text:match("^(حذ ج) (.*)") then
					local matches = text:match("^حذ ج (.*)")
					redis:hdel("bot1answers", matches)
					redis:srem("bot1answerslist", matches)
					return send(msg.chat_id_, msg.id_, "ای | " .. tostring(matches) .. " | از لیسار پاک شد.")
				elseif text:match("^(پا خ) (.*)$") then
					local matches = text:match("^پا خ (.*)$")
					if matches == "رو" then
						redis:set("bot1autoanswer", true)
						return send(msg.chat_id_, 0, "412763")
					elseif matches == "خا" then
						redis:del("bot1autoanswer")
						return send(msg.chat_id_, 0, "4664")
					end
				elseif text:match("^(تا ر)$")then
					local list = {redis:smembers("bot1supergroups"),redis:smembers("bot1groups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("bot1contacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"شماره  1 < انجام شد.")
				elseif text:match("^(وضعیت)$") then
					local s =  redis:get("bot1offjoin") and 0 or redis:get("bot1maxjoin") and redis:ttl("bot1maxjoin") or 0
					local ss = redis:get("bot1offlink") and 0 or redis:get("bot1maxlink") and redis:ttl("bot1maxlink") or 0
					local msgadd = redis:get("bot1addmsg") and "✅️" or "⛔️"
					local numadd = redis:get("bot1addcontact") and "✅️" or "⛔️"
					local txtadd = redis:get("bot1addmsgtext") or  "اد‌دی گلم خصوصی پیام بده"
					local autoanswer = redis:get("bot1autoanswer") and "✅️" or "⛔️"
					local wlinks = redis:scard("bot1waitelinks")
					local glinks = redis:scard("bot1goodlinks")
					local links = redis:scard("bot1savedlinks")
					local offjoin = redis:get("bot1offjoin") and "⛔️" or "✅️"
					local offlink = redis:get("bot1offlink") and "⛔️" or "✅️"
					local nlink = redis:get("bot1link") and "✅️" or "⛔️"
					local contacts = redis:get("bot1savecontacts") and "✅️" or "⛔️"
					local txt = "⚙️  <i>وضعیت اجرایی تبلیغ‌گر</i><code> 1</code>  ⛓\n\n"..tostring(offjoin).."<code> عضویت خودکار </code>🚀\n"..tostring(offlink).."<code> تایید لینک خودکار </code>🚦\n"..tostring(nlink).."<code> تشخیص لینک های عضویت </code>🎯\n"..tostring(contacts).."<code> افزودن خودکار مخاطبین </code>➕\n" .. tostring(autoanswer) .."<code> حالت پاسخگویی خودکار 🗣 </code>\n" .. tostring(numadd) .. "<code> افزودن مخاطب با شماره 📞 </code>\n" .. tostring(msgadd) .. "<code> افزودن مخاطب با پیام 🗞</code>\n〰〰〰ا〰〰〰\n📄<code> پیام افزودن مخاطب :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n<code>📁 لینک های ذخیره شده : </code><b>" .. tostring(links) .. "</b>\n<code>⏲	لینک های در انتظار عضویت : </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>ثانیه تا عضویت مجدد</code>\n<code>❄️ لینک های در انتظار تایید : </code><b>" .. tostring(wlinks) .. "</b>\n🕑️   <b>" .. tostring(ss) .. " </b><code>ثانیه تا تایید لینک مجدد</code>\n\n 😼 سازنده : @i_naji"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(P)$") or text:match("^(😐)$") then
					local gps = redis:scard("bot1groups")
					local sgps = redis:scard("bot1supergroups")
					local usrs = redis:scard("bot1users")
					local links = redis:scard("bot1savedlinks")
					local glinks = redis:scard("bot1goodlinks")
					local wlinks = redis:scard("bot1waitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("bot1contacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("bot1contacts")
					local text = [[
					
]] .. tostring(usrs) .. [[ ]] .. tostring(sgps) .. [[    

 
					]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(بف ) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^بف (.*)$")
					local naji
					if matches:match("^(پ)") then
						naji = "bot1users"
					elseif matches:match("^(گ)$") then
						naji = "bot1groups"
					elseif matches:match("^(سو)$") then
						naji = "bot1supergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					for i, v in pairs(list) do
						tdcli_function({
							ID = "ForwardMessages",
							chat_id_ = v,
							from_chat_id_ = msg.chat_id_,
							message_ids_ = {[0] = id},
							disable_notification_ = 1,
							from_background_ = 1
						}, dl_cb, nil)
					end
					return send(msg.chat_id_, msg.id_, "چچچچچ")
				elseif text:match("^(بف سو) (.*)") then
					local matches = text:match("^بف سو (.*)")
					local dir = redis:smembers("bot1supergroups")
					for i, v in pairs(dir) do
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
                    			return send(msg.chat_id_, msg.id_, "چچچچچچ")
				elseif text:match("^(بلاک) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("bot1blockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "حله")
				elseif text:match("^(رف بلاک) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("bot1blockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "البل")	
				elseif text:match('^(تن ن) "(.*)" (.*)') then
					local fname, lname = text:match('^تن ن "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "یبل>")
				elseif text:match("^(تن ی) (.*)") then
					local matches = text:match("^تن ی (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, 'حله')
				elseif text:match("^(حذ ن)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, 'ااااا')
				elseif text:match('^(بفر) "(.*)" (.*)') then
					local id, txt = text:match('^بفر "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "اوک")
				elseif text:match("^(بنال) (.*)") then
					local matches = text:match("^بنال (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(مای)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(لیو) (.*)$") then
					local matches = text:match("^لیو (.*)$") 	
					send(msg.chat_id_, msg.id_, 'ارج شد')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(اف ه) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("bot1groups"),redis:smembers("bot1supergroups")}
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
					return send(msg.chat_id_, msg.id_, "تتبلال>")
				elseif (text:match("^(عشقم)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(هل)$") then
					local txt = 'بلغیاا'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(لیو)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
		    				   chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(اف ه)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("bot1users"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "الان")
					end
				end
			end
			if redis:sismember("bot1answerslist", text) then
				if redis:get("bot1autoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("bot1answers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("bot1savecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("bot1addedcontacts",id) then
				redis:sadd("bot1addedcontacts",id)
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
				if redis:get("bot1addcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("bot1fname")
					local lnasme = redis:get("bot1lname") or ""
					local num = redis:get("bot1num")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("bot1addmsg") then
				local answer = redis:get("bot1addmsgtext") or "م بده"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("bot1link"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("bot1markread") then
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
			limit_ = 1000
		}, dl_cb, nil)
	end
end
