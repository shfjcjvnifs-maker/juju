local DA_HOOD_PLACE_ID = 2788229376

local TARGETS = {
    ["juju"] = {
        name = "juju",
        urls = {
            "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/refs/heads/main/juju.lua",
            "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/juju.lua",
            "https://cdn.jsdelivr.net/gh/shfjcjvnifs-maker/juju@main/juju.lua",
        },
        files = { "juju.lua" },
    },
    ["jujuHC"] = {
        name = "jujuHC",
        urls = {
            "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/refs/heads/main/jujuHC.lua",
            "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/jujuHC.lua",
            "https://cdn.jsdelivr.net/gh/shfjcjvnifs-maker/juju@main/jujuHC.lua",
        },
        files = { "jujuHC.lua" },
    },
}

local __loader_ui = nil

-- > ( target picker )

local function pick_target_ui()
    local env = (type(getgenv) == "function" and getgenv()) or _G

    if env then
        local chosen = env["juju_loader_target"]
        if chosen == "juju" or chosen == "jujuHC" then
            return chosen
        end
        if env["juju_loader_pick"] == false then
            return nil
        end
    end

    if type(__loader_ui) ~= "function" then
        return nil
    end

    local ok_mod, mod = pcall(__loader_ui)

    if not ok_mod or type(mod) ~= "table" or type(mod.create) ~= "function" then
        return nil
    end

    local ok_ui, loader = pcall(mod.create, {
        fade_duration = 0.28,
    })

    if not ok_ui or type(loader) ~= "table" then
        return nil
    end

    local root = loader.root
    local outer = root and root:FindFirstChild("OuterFrame")
    local inside = outer and outer:FindFirstChild("Inside")
    local right_side = inside and inside:FindFirstChild("RightSide")
    local section_border = right_side and right_side:FindFirstChild("SectionBorder")
    local section_inside = section_border and section_border:FindFirstChild("SectionInside")

    if not inside or not section_inside then
        pcall(function()
            loader:destroy()
        end)

        return nil
    end

    -- The picker is the same juju.beta shell as the loader; hide only the
    -- progress pieces and use the sidebar for the build tabs.
    local slider_holder = section_inside:FindFirstChild("LoadingSliderHolder")
    if slider_holder then
        slider_holder.Visible = false
    end

    local tab_loader = inside:FindFirstChild("TabLoader")
    if tab_loader then
        tab_loader.Visible = false
    end

    local tab_line = inside:FindFirstChild("TabLine")
    if tab_line then
        tab_line.Visible = false
    end

    local drag_overlay = root and root:FindFirstChild("DragOverlay")
    if drag_overlay then
        drag_overlay.Active = false
        drag_overlay.Visible = false
    end

    local tween_service = game:GetService("TweenService")
    local state = {
        picked = nil,
        closed = false,
    }

    local buttons = {}

    local function tween(object, info, properties)
        local animation = tween_service:Create(object, info, properties)
        animation:Play()
        return animation
    end

    local function add_fade(inst, prop, shown, hidden)
        if not inst or not prop then
            return
        end

        if type(loader.add_fade_target) == "function" then
            pcall(loader.add_fade_target, loader, inst, prop, shown or 0, hidden or 1)
        else
            inst[prop] = shown or 0
        end
    end

    local function apply_font(label, bold)
        local font = loader.font

        if font then
            label.FontFace = font
        elseif bold then
            label.Font = Enum.Font.GothamBold
        else
            label.Font = Enum.Font.Gotham
        end
    end

    local picker_objects = {}

    local title = Instance.new("TextLabel")
    title.Name = "PickerTitle"
    title.Position = UDim2.fromOffset(0, 112)
    title.Size = UDim2.new(1, 0, 0, 16)
    title.BackgroundTransparency = 1
    title.Text = "select build"
    title.TextColor3 = Color3.fromRGB(197, 197, 197)
    title.TextSize = 12
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.TextTransparency = 1
    title.ZIndex = 9
    apply_font(title, true)
    title.Parent = section_inside
    add_fade(title, "TextTransparency", 0)
    picker_objects[#picker_objects + 1] = title

    local status = Instance.new("TextLabel")
    status.Name = "PickerStatus"
    status.Position = UDim2.fromOffset(0, 132)
    status.Size = UDim2.new(1, 0, 0, 12)
    status.BackgroundTransparency = 1
    status.Text = "choose a build"
    status.TextColor3 = Color3.fromRGB(75, 72, 72)
    status.TextSize = 11
    status.TextXAlignment = Enum.TextXAlignment.Center
    status.TextYAlignment = Enum.TextYAlignment.Center
    status.TextTransparency = 1
    status.ZIndex = 9
    apply_font(status, false)
    status.Parent = section_inside
    add_fade(status, "TextTransparency", 0)
    picker_objects[#picker_objects + 1] = status

    local choices = {
        { name = "juju", value = "juju", hint = "main Da Hood" },
        { name = "jujuHC", value = "jujuHC", hint = "universal" },
        { name = "auto", value = "auto", hint = "route by place" },
    }

    for index, choice in ipairs(choices) do
        local tab = Instance.new("TextButton")
        tab.Name = "Pick_" .. choice.value
        tab.Position = UDim2.fromOffset(0, 73 + (index - 1) * 20)
        tab.Size = UDim2.fromOffset(100, 18)
        tab.BackgroundTransparency = 1
        tab.BorderSizePixel = 0
        tab.Text = ""
        tab.AutoButtonColor = false
        tab.Selectable = false
        tab.Active = true
        tab.ZIndex = 7
        tab.Parent = inside
        picker_objects[#picker_objects + 1] = tab

        local bar = Instance.new("Frame")
        bar.Name = "PickLine"
        bar.Position = UDim2.fromOffset(0, 1)
        bar.Size = UDim2.fromOffset(1, 12)
        bar.BackgroundColor3 = Color3.fromRGB(154, 213, 222)
        bar.BackgroundTransparency = 1
        bar.BorderSizePixel = 0
        bar.ZIndex = 8
        bar.Parent = tab

        local label = Instance.new("TextLabel")
        label.Name = "PickLabel"
        label.Position = UDim2.fromOffset(20, 0)
        label.Size = UDim2.fromOffset(74, 14)
        label.BackgroundTransparency = 1
        label.Text = choice.name
        label.TextColor3 = Color3.fromRGB(197, 197, 197)
        label.TextSize = 12
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Center
        label.TextTransparency = 1
        label.Active = false
        label.ZIndex = 8
        apply_font(label, false)
        label.Parent = tab

        add_fade(label, "TextTransparency", 0)
        add_fade(bar, "BackgroundTransparency", 1, 1)

        buttons[#buttons + 1] = {
            button = tab,
            bar = bar,
            label = label,
            value = choice.value,
        }

        tab.MouseEnter:Connect(function()
            if state.closed or state.picked then
                return
            end

            status.Text = choice.hint

            pcall(function()
                tween(bar, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.5,
                })
                tween(label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(255, 255, 255),
                })
                tween(status, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(197, 197, 197),
                })
            end)
        end)

        tab.MouseLeave:Connect(function()
            if state.closed or state.picked then
                return
            end

            status.Text = "choose a build"

            pcall(function()
                tween(bar, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 1,
                })
                tween(label, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(197, 197, 197),
                })
                tween(status, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(75, 72, 72),
                })
            end)
        end)

        tab.MouseButton1Click:Connect(function()
            if state.picked or state.closed then
                return
            end

            state.picked = choice.value

            for _, entry in ipairs(buttons) do
                entry.button.Active = false

                if entry.value == choice.value then
                    entry.bar.BackgroundTransparency = 0.5
                    entry.label.TextColor3 = Color3.fromRGB(255, 255, 255)
                else
                    entry.bar.BackgroundTransparency = 1
                    entry.label.TextColor3 = Color3.fromRGB(75, 72, 72)
                end
            end

            if choice.value == "auto" then
                status.Text = "checking place"
            else
                status.Text = "loading " .. choice.name
            end

            pcall(function()
                tween(status, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
                    TextColor3 = Color3.fromRGB(154, 213, 222),
                })
            end)
        end)
    end

    -- After a build is picked, the picker becomes the progress loader:
    -- hide the picker rows and restore the loader tab + slider in place.
    local function finish_picker()
        state.closed = true

        for _, inst in ipairs(picker_objects) do
            pcall(function()
                inst.Visible = false
            end)
        end

        if slider_holder then
            slider_holder.Visible = true
        end

        if tab_loader then
            tab_loader.Visible = true
        end

        if tab_line then
            tab_line.Visible = true
        end

        if drag_overlay then
            drag_overlay.Active = true
            drag_overlay.Visible = true
        end
    end

    local ok_fade = pcall(function()
        loader:fade_in(0.28)
    end)

    if not ok_fade then
        pcall(function()
            loader:destroy()
        end)

        return nil
    end

    local deadline = os.time() + 30

    while not state.picked and os.time() < deadline do
        task.wait(0.05)
    end

    if state.picked then
        task.wait(0.12)
        return state.picked, loader, finish_picker
    end

    state.closed = true

    pcall(function()
        loader:fade_out(0.28)
    end)

    pcall(function()
        loader:destroy()
    end)

    return nil
end

-- > ( embedded uiloader )

__loader_ui = function()
-- > ( juju.beta ui loader )
-- Scale: 432 x 198, centered on screen, draggable anywhere on the window,
-- authentic juju.lua shell (background #000000 outer frame, #060606 left sidebar + right_side #000000
-- with juju section_border/section_inside + section_line header), 3D 360° rotating juju logo,
-- slider-styled loading bar with percentage and live asset path readout,
-- fade-in / fade-out transitions, and juju.lua file system asset loader.
-- Works in both Roblox executors (gethui/CoreGui + writefile/getcustomasset)
-- and Roblox Studio preview (PlayerGui / CoreGui fallback + demo asset pass).

local Uiloader = {}

local function safe_cloneref(service)
    if type(cloneref) == "function" then
        local ok, ref = pcall(cloneref, service)
        if ok and ref then
            return ref
        end
    end
    return service
end

local RunService = safe_cloneref(game:GetService("RunService"))
local UserInputService = safe_cloneref(game:GetService("UserInputService"))
local TweenService = safe_cloneref(game:GetService("TweenService"))
local Players = safe_cloneref(game:GetService("Players"))
local CoreGui = safe_cloneref(game:GetService("CoreGui"))
local GuiService = safe_cloneref(game:GetService("GuiService"))

local IS_STUDIO = RunService:IsStudio()

local COLORS = {
    shadow = Color3.fromRGB(154, 213, 222),
    accent = Color3.fromRGB(154, 213, 222),
    brand_white = Color3.fromRGB(255, 255, 255),
    active_text = Color3.fromRGB(197, 197, 197),
    border = Color3.fromRGB(24, 25, 24),
    highlighted = Color3.fromRGB(51, 65, 70),
    dark_text = Color3.fromRGB(70, 85, 87),
    inactive_text = Color3.fromRGB(75, 72, 72),
    section = Color3.fromRGB(6, 6, 6),
    background = Color3.fromRGB(0, 0, 0),
}

local LOADER_WIDTH = 432
local LOADER_HEIGHT = 198

-- Exact juju.lua Drawing2 Font = 1 ("A": Inter 18pt Bold from api.lua Drawing2FontCache/A.ttf)
-- Uses the exact same Drawing2FontCache/A.ttf + getcustomasset Font.new loader as juju.lua api.lua,
-- with Studio (JujuInterBold.json) and BuilderSans Bold fallback.
local HttpService = safe_cloneref(game:GetService("HttpService"))

local function resolve_juju_drawing_font()
    -- 1. If juju.lua Drawing2 (fake_drawing) is already loaded, reuse its exact Font.Enums[1]
    local env = (type(getgenv) == "function" and getgenv()) or _G
    local existing_drawing = env and env["fake_drawing"]
    if type(existing_drawing) == "table" and existing_drawing.Font and existing_drawing.Font.Enums and existing_drawing.Font.Enums[1] then
        local f = existing_drawing.Font.Enums[1]
        if typeof(f) == "Font" then
            return f
        end
    end

    -- 2. Executor path: mirror api.lua Drawing2.Font.new("A", ...) via Drawing2FontCache/A.ttf
    if type(isfolder) == "function" and type(makefolder) == "function" and type(isfile) == "function"
        and type(writefile) == "function" and type(readfile) == "function" and type(getcustomasset) == "function"
    then
        local ok_font, font_obj = pcall(function()
            if not isfolder("Drawing2FontCache") then
                makefolder("Drawing2FontCache")
            end

            local ttf_path = "Drawing2FontCache/A.ttf"
            if not isfile(ttf_path) then
                local api_src = nil
                if isfile("juju recode/assets/api.lua") then
                    local ok_r, body = pcall(readfile, "juju recode/assets/api.lua")
                    if ok_r and type(body) == "string" and #body > 0 then
                        api_src = body
                    end
                end
                if not api_src then
                    local ok_h, body = pcall(function()
                        return game:HttpGet("https://raw.githubusercontent.com/d1rtylegitness/juju/refs/heads/main/api.lua")
                    end)
                    if ok_h and type(body) == "string" and #body > 0 then
                        api_src = body
                    end
                end
                if api_src then
                    local font_b64 = string.match(api_src, 'Drawing2%.Font%.new%("A",%s*"([^"]+)"%)')
                    if font_b64 and #font_b64 > 0 then
                        local crypt_table = env and env["crypt"]
                        local dec = (crypt_table and crypt_table["base64"] and crypt_table["base64"]["decode"])
                            or (type(base64_decode) == "function" and base64_decode)
                        if type(dec) == "function" then
                            writefile(ttf_path, dec(font_b64))
                        end
                    end
                end
            end

            if isfile(ttf_path) then
                local family_path = "Drawing2FontCache/A_family.json"
                writefile(family_path, HttpService:JSONEncode({
                    ["name"] = "A",
                    ["faces"] = {
                        {
                            ["name"] = "Regular",
                            ["weight"] = 100,
                            ["style"] = "normal",
                            ["assetId"] = getcustomasset(ttf_path),
                        },
                    },
                }))
                return Font.new(getcustomasset(family_path), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
            end
            return nil
        end)
        if ok_font and typeof(font_obj) == "Font" then
            return font_obj
        end
    end

    -- 3. Roblox Studio preview path: exact Inter 18pt Bold family installed in Studio content/fonts
    if IS_STUDIO then
        local ok_studio, studio_font = pcall(function()
            return Font.new("rbxasset://fonts/families/JujuInterBold.json", Enum.FontWeight.Regular, Enum.FontStyle.Normal)
        end)
        if ok_studio and typeof(studio_font) == "Font" then
            return studio_font
        end
    end

    -- 4. Fallback geometric sans matching juju.lua
    local fallback = Font.fromEnum(Enum.Font.GothamBold)
    pcall(function()
        fallback = Font.new("rbxasset://fonts/families/BuilderSans.json", Enum.FontWeight.Bold, Enum.FontStyle.Normal)
    end)
    return fallback
end

local UI_FONT_FACE = resolve_juju_drawing_font()
local UI_FONT_BOLD = UI_FONT_FACE
-- The juju font draws a hairline slash in "%" so it reads as two dots at 12px.
-- Only the "%" glyph uses a bold font (digits keep the juju font).
local PERCENT_SIGN = '<font face="Gotham" weight="bold">%</font>'

-- Embedded fallback PNG data for the juju logo (front & horizontally-mirrored back for true 360° 3D spin)
local LOGO_BACK_BASE64 = "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"
local LOGO_BASE64 = "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"

-- Same file system manifest & paths as juju.lua ("juju recode/...")
local ROOT_FOLDER = "juju recode"

local ASSET_FOLDERS = {
    "juju recode",
    "juju recode/assets",
    "juju recode/custom",
    "juju recode/themes",
    "juju recode/addons",
    "juju recode/configs",
}

local ASSET_MANIFEST = {
    { path = "juju recode/assets/api.lua", url = "https://raw.githubusercontent.com/d1rtylegitness/juju/refs/heads/main/api.lua" },
    { path = "juju recode/assets/sparkle.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/sparkle.ogg" },
    { path = "juju recode/assets/skeet.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/skeet.ogg" },
    { path = "juju recode/assets/neverlose.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/neverlose.ogg" },
    { path = "juju recode/assets/break.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/break.ogg" },
    { path = "juju recode/assets/mc bow.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/mc%20bow.ogg" },
    { path = "juju recode/assets/primordial.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/primordial.ogg" },
    { path = "juju recode/assets/rust.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/rust.ogg" },
    { path = "juju recode/assets/sexy.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/sexy.ogg" },
    { path = "juju recode/assets/jaydes.png", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/jaydes.png" },
    { path = "juju recode/assets/1.png", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/1.png" },
    { path = "juju recode/assets/2.png", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/2.png" },
    { path = "juju recode/assets/logo.png", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/logo.png" },
    { path = "juju recode/assets/saturation.png", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/assets/saturation.png" },
    { path = "juju recode/custom/textures.json", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/textures.json" },
    { path = "juju recode/custom/character.rbxm", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/character.rbxm" },
    { path = "juju recode/custom/pinksky.rbxm", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/pinksky.rbxm" },
    { path = "juju recode/custom/crunch.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/crunch.ogg" },
    { path = "juju recode/custom/scar.ogg", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/scar.ogg" },
    { path = "juju recode/custom/x hit.rbxm", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/x%20hit.rbxm" },
    { path = "juju recode/custom/blossom aura.rbxm", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/blossom%20aura.rbxm" },
    { path = "juju recode/custom/spam.json", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/custom/spam.json" },
    { path = "juju recode/themes/default.th", url = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/themes/default.th" },
    { path = "juju recode/data.dat", content = [[{"notifications":true,"theme":"","favorites":[]}]] },
}

local function decode_base64(data)
    if type(base64_decode) == "function" then
        local ok, res = pcall(base64_decode, data)
        if ok and type(res) == "string" and #res > 0 then
            return res
        end
    end

    local env = (type(getgenv) == "function" and getgenv()) or _G
    local crypt_table = env and env["crypt"]
    local native = (crypt_table and (crypt_table["base64decode"] or (crypt_table["base64"] and crypt_table["base64"]["decode"])))
        or (env and env["base64"] and env["base64"]["decode"])
        or (env and env["base64decode"])

    if type(native) == "function" then
        local ok, res = pcall(native, data)
        if ok and type(res) == "string" and #res > 0 then
            return res
        end
    end

    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, 64 do
        lookup[string.byte(alphabet, i)] = i - 1
    end

    data = string.gsub(data, "[^%w%+/=]", "")
    local out = {}
    local buffer, bits = 0, 0
    for i = 1, #data do
        local ch = string.byte(data, i)
        if ch == 61 then
            break
        end
        buffer = buffer * 64 + lookup[ch]
        bits = bits + 6
        if bits >= 8 then
            bits = bits - 8
            local divisor = 2 ^ bits
            local value = math.floor(buffer / divisor)
            out[#out + 1] = string.char(value)
            buffer = buffer - value * divisor
        end
    end
    return table.concat(out)
end

local function has_executor_fs()
    return type(isfolder) == "function"
        and type(makefolder) == "function"
        and type(isfile) == "function"
        and type(writefile) == "function"
        and type(readfile) == "function"
end

local function ensure_logo_file(file_path, fallback_b64, studio_asset)
    if has_executor_fs() and type(getcustomasset) == "function" then
        pcall(function()
            if not isfolder(ROOT_FOLDER) then
                makefolder(ROOT_FOLDER)
            end
            if not isfolder(ROOT_FOLDER .. "/assets") then
                makefolder(ROOT_FOLDER .. "/assets")
            end
            local needs_seed = not isfile(file_path)
            if not needs_seed then
                local ok, body = pcall(readfile, file_path)
                needs_seed = (not ok) or type(body) ~= "string" or #body == 0
            end
            if needs_seed and type(fallback_b64) == "string" and not string.find(fallback_b64, "^__JUJU_") then
                writefile(file_path, decode_base64(fallback_b64))
            end
        end)

        local ok, asset = pcall(getcustomasset, file_path)
        if ok and type(asset) == "string" and #asset > 0 then
            return asset
        end
    end

    if IS_STUDIO then
        return studio_asset
    end

    return ""
end

local function ensure_logo_asset(custom_logo_id)
    if type(custom_logo_id) == "string" and #custom_logo_id > 0 then
        return custom_logo_id
    end
    return ensure_logo_file("juju recode/assets/logo.png", LOGO_BASE64, "rbxasset://textures/juju_logo.png")
end

local function ensure_logo_back_asset(custom_back_id)
    if type(custom_back_id) == "string" and #custom_back_id > 0 then
        return custom_back_id
    end
    return ensure_logo_file("juju recode/assets/logo_back.png", LOGO_BACK_BASE64, "rbxasset://textures/juju_logo_back.png")
end

local function resolve_gui_parent(explicit_parent)
    if explicit_parent then
        return explicit_parent
    end

    if type(gethui) == "function" then
        local ok, hui = pcall(gethui)
        if ok and hui then
            return safe_cloneref(hui)
        end
    end

    if IS_STUDIO then
        local local_player = Players.LocalPlayer
        if local_player then
            local pgui = local_player:FindFirstChildOfClass("PlayerGui") or local_player:WaitForChild("PlayerGui", 2)
            if pgui then
                return pgui
            end
        end
        local starter_gui = game:GetService("StarterGui")
        if starter_gui then
            return starter_gui
        end
    end

    local ok = pcall(function()
        return CoreGui.Name
    end)
    if ok then
        return CoreGui
    end

    local local_player = Players.LocalPlayer
    return local_player and local_player:FindFirstChildOfClass("PlayerGui") or CoreGui
end

local function create_inst(class_name, props, parent)
    local inst = Instance.new(class_name)
    for k, v in pairs(props) do
        inst[k] = v
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

function Uiloader.create(options)
    options = options or {}

    local parent = resolve_gui_parent(options.parent)
    local fade_duration = options.fade_duration or 0.28
    local spin_speed = options.spin_speed or 115 -- degrees per second (true 3D 360° Y-axis rotation)
    local logo_asset = ensure_logo_asset(options.logo_asset)
    local logo_back_asset = ensure_logo_back_asset(options.logo_back_asset)
    if logo_back_asset == "" then
        logo_back_asset = logo_asset
    end

    -- Remove any previous loader left in the same parent
    local existing = parent:FindFirstChild("juju_uiloader")
    if existing then
        pcall(function()
            existing:Destroy()
        end)
    end

    local gui = create_inst("ScreenGui", {
        Name = "juju_uiloader",
        DisplayOrder = 2147483640,
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, parent)

    -- Root container positioned dead-center on screen (432 x 198)
    local root = create_inst("Frame", {
        Name = "LoaderRoot",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0.5, 0),
        Size = UDim2.fromOffset(LOADER_WIDTH, LOADER_HEIGHT),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Active = true,
    }, gui)

    -- Subtle scale pop during fade-in / fade-out
    local root_scale = create_inst("UIScale", {
        Name = "FadeScale",
        Scale = 0.96,
    }, root)

    -- Outer frame matching juju.lua: pure black #000000 shell with 4px rounded corners
    -- (gives the exact dark outer margin + recessed rounded 1px inner border detail from juju UI)
    local frame_outer = create_inst("Frame", {
        Name = "OuterFrame",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = COLORS.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 2,
    }, root)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 4) }, frame_outer)

    -- Subtle outer 1px rounded corner line (#181918)
    local outer_stroke = create_inst("UIStroke", {
        Name = "OuterStroke",
        Color = COLORS.border,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, frame_outer)

    -- Inner surface matching juju.lua: inside (Position (1,1), Size (1,-2,1,-2), Color = section #060606, Rounding = 4)
    local frame_inside = create_inst("Frame", {
        Name = "Inside",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = COLORS.section,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 3,
    }, frame_outer)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 4) }, frame_inside)

    -- =========================================================================
    -- LEFT SIDEBAR (matches juju.lua sidebar: 100px wide, #060606 background,
    -- logo + stacked "juju" white / ".beta" accent + group header/line + active tab)
    -- =========================================================================
    local SIDEBAR_WIDTH = 100

    local sidebar_logo = create_inst("ImageLabel", {
        Name = "SidebarLogo",
        Position = UDim2.fromOffset(14, 14),
        Size = UDim2.fromOffset(26, 26),
        BackgroundTransparency = 1,
        Image = logo_asset,
        ImageColor3 = COLORS.accent,
        ImageTransparency = 1,
        ScaleType = Enum.ScaleType.Fit,
        ZIndex = 6,
    }, frame_inside)

    local juju_text = create_inst("TextLabel", {
        Name = "JujuText",
        Position = UDim2.fromOffset(45, 13),
        Size = UDim2.fromOffset(50, 14),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "juju",
        TextColor3 = COLORS.brand_white,
        TextSize = 14,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, frame_inside)

    local build_text = create_inst("TextLabel", {
        Name = "BuildText",
        Position = UDim2.fromOffset(45, 27),
        Size = UDim2.fromOffset(50, 13),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = ".beta",
        TextColor3 = COLORS.accent,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, frame_inside)

    -- Sidebar group header + accent underline (matches juju.lua create_group)
    local group_header_label = create_inst("TextLabel", {
        Name = "GroupHeader",
        Position = UDim2.fromOffset(15, 50),
        Size = UDim2.fromOffset(70, 13),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "system",
        TextColor3 = COLORS.accent,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, frame_inside)

    local group_header_line = create_inst("Frame", {
        Name = "GroupHeaderLine",
        Position = UDim2.fromOffset(15, 65),
        Size = UDim2.fromOffset(70, 1),
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, frame_inside)

    -- Active tab indicator matching juju.lua's tab_line (left 1px accent bar at x=0, h=12, transparency 0.5)
    local tab_line = create_inst("Frame", {
        Name = "TabLine",
        Position = UDim2.fromOffset(0, 74),
        Size = UDim2.fromOffset(1, 12),
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, frame_inside)

    local tab_loader_label = create_inst("TextLabel", {
        Name = "TabLoader",
        Position = UDim2.fromOffset(20, 73),
        Size = UDim2.fromOffset(74, 14),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "loader",
        TextColor3 = COLORS.active_text,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 6,
    }, frame_inside)



    -- Divider + Right Side matching juju.lua (right_side_divider at x=100, right_side at x=101, Color = #000000)
    local right_side_divider = create_inst("Frame", {
        Name = "RightSideDivider",
        Position = UDim2.fromOffset(SIDEBAR_WIDTH, 0),
        Size = UDim2.new(0, 1, 1, 0),
        BackgroundColor3 = COLORS.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, frame_inside)

    local right_side = create_inst("Frame", {
        Name = "RightSide",
        Position = UDim2.fromOffset(SIDEBAR_WIDTH + 1, 0),
        Size = UDim2.new(1, -(SIDEBAR_WIDTH + 1), 1, 0),
        BackgroundColor3 = COLORS.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 4,
    }, frame_inside)

    -- =========================================================================
    -- SECTION BOX inside RightSide (exact match to juju.lua create_section + corner detail:
    -- 10px black inset margin -> rounded 4px 1px border #181918 (UIStroke) wrapping #060606 inside
    -- -> top accent section_line + "juju.beta" + section_line_two + subtle corner ticks)
    -- =========================================================================
    local section_border = create_inst("Frame", {
        Name = "SectionBorder",
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(1, -20, 1, -20),
        BackgroundColor3 = COLORS.section,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 5,
    }, right_side)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 4) }, section_border)

    -- Crisp 1px rounded corner border line (#181918) matching the juju UI corner detail
    local section_stroke = create_inst("UIStroke", {
        Name = "SectionCornerLine",
        Color = COLORS.border,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, section_border)

    local section_inside = create_inst("Frame", {
        Name = "SectionInside",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundColor3 = COLORS.section,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 6,
    }, section_border)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 4) }, section_inside)

    -- Top accent hairline split around "juju.beta" header (exact match to juju.lua create_section)
    local section_line = create_inst("Frame", {
        Name = "SectionLineLeft",
        Position = UDim2.fromOffset(4, 0),
        Size = UDim2.fromOffset(9, 1),
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, section_inside)

    local section_label_bg = create_inst("Frame", {
        Name = "SectionLabelMask",
        Position = UDim2.fromOffset(15, -2),
        Size = UDim2.fromOffset(56, 4),
        BackgroundColor3 = COLORS.section,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, section_inside)

    local section_label = create_inst("TextLabel", {
        Name = "SectionLabel",
        Position = UDim2.fromOffset(17, -7),
        Size = UDim2.fromOffset(54, 14),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "juju.beta",
        TextColor3 = COLORS.accent,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 9,
    }, section_inside)

    local section_line_two = create_inst("Frame", {
        Name = "SectionLineRight",
        Position = UDim2.fromOffset(72, 0),
        Size = UDim2.new(1, -76, 0, 1),
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, section_inside)

    -- Subtle corner line accents along the bottom rounded corners of section_inside
    local corner_bl_h = create_inst("Frame", {
        Name = "CornerBL_H",
        Position = UDim2.new(0, 4, 1, -1),
        Size = UDim2.fromOffset(10, 1),
        BackgroundColor3 = COLORS.highlighted,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, section_inside)

    local corner_br_h = create_inst("Frame", {
        Name = "CornerBR_H",
        Position = UDim2.new(1, -14, 1, -1),
        Size = UDim2.fromOffset(10, 1),
        BackgroundColor3 = COLORS.highlighted,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, section_inside)

    -- =========================================================================
    -- TRUE 3D 360° ROTATING JUJU LOGO (ViewportFrame with real 3D double-sided slab +
    -- extruded thickness layers + full continuous 0° -> 360° 3D rotation around Y + subtle tilt)
    -- =========================================================================
    local logo_viewport = create_inst("ViewportFrame", {
        Name = "Logo3DViewport",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(0.5, 0, 0, 58),
        Size = UDim2.fromOffset(88, 88),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ImageTransparency = 1,
        LightColor = Color3.fromRGB(255, 255, 255),
        Ambient = Color3.fromRGB(220, 240, 245),
        LightDirection = Vector3.new(-0.35, -0.45, -1),
        ZIndex = 7,
    }, section_inside)

    local logo_world = create_inst("WorldModel", {
        Name = "LogoWorld",
    }, logo_viewport)

    local logo_camera = create_inst("Camera", {
        Name = "LogoCamera",
        FieldOfView = 34,
        CFrame = CFrame.new(Vector3.new(0, 0, 4.7), Vector3.new(0, 0, 0)),
    }, logo_viewport)
    logo_viewport.CurrentCamera = logo_camera

    -- Build a true 3D double-sided rotating emblem matching the 360° spin GIF:
    -- Front face (z = +depth/2, NormalId.Back facing +Z camera) displays logo.png normally;
    -- Back face (z = -depth/2, NormalId.Front facing -Z) displays horizontally-mirrored logo_back.png
    -- so rotating 0° -> 90° (edge) -> 180° (reversed back) -> 270° (edge) -> 360° (front) is a true 360° spin.
    local logo_model = create_inst("Model", {
        Name = "JujuLogo3D",
    }, logo_world)

    local logo_slices = {}
    local SLICE_COUNT = 9
    local SLICE_DEPTH = 0.18

    for i = 1, SLICE_COUNT do
        local t = (i - 1) / (SLICE_COUNT - 1) -- 0..1
        local z_off = (0.5 - t) * SLICE_DEPTH -- i=1 at +z (camera-facing front), i=SLICE_COUNT at -z (back)
        local is_front = (i == 1)
        local is_back = (i == SLICE_COUNT)
        local is_outer = (is_front or is_back)

        local slice = create_inst("Part", {
            Name = "LogoSlice_" .. tostring(i),
            Anchored = true,
            CanCollide = false,
            CastShadow = false,
            Size = Vector3.new(2.25, 2.25, 0.018),
            Transparency = 1,
            CFrame = CFrame.new(0, 0, z_off),
        }, logo_model)

        -- Outer faces = crisp accent (#9AD5DE), inner extruded slices = shaded teal rim
        local slice_color = is_outer and COLORS.accent or Color3.fromRGB(78, 132, 142)

        if logo_asset ~= "" then
            -- NormalId.Back faces +Z (toward the camera at yaw=0°): shows forward logo.png
            create_inst("Decal", {
                Name = "CameraFrontFace",
                Face = Enum.NormalId.Back,
                Texture = logo_asset,
                Color3 = slice_color,
                -- inner slices nearly clear so logo.png's soft halo can't stack into a glow
                Transparency = is_back and 1 or (is_outer and 0 or 0.85),
            }, slice)
            -- NormalId.Front faces -Z (toward the camera at yaw=180°): shows mirrored logo_back.png
            create_inst("Decal", {
                Name = "CameraBackFace",
                Face = Enum.NormalId.Front,
                Texture = logo_back_asset,
                Color3 = slice_color,
                Transparency = is_front and 1 or (is_outer and 0 or 0.85),
            }, slice)
        else
            slice.Transparency = is_outer and 0.1 or 0.35
            slice.Color = slice_color
            slice.Size = Vector3.new(1.5, 1.5, 0.04)
            slice.Material = Enum.Material.SmoothPlastic
        end

        logo_slices[i] = { part = slice, z_off = z_off }
    end

    -- =========================================================================
    -- SLIDER-STYLED LOADING BAR directly beneath the 3D rotating juju logo
    -- Exact match to juju.lua slider: 12px border (#181918), 1px inset well (#000000),
    -- 1px inset fill (#9AD5DE at 0.5 transparency) with 4px rounding + divider + % readout
    -- =========================================================================
    local BAR_PAD_X = 16

    local slider_holder = create_inst("Frame", {
        Name = "LoadingSliderHolder",
        Position = UDim2.fromOffset(BAR_PAD_X, 112),
        Size = UDim2.new(1, -(BAR_PAD_X * 2), 0, 44),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 7,
    }, section_inside)

    local title_label = create_inst("TextLabel", {
        Name = "LoadingTitle",
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromOffset(48, 12),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "loading",
        TextColor3 = COLORS.active_text,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 8,
    }, slider_holder)

    local slider_line = create_inst("Frame", {
        Name = "SliderLine",
        Position = UDim2.fromOffset(48, 2),
        Size = UDim2.fromOffset(1, 8),
        BackgroundColor3 = COLORS.dark_text,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, slider_holder)

    local percent_label = create_inst("TextLabel", {
        Name = "PercentLabel",
        Position = UDim2.fromOffset(53, 0),
        Size = UDim2.fromOffset(42, 12),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        RichText = true,
        Text = "0" .. PERCENT_SIGN,
        TextColor3 = COLORS.accent,
        TextSize = 12,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 8,
    }, slider_holder)

    local asset_label = create_inst("TextLabel", {
        Name = "AssetPathLabel",
        Position = UDim2.fromOffset(92, 0),
        Size = UDim2.new(1, -92, 0, 12),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "initializing...",
        TextColor3 = COLORS.dark_text,
        TextSize = 11,
        TextTransparency = 1,
        TextTruncate = Enum.TextTruncate.AtEnd,
        TextXAlignment = Enum.TextXAlignment.Right,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 8,
    }, slider_holder)


    -- Slider border (matches juju.lua slider_border: height 12, 1px #181918 corner line, rounding 4)
    local slider_border = create_inst("Frame", {
        Name = "SliderBorder",
        Position = UDim2.fromOffset(0, 15),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundColor3 = COLORS.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 8,
    }, slider_holder)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 4) }, slider_border)

    local slider_stroke = create_inst("UIStroke", {
        Name = "SliderBorderLine",
        Color = COLORS.border,
        Thickness = 1,
        Transparency = 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
    }, slider_border)

    -- Slider well (matches juju.lua slider_inside: 1px inset, color background #000000, rounding 3)
    local slider_inside = create_inst("Frame", {
        Name = "SliderInside",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(1, -2, 1, -2),
        BackgroundColor3 = COLORS.background,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 9,
    }, slider_border)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 3) }, slider_inside)

    -- Slider fill (matches juju.lua slider_fill: 1px inset, color accent #9AD5DE, transparency 0.5, rounding 3)
    local slider_fill = create_inst("Frame", {
        Name = "SliderFill",
        Position = UDim2.fromOffset(1, 1),
        Size = UDim2.new(0, 0, 1, -2),
        BackgroundColor3 = COLORS.accent,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ZIndex = 10,
    }, slider_inside)
    create_inst("UICorner", { CornerRadius = UDim.new(0, 3) }, slider_fill)

    -- Bottom status readout showing file count
    local count_label = create_inst("TextLabel", {
        Name = "CountLabel",
        Position = UDim2.fromOffset(0, 31),
        Size = UDim2.new(1, 0, 0, 12),
        BackgroundTransparency = 1,
        FontFace = UI_FONT_FACE,
        Text = "0 / " .. tostring(#ASSET_MANIFEST) .. " files",
        TextColor3 = COLORS.inactive_text,
        TextSize = 11,
        TextTransparency = 1,
        TextXAlignment = Enum.TextXAlignment.Center,
        TextYAlignment = Enum.TextYAlignment.Center,
        ZIndex = 8,
    }, slider_holder)

    -- Full-window transparent drag overlay at top ZIndex so clicking anywhere on the loader drags cleanly
    local drag_overlay = create_inst("TextButton", {
        Name = "DragOverlay",
        Position = UDim2.fromScale(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Selectable = false,
        Active = true,
        ZIndex = 50,
    }, root)

    -- Track target transparencies so fade-in and fade-out preserve juju's exact opacity hierarchy
    local fade_targets = {
        { inst = frame_outer, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = outer_stroke, prop = "Transparency", shown = 0, hidden = 1 },
        { inst = frame_inside, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = sidebar_logo, prop = "ImageTransparency", shown = 0, hidden = 1 },
        { inst = juju_text, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = build_text, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = group_header_label, prop = "TextTransparency", shown = 0.5, hidden = 1 },
        { inst = group_header_line, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = tab_line, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = tab_loader_label, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = right_side_divider, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = right_side, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = section_border, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = section_stroke, prop = "Transparency", shown = 0, hidden = 1 },
        { inst = section_inside, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = section_line, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = section_label_bg, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = section_label, prop = "TextTransparency", shown = 0.25, hidden = 1 },
        { inst = section_line_two, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = corner_bl_h, prop = "BackgroundTransparency", shown = 0.4, hidden = 1 },
        { inst = corner_br_h, prop = "BackgroundTransparency", shown = 0.4, hidden = 1 },
        { inst = logo_viewport, prop = "ImageTransparency", shown = 0, hidden = 1 },
        { inst = title_label, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = slider_line, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = percent_label, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = asset_label, prop = "TextTransparency", shown = 0, hidden = 1 },
        { inst = slider_border, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = slider_stroke, prop = "Transparency", shown = 0, hidden = 1 },
        { inst = slider_inside, prop = "BackgroundTransparency", shown = 0, hidden = 1 },
        { inst = slider_fill, prop = "BackgroundTransparency", shown = 0.5, hidden = 1 },
        { inst = count_label, prop = "TextTransparency", shown = 0, hidden = 1 },
    }

    local connections = {}
    local destroyed = false
    local has_been_dragged = false
    local dragging = false
    local drag_input = nil
    local drag_start_mouse = Vector2.new(0, 0)
    local drag_start_pos = Vector2.new(0, 0)
    local slider_hovered = false

    local target_progress = 0
    local displayed_progress = 0
    local spin_angle = 0

    local function recenter_if_needed()
        if destroyed or has_been_dragged then
            return
        end
        root.AnchorPoint = Vector2.new(0.5, 0.5)
        root.Position = UDim2.new(0.5, 0, 0.5, 0)
    end

    local function point_in_rect(pt, inst)
        local inset = GuiService:GetGuiInset()
        local p = inst.AbsolutePosition + inset
        local s = inst.AbsoluteSize
        return pt.X >= p.X and pt.X <= (p.X + s.X) and pt.Y >= p.Y and pt.Y <= (p.Y + s.Y)
    end

    local function begin_drag(mouse_pos, input_obj)
        if destroyed or dragging then
            return
        end
        dragging = true
        drag_input = input_obj
        has_been_dragged = true
        local inset = GuiService:GetGuiInset()
        local abs_pos = root.AbsolutePosition + inset
        root.AnchorPoint = Vector2.new(0, 0)
        root.Position = UDim2.fromOffset(abs_pos.X, abs_pos.Y)
        drag_start_pos = Vector2.new(abs_pos.X, abs_pos.Y)
        drag_start_mouse = mouse_pos
        TweenService:Create(outer_stroke, TweenInfo.new(0.12, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
            Color = COLORS.highlighted,
        }):Play()
    end

    local function end_drag()
        if not dragging then
            return
        end
        dragging = false
        drag_input = nil
        if not destroyed then
            TweenService:Create(outer_stroke, TweenInfo.new(0.14, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
                Color = COLORS.border,
            }):Play()
        end
    end

    local function update_drag_to(mouse_pos)
        if not dragging or destroyed then
            return
        end
        local delta = mouse_pos - drag_start_mouse
        local next_x = drag_start_pos.X + delta.X
        local next_y = drag_start_pos.Y + delta.Y

        local cam = workspace.CurrentCamera
        if cam then
            local vp = cam.ViewportSize
            next_x = math.clamp(next_x, 0, math.max(0, vp.X - LOADER_WIDTH))
            next_y = math.clamp(next_y, 0, math.max(0, vp.Y - LOADER_HEIGHT))
        end

        root.Position = UDim2.fromOffset(math.floor(next_x + 0.5), math.floor(next_y + 0.5))
    end

    -- Reliable dragging via both overlay InputBegan AND global UserInputService fallback
    -- (handles executors + Roblox Studio + touch + mouse movement even when cursor leaves the frame)
    table.insert(connections, drag_overlay.InputBegan:Connect(function(input)
        if destroyed then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            begin_drag(UserInputService:GetMouseLocation(), input)
        end
    end))

    table.insert(connections, UserInputService.InputBegan:Connect(function(input)
        if destroyed or dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mouse_pos = UserInputService:GetMouseLocation()
            if point_in_rect(mouse_pos, root) then
                begin_drag(mouse_pos, input)
            end
        end
    end))

    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if not dragging then return end
        if input == drag_input
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch
        then
            end_drag()
        end
    end))

    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if destroyed then return end
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update_drag_to(UserInputService:GetMouseLocation())
        end
    end))

    -- Keep centered on viewport resize if the user hasn't dragged it away
    local cam = workspace.CurrentCamera
    if cam then
        table.insert(connections, cam:GetPropertyChangedSignal("ViewportSize"):Connect(recenter_if_needed))
    end

    -- Per-frame 3D 360° logo spin + continuous drag tracking + slider hover + smooth bar lerp
    table.insert(connections, RunService.RenderStepped:Connect(function(dt)
        if destroyed then return end

        -- Keep drag synced every frame while mouse button 1 is held (smooth even during fast drags)
        if dragging then
            if drag_input and drag_input.UserInputType == Enum.UserInputType.MouseButton1
                and not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)
            then
                end_drag()
            else
                update_drag_to(UserInputService:GetMouseLocation())
            end
        end

        -- Hover border highlight on slider (matches juju.lua slider_border hover without blocking drag)
        local mouse_now = UserInputService:GetMouseLocation()
        local is_over_slider = point_in_rect(mouse_now, slider_border)
        if is_over_slider ~= slider_hovered then
            slider_hovered = is_over_slider
            TweenService:Create(slider_stroke, TweenInfo.new(0.17, Enum.EasingStyle.Circular, Enum.EasingDirection.Out), {
                Color = slider_hovered and COLORS.highlighted or COLORS.border,
            }):Play()
        end

        -- Continuous true 3D 360° Y-axis revolution (front -> edge -> reversed back -> edge -> front)
        spin_angle = (spin_angle + spin_speed * dt) % 360
        local yaw_rad = math.rad(spin_angle)
        local base_cf = CFrame.Angles(0, yaw_rad, 0)
        for i = 1, #logo_slices do
            local entry = logo_slices[i]
            entry.part.CFrame = base_cf * CFrame.new(0, 0, entry.z_off)
        end

        -- Smooth loading bar interpolation
        local lerp_alpha = math.clamp(dt * 12, 0, 1)
        displayed_progress = displayed_progress + (target_progress - displayed_progress) * lerp_alpha
        if math.abs(target_progress - displayed_progress) < 0.001 then
            displayed_progress = target_progress
        end

        local max_fill_w = math.max(0, slider_inside.AbsoluteSize.X - 2)
        local fill_w = math.floor(max_fill_w * math.clamp(displayed_progress, 0, 1) + 0.5)
        slider_fill.Size = UDim2.new(0, fill_w, 1, -2)
        percent_label.Text = tostring(math.floor(math.clamp(displayed_progress, 0, 1) * 100 + 0.5)) .. PERCENT_SIGN
    end))

    local controller = {
        gui = gui,
        root = root,
        manifest = ASSET_MANIFEST,
        font = UI_FONT_FACE,
    }

    function controller:set_spin_angle(deg)
        if destroyed then return end
        spin_angle = (tonumber(deg) or 0) % 360
        local base_cf = CFrame.Angles(0, math.rad(spin_angle), 0)
        for i = 1, #logo_slices do
            local entry = logo_slices[i]
            entry.part.CFrame = base_cf * CFrame.new(0, 0, entry.z_off)
        end
    end

    function controller:set_logo_asset(asset_id, back_asset_id)
        if destroyed or type(asset_id) ~= "string" or #asset_id == 0 then
            return
        end
        local resolved_back = (type(back_asset_id) == "string" and #back_asset_id > 0) and back_asset_id or asset_id
        sidebar_logo.Image = asset_id
        for i = 1, #logo_slices do
            local part = logo_slices[i].part
            local is_front = (i == 1)
            local is_back = (i == #logo_slices)
            local cam_front = part:FindFirstChild("CameraFrontFace")
            local cam_back = part:FindFirstChild("CameraBackFace")
            if cam_front and cam_back then
                cam_front.Texture = asset_id
                cam_back.Texture = resolved_back
            else
                part.Transparency = 1
                part.Size = Vector3.new(2.25, 2.25, 0.018)
                local slice_color = (is_front or is_back) and COLORS.accent or Color3.fromRGB(78, 132, 142)
                create_inst("Decal", {
                    Name = "CameraFrontFace",
                    Face = Enum.NormalId.Back,
                    Texture = asset_id,
                    Color3 = slice_color,
                    Transparency = is_back and 1 or 0,
                }, part)
                create_inst("Decal", {
                    Name = "CameraBackFace",
                    Face = Enum.NormalId.Front,
                    Texture = resolved_back,
                    Color3 = slice_color,
                    Transparency = is_front and 1 or 0,
                }, part)
            end
        end
    end

    function controller:set_progress(fraction, status_text, current_index, total_count)
        if destroyed then return end
        target_progress = math.clamp(tonumber(fraction) or 0, 0, 1)
        if status_text ~= nil then
            asset_label.Text = tostring(status_text)
        end
        if current_index ~= nil and total_count ~= nil then
            count_label.Text = tostring(current_index) .. " / " .. tostring(total_count) .. " files"
        end
    end

    function controller:add_fade_target(inst, prop, shown, hidden)
        if destroyed or not inst or not prop then
            return
        end

        local target = {
            inst = inst,
            prop = prop,
            shown = shown or 0,
            hidden = hidden or 1,
        }

        fade_targets[#fade_targets + 1] = target
        inst[prop] = target.hidden
    end

    local active_fade_tweens = {}

    local function cancel_fade_tweens()
        for _, tw in ipairs(active_fade_tweens) do
            pcall(function()
                tw:Cancel()
            end)
        end
        table.clear(active_fade_tweens)
    end

    function controller:fade_in(duration)
        if destroyed then return end
        cancel_fade_tweens()
        local d = duration or fade_duration
        -- Guarantee clean start from invisible + slight scale-in
        root.Visible = true
        root_scale.Scale = 0.96
        for _, item in ipairs(fade_targets) do
            item.inst[item.prop] = item.hidden
        end
        local info = TweenInfo.new(d, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
        local scale_tw = TweenService:Create(root_scale, info, { Scale = 1 })
        table.insert(active_fade_tweens, scale_tw)
        scale_tw:Play()
        for _, item in ipairs(fade_targets) do
            local tw = TweenService:Create(item.inst, info, { [item.prop] = item.shown })
            table.insert(active_fade_tweens, tw)
            tw:Play()
        end
        task.wait(d)
    end

    function controller:fade_out(duration)
        if destroyed then return end
        cancel_fade_tweens()
        local d = duration or fade_duration
        local info = TweenInfo.new(d, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out)
        local scale_tw = TweenService:Create(root_scale, info, { Scale = 0.96 })
        table.insert(active_fade_tweens, scale_tw)
        scale_tw:Play()
        for _, item in ipairs(fade_targets) do
            local tw = TweenService:Create(item.inst, info, { [item.prop] = item.hidden })
            table.insert(active_fade_tweens, tw)
            tw:Play()
        end
        task.wait(d)
        if not destroyed then
            root.Visible = false
        end
    end

    function controller:get_spin_angle()
        return spin_angle
    end

    function controller:destroy()
        if destroyed then return end
        destroyed = true
        for _, conn in ipairs(connections) do
            pcall(function()
                conn:Disconnect()
            end)
        end
        table.clear(connections)
        if gui then
            pcall(function()
                gui:Destroy()
            end)
        end
    end

    -- Load every asset from juju.lua's file system manifest and update bar + %
    function controller:load_assets(step_delay)
        local fs_ready = has_executor_fs()
        local total = #ASSET_MANIFEST

        if fs_ready then
            for _, folder in ipairs(ASSET_FOLDERS) do
                pcall(function()
                    if not isfolder(folder) then
                        makefolder(folder)
                    end
                end)
            end
        end

        local function needs_write(path)
            if not isfile(path) then
                return true
            end
            local ok, body = pcall(readfile, path)
            return ok and type(body) == "string" and #body == 0
        end

        for index, entry in ipairs(ASSET_MANIFEST) do
            if destroyed then
                break
            end

            local display_path = string.gsub(entry.path, "^" .. ROOT_FOLDER .. "/", "")
            self:set_progress((index - 1) / total, display_path, index - 1, total)

            if fs_ready then
                if needs_write(entry.path) then
                    local ok, err = pcall(function()
                        local content = entry.content
                        if not content and entry.url then
                            content = game:HttpGet(entry.url)
                        end
                        if type(content) == "string" and #content > 0 then
                            writefile(entry.path, content)
                        end
                    end)
                    if not ok then
                        warn("[juju.beta loader] asset skipped: " .. entry.path .. " (" .. tostring(err) .. ")")
                    end
                end

                -- If logo.png was just written, hot-bind it to both sidebar + 3D rotating logo
                if entry.path == "juju recode/assets/logo.png" and logo_asset == "" and type(getcustomasset) == "function" then
                    local ok, asset = pcall(getcustomasset, entry.path)
                    if ok and type(asset) == "string" and #asset > 0 then
                        logo_asset = asset
                        logo_back_asset = ensure_logo_back_asset()
                        self:set_logo_asset(asset, logo_back_asset)
                    end
                end
            end

            self:set_progress(index / total, display_path, index, total)

            local wait_time = step_delay
            if wait_time == nil then
                wait_time = fs_ready and 0.02 or 0.06
            end
            if wait_time > 0 then
                task.wait(wait_time)
            end
        end

        if not destroyed then
            self:set_progress(1, "ready", total, total)
            task.wait(0.28)
        end
    end

    return controller
end

-- High-level entry point: fades in loader, loads all juju assets, fades out loader,
-- and optionally runs a callback (or loads juju.lua) once assets are ready.
function Uiloader.run(options)
    options = options or {}
    local loader = Uiloader.create(options)

    loader:fade_in(options.fade_in or 0.28)
    loader:load_assets(options.step_delay)

    if type(options.on_ready) == "function" then
        pcall(options.on_ready, loader)
    end

    if not options.keep_open then
        loader:fade_out(options.fade_out or 0.28)
        loader:destroy()
    end

    return loader
end

-- Expose globally so juju.lua or an external bootstrapper can reuse Uiloader directly
do
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if env then
        env["juju_uiloader"] = Uiloader
    end
end

return Uiloader
end

-- > ( place routing )

local function pick_target()
    local env = getgenv()
    local chosen = env and env["juju_loader_target"]

    if chosen == "juju" or chosen == "jujuHC" then
        return chosen
    end

    if game["PlaceId"] == DA_HOOD_PLACE_ID then
        return "juju"
    end

    return "jujuHC"
end

local function fetch_source(target)
    local env = getgenv()
    local direct = env and env["juju_loader_source"]

    if type(direct) == "string" and #direct > 0 then
        return direct, "getgenv source"
    end

    local override = env and env["juju_loader_url"]

    if type(override) == "string" and #override > 0 then
        local ok, body = pcall(function()
            return game:HttpGet(override)
        end)

        if ok and type(body) == "string" and #body > 0 then
            return body, override
        end
    end

    for _, url in target.urls do
        local ok, body = pcall(function()
            return game:HttpGet(url)
        end)

        if ok and type(body) == "string" and #body > 0 then
            return body, url
        end
    end

    if type(readfile) == "function" then
        for _, path in target.files do
            local ok, body = pcall(readfile, path)

            if ok and type(body) == "string" and #body > 0 then
                return body, path
            end
        end
    end

    return nil, nil
end

-- > ( loader ui )

local picked_target, picker_loader, finish_picker = pick_target_ui()

if picked_target == "juju" or picked_target == "jujuHC" then
    local env = (type(getgenv) == "function" and getgenv()) or _G
    if env then
        env["juju_loader_target"] = picked_target
    end
end

local target_name = pick_target()
local target = TARGETS[target_name]

local loader = nil

if picker_loader and type(finish_picker) == "function" then
    -- Seamless handoff: the picker shell becomes the progress loader.
    loader = picker_loader
    pcall(finish_picker)
else
    do
        local ok, mod = pcall(__loader_ui)

        if ok and type(mod) == "table" and type(mod.create) == "function" then
            local ok_ui, ui = pcall(mod.create, {
                fade_duration = 0.28,
            })

            if ok_ui and ui then
                loader = ui
                pcall(function()
                    loader:fade_in(0.28)
                end)
            end
        end
    end
end

local function set_status(fraction, text, index, total)
    if loader then
        pcall(function()
            loader:set_progress(fraction, text, index, total)
        end)
    end
end

local function close_loader(wait_time)
    if not loader then
        return
    end

    pcall(function()
        if wait_time then
            task["wait"](wait_time)
        end

        loader:fade_out(0.28)
        loader:destroy()
    end)
end

-- > ( run )

set_status(0.25, "loading " .. target.name, 1, 3)

local source, source_name = fetch_source(target)

if not source then
    set_status(1, "failed to download " .. target.name, 3, 3)
    warn("[juju loader] could not download " .. target.name .. " for place " .. tostring(game["PlaceId"]))
    close_loader(1)
    return
end

set_status(0.75, "compiling " .. target.name, 2, 3)

if type(loadstring) ~= "function" then
    set_status(1, "loadstring unavailable", 3, 3)
    warn("[juju loader] loadstring is not available in this executor")
    close_loader(1)
    return
end

local chunk, compile_error = loadstring(source)

if not chunk then
    set_status(1, "compile failed", 3, 3)
    warn("[juju loader] " .. target.name .. " failed to compile: " .. tostring(compile_error))
    close_loader(1)
    return
end

set_status(1, "loading " .. target.name .. " assets", 3, 3)

local ok, err = pcall(chunk)

if not ok then
    warn("[juju loader] " .. target.name .. " failed: " .. tostring(err))
end

close_loader()
