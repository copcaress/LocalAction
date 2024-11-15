local imgui = require 'imgui'
local key = require 'vkeys'
local encoding = require 'encoding'
encoding.default = 'CP1251'
u8 = encoding.UTF8

local main_window_state = imgui.ImBool(false)
local text_input = imgui.ImBuffer(256)
local edit_id = nil

local actionTextColor = 0xFFC2A2DA
local buttonColor = imgui.ImVec4(0x52 / 255, 0x50 / 255, 0x92 / 255, 1)
local buttonHoveredColor = imgui.ImVec4(0x64 / 255, 0x62 / 255, 0xA2 / 255, 1)
local buttonActiveColor = imgui.ImVec4(0x42 / 255, 0x40 / 255, 0x82 / 255, 1)
local deleteButtonColor = imgui.ImVec4(0.9, 0.3, 0.3, 1)
local text3DData = {}
local myX, myY, myZ = 0

function main()
    while not isSampAvailable() do wait(200) end
    sampRegisterChatCommand('act', handleActCommand)

    sampAddChatMessage("{C2A2DA}[LocalAction] {FFFFFF}Загружен. Активация: {C2A2DA}/act{C2A2DA}.{FFFFFF} Автор: {C2A2DA}сopcar.{FFFFFF}", -1)

    while true do
        wait(0)
        myX, myY, myZ = getCharCoordinates(PLAYER_PED)

        imgui.Process = main_window_state.v  -- окно будет активироваться только по команде
    end
end

function imgui.OnDrawFrame()
    if main_window_state.v then
        local screenWidth, screenHeight = getScreenResolution()
        imgui.SetNextWindowPos(imgui.ImVec2(screenWidth / 2 - 150, screenHeight / 2 - 75), imgui.Cond.FirstUseEver)
        imgui.SetNextWindowSize(imgui.ImVec2(338, 140), imgui.Cond.FirstUseEver)
        
        imgui.Begin(u8'LocalAction', main_window_state)

        imgui.Text(u8'Введите текст. Используйте @ для переноса строки:')
        
        -- Поле ввода с переносом текста
        local inputWidth = 300
        imgui.PushItemWidth(inputWidth)
        imgui.PushStyleVar(imgui.StyleVar.FrameRounding, 4)
        
        -- Настройка текстового поля с переносом
        imgui.InputTextMultiline('##input', text_input, imgui.ImVec2(inputWidth, 60), imgui.InputTextFlags.AllowTabInput)

        imgui.PopStyleVar()
        imgui.PopItemWidth()

        -- Кнопка сохранения
        imgui.PushStyleColor(imgui.Col.Button, buttonColor)
        imgui.PushStyleColor(imgui.Col.ButtonHovered, buttonHoveredColor)
        imgui.PushStyleColor(imgui.Col.ButtonActive, buttonActiveColor)

        if imgui.Button(u8"Сохранить") then
            createOrEdit3DText(text_input.v)
            main_window_state.v = false
        end

        imgui.SameLine()
        if imgui.Button(u8"Отмена") then
            main_window_state.v = false
            edit_id = nil
        end

        imgui.PopStyleColor(3)

        -- Выравниваем кнопку удаления по правой стороне
        if edit_id then
            imgui.SameLine(inputWidth - 48) -- отступ к правому краю
            imgui.PushStyleColor(imgui.Col.Button, deleteButtonColor)

            if imgui.Button(u8"Удалить") then
                delete3DText(edit_id)
                main_window_state.v = false
                edit_id = nil
            end

            imgui.PopStyleColor()
        end

        imgui.End()
    end
end

function handleActCommand(args)
    local id = tonumber(args)
    if id and text3DData[id] then
        edit_id = id
        text_input.v = text3DData[id].text:gsub("\n", "@")
        main_window_state.v = true
    else
        edit_id = nil
        main_window_state.v = true
    end
end

function createOrEdit3DText(input)
    local displayText = input:gsub("@", "\n")
    local decodedText = u8:decode(displayText)

    if edit_id and text3DData[edit_id] then
        sampDestroy3dText(text3DData[edit_id].id)
        text3DData[edit_id].id = sampCreate3dText(decodedText, actionTextColor, myX, myY, myZ, 40, false, -1, -1)
        text3DData[edit_id].text = displayText
        sampAddChatMessage(("{C2A2DA}[LocalAction] {FFFFFF}Текст с {C2A2DA} id%d{FFFFFF} обновлён."):format(edit_id), -1)
    else
        local newId = #text3DData + 1
        text3DData[newId] = { id = sampCreate3dText(decodedText, actionTextColor, myX, myY, myZ, 40, false, -1, -1), text = displayText }
        sampAddChatMessage(("{C2A2DA}[LocalAction] {FFFFFF}Текст с {C2A2DA}id%d {FFFFFF}создан."):format(newId), -1)
    end

    edit_id = nil
end

function delete3DText(id)
    if text3DData[id] then
        sampDestroy3dText(text3DData[id].id)
        text3DData[id] = nil
        sampAddChatMessage(("{C2A2DA}[LocalAction] {FFFFFF}Текст с {C2A2DA}id%d{FFFFFF} удалён."):format(id), -1)
    end
end
