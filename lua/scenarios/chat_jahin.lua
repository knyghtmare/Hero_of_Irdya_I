--textdomain wesnoth-Hero_of_Irdya

function chat_jahin(t)
    -- behave like a [chat] tag
    -- speaker is Jahin, by default
    wesnoth.fire("chat", { speaker = "Jahin", message = t.txt_msg })
end

function narrator_message_mysterious(txt)
    -- behave like a message tag
    -- with speaker fixed
    wesnoth.fire("message", { speaker = narrator, image= misc/blank-hex.png, caption = "Mysterious Booming Voice" , message = txt.txt_msg })
end