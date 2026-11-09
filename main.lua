-- juju entry point
-- Executes the current build straight from the repo, cache-busted so a fresh
-- push is picked up without waiting on the raw CDN.

local BASE = "https://raw.githubusercontent.com/shfjcjvnifs-maker/juju/main/juju.lua"
local url = BASE .. "?t=" .. tostring(os.time())

local fetched, source = pcall(function()
    return game:HttpGet(url)
end)

if not fetched or type(source) ~= "string" or #source < 10000 then
    warn("[juju] download failed: " .. tostring(source))

    pcall(function()
        local container = (gethui and gethui()) or game:GetService("CoreGui")
        local gui = Instance.new("ScreenGui")
        gui.Name = "juju_download_error"
        gui.DisplayOrder = 2147483647
        gui.IgnoreGuiInset = true
        gui.ResetOnSpawn = false
        gui.Parent = container

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundColor3 = Color3.fromRGB(16, 0, 0)
        label.BackgroundTransparency = 0.1
        label.BorderSizePixel = 0
        label.TextColor3 = Color3.fromRGB(255, 130, 130)
        label.Font = Enum.Font.Code
        label.TextSize = 14
        label.TextWrapped = true
        label.TextXAlignment = Enum.TextXAlignment.Left
        label.TextYAlignment = Enum.TextYAlignment.Top
        label.Text = "juju download failed\n\n" .. url .. "\n\n" .. tostring(source)
        label.Parent = gui
    end)

    error("[juju] download failed: " .. tostring(source), 0)
end

local chunk, compile_error = loadstring(source)

if not chunk then
    warn("[juju] compile failed: " .. tostring(compile_error))
    error("[juju] compile failed: " .. tostring(compile_error), 0)
end

local ok, runtime_error = pcall(chunk)

if not ok then
    error("[juju] runtime error: " .. tostring(runtime_error), 0)
end