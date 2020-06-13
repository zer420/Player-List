local ui_enable = gui.Checkbox(gui.Reference("Misc", "General", "Extra"), "playerlist.enable", "Player List", false);
local ui_win = gui.Window("playerlist", "Player List", 150, 150, 516, 422);


local ui_tab = {
    {"Player", gui.Groupbox(ui_win, "Select a Player", 16, 56, 234), gui.Groupbox(ui_win, "Player Options", 266, 56, 234), gui.Groupbox(ui_win, "Player Information", 266, 224, 234),},
    {"Misc", gui.Groupbox(ui_win, "Playstyle", 16, 56, 234), gui.Groupbox(ui_win, "Priority Settings", 266, 56, 234),},
    {1, {170,30,30,255}, {220,60,40,255}, {255,255,255,255}, {255,255,255,40}, f = draw.CreateFont("Calibri Bold", 20, 20),},
};
local ntab = (#ui_tab - 1); local function ui_setup() for i = 1, ntab do if i ~= ui_tab[ntab + 1][1] then for j = 2, #ui_tab[i] do ui_tab[i][j]:SetInvisible(true); end; end; end; end;
ui_setup(); local function ui_tab_selector(x1, y1, x2, y2, active)
    draw.SetFont(ui_tab[ntab + 1].f); local mx, my = input.GetMousePos(); local size = ((x2 - x1) / (ntab)); local offset = x1;
    for i = 1, (ntab) do
        if i == ui_tab[ntab + 1][1] then draw.Color(unpack(ui_tab[ntab + 1][3])) else draw.Color(unpack(ui_tab[ntab + 1][2])) end;
        draw.FilledRect(offset, y1, offset + size, y2); local xtxt, ytxt = draw.GetTextSize(ui_tab[i][1]);
        draw.Color(unpack(ui_tab[ntab + 1][4])); draw.Text((offset + (size / 2) - (xtxt / 2)), (y1 + 20 - (ytxt / 2)), ui_tab[i][1]);
        if mx >= offset and mx < offset + size and my >= y1 and my < y2 then
            draw.Color(unpack(ui_tab[ntab + 1][5])); draw.FilledRect(offset, y1, offset + size, y2);
            if input.IsButtonPressed("mouse1") then
                for j = 2, #ui_tab[ui_tab[ntab + 1][1]] do ui_tab[ui_tab[ntab + 1][1]][j]:SetInvisible(true); end; ui_tab[ntab + 1][1] = i;
                for j = 2, #ui_tab[i] do ui_tab[i][j]:SetInvisible(false); end;
end; end; offset = offset + size; end; end;
local ui_tab_select = gui.Custom(ui_win, "tab", 0, 0, 516, 40, ui_tab_selector); -- way cleaner than buttons


local ui_plist = gui.Listbox(ui_tab[1][2], "players", 257);
ui_plist:SetWidth(202);

local ui_misc = {
    gui.Combobox(ui_tab[2][2], "playstyle.mode", "Mode", "Rage", "Semirage"),
    gui.Checkbox(ui_tab[2][3], "priority.enable", "Enable Priority", false),
    gui.Slider(ui_tab[2][3], "priority.fov", "FOV Override", 2, 1, 10, 1);
};

local semi_rbot = gui.Checkbox(ui_tab[1][3], "ragebot", "Use Ragebot", false);
local priority_order = gui.Slider(ui_tab[1][3], "priority", "Priority Order", 10, 1, 10, 1);
local ui_option_multi_ref = gui.Multibox(ui_tab[1][3], "Additional Features");
local ui_player_option = {
    gui.Checkbox(ui_option_multi_ref, "bodyaim", "Force Bodyaim", false),
    gui.Checkbox(ui_option_multi_ref, "safepoint", "Force Safepoint", false),
};

local kdr = gui.Text(ui_tab[1][4], "Kill/Death Ratio");

ui_enable:SetDescription("Show the player list window.");
ui_misc[1]:SetDescription("Select your playstyle for suiting features.");
ui_misc[2]:SetDescription("It will cause a lock so be aware.");
semi_rbot:SetDescription("Use the ragebot instead of legitbot.");
priority_order:SetDescription("Lower is higher priority, 10 is disabled.");
ui_option_multi_ref:SetDescription("Features to control the ragebot per players.")


local p_list = {
    temp = {},
    p = {}, -- settings
    ref = { -- used in various places
        name = {},
        uid = {},
        index = {},
    },
};

local function SaveCfg(uid)
    p_list.p[uid].rbot = semi_rbot:GetValue();
    p_list.p[uid].prio = priority_order:GetValue();
    p_list.p[uid].bodyaim = ui_player_option[1]:GetValue();
    p_list.p[uid].safepoint = ui_player_option[2]:GetValue();
end;

local function LoadCfg(uid)
    semi_rbot:SetValue(p_list.p[uid].rbot);
    priority_order:SetValue(p_list.p[uid].prio);
    ui_player_option[1]:SetValue(p_list.p[uid].bodyaim);
    ui_player_option[2]:SetValue(p_list.p[uid].safepoint);
end;

local ui_allow_updt = false;

local function Reset()
    ui_allow_updt = false;    
    ui_plist:SetOptions();
    kdr:SetText("Kill/Death Ratio");
    p_list.p = {};
    p_list.temp = {};
    p_list.ref = {name = {},uid = {},index = {},};
end;

callbacks.Register("FireGameEvent", "ResetOnEnd", function(e)
    if e:GetName() == "cs_win_panel_match" then
        Reset();
    end;
end);
client.AllowListener("cs_win_panel_match");

local ui_cache = {opti, list, map,};
callbacks.Register("Draw", "UIHandler", function()
    ui_cache.opti = ui_enable:GetValue() and gui.Reference("Menu"):IsActive()
    ui_win:SetActive(ui_cache.opti);

    if ui_cache.opti == false then return; end;

    ui_win:SetHeight(ui_tab[3][1] == 1 and 422 or 250);

    if ui_misc[1]:GetValue() == 0 then ui_cache.opti = true; else ui_cache.opti = false; end;
    semi_rbot:SetInvisible(ui_cache.opti);
    ui_option_multi_ref:SetInvisible(not ui_cache.opti);
    priority_order:SetDisabled(ui_cache.opti == false and semi_rbot:GetValue() == false or ui_misc[2]:GetValue() == false);
    ui_tab[1][4]:SetPosY(ui_cache.opti == true and 252 or 236);

    -- reset ui while not in game or new game
    if engine.GetMapName() == "" or engine.GetMapName() ~= ui_cache.map then 
        ui_cache.map = engine.GetMapName();
        Reset();
    end;

    -- update ui for the selected player
    if ui_allow_updt == true then
        if ui_cache.list ~= (ui_plist:GetValue() + 1) then
            ui_cache.list = (ui_plist:GetValue() + 1);
            LoadCfg(p_list.ref.uid[ui_cache.list]);
        end;
        SaveCfg(p_list.ref.uid[ui_cache.list]);
        local temp_kdr = {
            k = tonumber(entities.GetPlayerResources():GetPropInt("m_iKills", entities.GetByUserID(p_list.ref.uid[ui_cache.list]):GetIndex())),
            d = tonumber(entities.GetPlayerResources():GetPropInt("m_iDeaths", entities.GetByUserID(p_list.ref.uid[ui_cache.list]):GetIndex())),
        };
        kdr:SetText(temp_kdr.d > 0 and "Kill/Death Ratio = " .. (math.ceil((temp_kdr.k / temp_kdr.d) * 10) * 0.1) or "Kill/Death Ratio = " ..  temp_kdr.k);
    end;
end);

local openprofile = gui.Button(ui_tab[1][4], "Open Steam Profile In Overlay", function()
    if ui_allow_updt == true then
        if client.GetPlayerInfo(p_list.ref.index[ui_cache.list])["IsBot"] == false then
            -- clean af way to get profile
            local link = [[("http://steamcommunity.com/profiles/765611]] .. 97960265728 + client.GetPlayerInfo(p_list.ref.index[ui_cache.list])["SteamID"] .. [[/")]];
            panorama.RunScript("SteamOverlayAPI.OpenURL" .. link);
end; end; end);
openprofile:SetWidth(202);

callbacks.Register("CreateMove", "UpdatePlayerList", function()
    p_list.temp = entities.FindByClass("CCSPlayer");
    for i, j in pairs(p_list.temp) do
        local uid = client.GetPlayerInfo(j:GetIndex())["UserID"];
        -- create an entry in the table
        if p_list.p[uid] == nil then
            p_list.p[uid] = {rbot = false, prio = 10, bodyaim = false, safepoint = false,};
        end;
        p_list.ref.name[i] = j:GetName();
        p_list.ref.uid[i] = uid;
        p_list.ref.index[i] = j:GetIndex();
    end;
    ui_plist:SetOptions(unpack(p_list.ref.name));
    ui_allow_updt = true;
end);

local weapon_info = {
    [1] = "hpistol",[2] = "pistol",[3] = "pistol",[4] = "pistol",[7] = "rifle",[8] = "rifle", [9] = "sniper", [10] = "rifle",[11] = "asniper",[13] = "rifle", [14] = "lmg", [16] = "rifle",
    [17] = "smg",[19] = "smg",[23] = "smg",[24] = "smg",[25] = "shotgun",[26] = "smg", [27] = "shotgun", [28] = "lmg",[29] = "shotgun", [30] = "pistol", [32] = "pistol",[33] = "smg",
    [34] = "smg", [35] = "shotgun", [36] = "pistol",[38] = "asniper",[39] = "rifle", [40] = "scout", [60] = "rifle",[61] = "pistol",[63] = "pistol", [64] = "hpistol",
};

local target_i = nil; callbacks.Register("AimbotTarget", function(e) target_i = e:GetIndex(); end);

local aimbot_cache = {target_c, wep_type, applied = false, bodyaim, sphead, spbody, splimbs};

local function ResetCfg()
    gui.SetValue(string.format("rbot.hitscan.mode.%s.bodyaim", aimbot_cache.wep_type), aimbot_cache.bodyaim);
    gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshot", aimbot_cache.wep_type), aimbot_cache.sphead);
    gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshotbody", aimbot_cache.wep_type), aimbot_cache.spbody);
    gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshotlimbs", aimbot_cache.wep_type), aimbot_cache.splimbs);

    aimbot_cache.applied = false;
end;

local ent_vis, vis_next_check = {}, 1;
callbacks.Register("CreateMove", "GetVisiblePlayers", function(ucmd)
    -- check every 6 ticks for every visible enemies
    if vis_next_check < ucmd.tick_count then
        local lp = entities.GetLocalPlayer();
        for i, p in pairs(p_list.temp) do
            if p:GetTeamNumber() ~= lp:GetTeamNumber() and p:IsAlive() == true then
                local vis = engine.TraceLine(lp:GetAbsOrigin() + lp:GetPropVector("localdata", "m_vecViewOffset[0]"), p:GetHitboxPosition(3), 0x1).contents == 0;
                ent_vis[client.GetPlayerInfo(p:GetIndex())["UserID"]] = vis;
            else
                ent_vis[client.GetPlayerInfo(p:GetIndex())["UserID"]] = false;
            end;
        end;
        vis_next_check = ucmd.tick_count + 6;
    end;
end);

local priority_set, priority_toset, prev_fov = false, false, 180;

local function ResetPrio()
    gui.SetValue("rbot.aim.target.fov", prev_fov);
    priority_set = false;
end;

callbacks.Register("CreateMove", "Apply", function()
    -- get highest priority target which is visible
    local prio_vis = {11, nil, allowed,};
    for i, p in pairs(ent_vis) do
        if  p_list.p[i] ~= nil then
            if ui_misc[1]:GetValue() == 1 and p_list.p[i].rbot == true then
                prio_vis.allowed = true;
            elseif ui_misc[1]:GetValue() == 0 then
                prio_vis.allowed = true;
            end;
            if prio_vis.allowed == true then
                if p == true then
                    if prio_vis[1] > p_list.p[i].prio then
                        prio_vis[1] = p_list.p[i].prio;
                        prio_vis[2] = i;
                    end;
                end;
            end;
        end;
    end;

    local wep, lp = weapon_info[entities.GetLocalPlayer():GetWeaponID()], entities.GetLocalPlayer();

    if ui_misc[1]:GetValue() == 0 and gui.GetValue("rbot.master") == true then

        if target_i ~= nil and wep ~= nil and aimbot_cache.applied == false then
            -- cache then apply per target corrections 
            aimbot_cache.target_c = target_i;
            aimbot_cache.wep_type = wep;
            aimbot_cache.bodyaim = gui.GetValue(string.format("rbot.hitscan.mode.%s.bodyaim", wep));
            aimbot_cache.sphead = gui.GetValue(string.format("rbot.hitscan.mode.%s.delayshot", wep));
            aimbot_cache.spbody = gui.GetValue(string.format("rbot.hitscan.mode.%s.delayshotbody", wep));
            aimbot_cache.splimbs = gui.GetValue(string.format("rbot.hitscan.mode.%s.delayshotlimbs", wep));

            if p_list.p[client.GetPlayerInfo(target_i)["UserID"]].bodyaim == true then
                gui.SetValue(string.format("rbot.hitscan.mode.%s.bodyaim", wep), 1);
            end;
            if p_list.p[client.GetPlayerInfo(target_i)["UserID"]].safepoint == true then
                gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshot", wep), 1);
                gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshotbody", wep), 1);
                gui.SetValue(string.format("rbot.hitscan.mode.%s.delayshotlimbs", wep), 1);
            end;

            aimbot_cache.applied = true;

        elseif aimbot_cache.applied == true then
            if target_i == nil or wep == nil then
                ResetCfg();
            elseif target_i ~= aimbot_cache.target_c or wep ~= aimbot_cache.wep_type then
                ResetCfg();
            end;
        end;    

    elseif ui_misc[1]:GetValue() == 1 then
        -- per players ragebot
        if prio_vis[2] ~= nil then
            gui.SetValue("rbot.master", true);
        else
            gui.SetValue("lbot.master", true);
        end;    
    end;

    if gui.GetValue("rbot.aim.target.fov") ~= ui_misc[3]:GetValue() then
        prev_fov = gui.GetValue("rbot.aim.target.fov");
    end;

    if ui_misc[2]:GetValue() == true then
        -- flicks to the target, set FOV to 3 & enable lock while checking if it's the right one
        if prio_vis[1] < 10 and wep ~= nil then
            if entities.GetByUserID(prio_vis[2]):IsAlive() == false then
                ResetPrio();
                return;
            end;

            if priority_toset == true then
                local lp_pos = (lp:GetAbsOrigin() + lp:GetPropVector("localdata", "m_vecViewOffset[0]"));
                local t_pos = entities.GetByUserID(prio_vis[2]):GetHitboxPosition(5);

                engine.SetViewAngles((t_pos - lp_pos):Angles());
                gui.SetValue("rbot.aim.target.fov", ui_misc[3]:GetValue());
                gui.SetValue("rbot.aim.target.lock", true);

                priority_set = true;
                priority_toset = false;
            end;

            if target_i == entities.GetByUserID(prio_vis[2]):GetIndex() then
                priority_toset = false
                ResetPrio()
            else
                priority_toset = true
            end;

        elseif priority_set == true then
            ResetPrio();
        end;
    end;

end);
